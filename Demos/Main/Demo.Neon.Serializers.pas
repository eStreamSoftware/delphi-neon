{******************************************************************************}
{                                                                              }
{  Neon: Serialization Library for Delphi                                      }
{  Copyright (c) 2018-2019 Paolo Rossi                                         }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}
unit Demo.Neon.Serializers;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.SyncObjs, System.TypInfo,
  System.Generics.Collections, System.Math.Vectors, System.JSON, Vcl.Graphics,

  Demo.Neon.Entities,
  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence;

type
  TPoint3DSerializer = class(TCustomSerializer)
  public
    class function GetTargetInfo: PTypeInfo; override;
  public
    function Serialize(const AValue: TValue; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; AContext: IDeserializerContext): TValue; override;
  end;

  TParameterSerializer = class(TCustomSerializer)
  public
    class function GetTargetInfo: PTypeInfo; override;
  public
    function Serialize(const AValue: TValue; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; AContext: IDeserializerContext): TValue; override;
  end;

  TFontSerializer = class(TCustomSerializer)
  public
    class function GetTargetInfo: PTypeInfo; override;
  public
    function Serialize(const AValue: TValue; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; AContext: IDeserializerContext): TValue; override;
  end;

  TCaseClassSerializer = class(TCustomSerializer)
  public
    class function GetTargetInfo: PTypeInfo; override;
  public
    function Serialize(const AValue: TValue; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; AContext: IDeserializerContext): TValue; override;
  end;

implementation

uses
  Neon.Core.Utils;

{ TPoint3DSerializer }

class function TPoint3DSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TypeInfo(TPoint3D);
end;

function TPoint3DSerializer.Serialize(const AValue: TValue; AContext: ISerializerContext): TJSONValue;
var
  LVal: TPoint3D;
  LJSON: TJSONObject;
begin
  LVal := AValue.AsType<TPoint3D>;
  LJSON := TJSONObject.Create;
  LJSON.AddPair('X', TJSONNumber.Create(LVal.X));
  LJSON.AddPair('Y', TJSONNumber.Create(LVal.Y));
  LJSON.AddPair('Z', TJSONNumber.Create(LVal.Z));
  Result := LJSON;
end;

function TPoint3DSerializer.Deserialize(AValue: TJSONValue; const AData: TValue; AContext: IDeserializerContext): TValue;
var
  LVal: TPoint3D;
begin
  LVal.X := AValue.GetValue<Double>('X');
  LVal.Y := AValue.GetValue<Double>('Y');
  LVal.Z := AValue.GetValue<Double>('Z');

  Result := TValue.From<TPoint3D>(LVal);
end;

{ TParameterSerializer }

class function TParameterSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TParameterContainer.ClassInfo;
end;

function TParameterSerializer.Serialize(const AValue: TValue; AContext: ISerializerContext): TJSONValue;
var
  LParam: TParameterContainer;
begin
  LParam := AValue.AsType<TParameterContainer>;

  if not LParam.ref.ref.IsEmpty then
    Result := AContext.WriteDataMember(LParam.ref)
  else
    Result := AContext.WriteDataMember(LParam.par);
end;

function TParameterSerializer.Deserialize(AValue: TJSONValue; const AData: TValue;
  AContext: IDeserializerContext): TValue;
var
  LVal: TParameterContainer;
  LType: TRttiType;
begin
  LVal := AData.AsType<TParameterContainer>;

  if Assigned((AValue as TJSONObject).GetValue('$ref')) then
  begin
    LType := TRttiUtils.Context.GetType(TReference);
    AContext.ReadDataMember(AValue, LType, LVal.ref);
  end
  else
  begin
    LType := TRttiUtils.Context.GetType(TParameter);
    AContext.ReadDataMember(AValue, LType, LVal.par);
  end;

  Result := TValue.From<TParameterContainer>(LVal);
end;

{ TFontSerializer }

class function TFontSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TFont.ClassInfo;
end;

function TFontSerializer.Serialize(const AValue: TValue; AContext: ISerializerContext): TJSONValue;
var
  LFont: TFont;
  LJSON: TJSONObject;
begin
  LFont := AValue.AsType<TFont>;

  LJSON := TJSONObject.Create;
  LJSON.AddPair('Name', LFont.Name);
  LJSON.AddPair('Orientation', TJSONNumber.Create(LFont.Orientation));
  LJSON.AddPair('Pitch', AContext.WriteDataMember(TValue.From<TFontPitch>(LFont.Pitch)));
  LJSON.AddPair('Size', TJSONNumber.Create(LFont.Size));

  Result := LJSON;
end;

function TFontSerializer.Deserialize(AValue: TJSONValue; const AData: TValue;
  AContext: IDeserializerContext): TValue;
var
  LJSONObject: TJSONObject;
  LJSONValue: TJSONValue;
  LFont: TFont;
begin
  if not (AValue is TJSONObject) then
    raise ENeonException.Create('TFontSerializer.Deserialize: JSON does not represent an object');

  if AData.IsEmpty then
    LFont := TFont.Create
  else
    LFont := AData.AsType<TFont>;

  LJSONObject := AValue as TJSONObject;

  LJSONValue := LJSONObject.GetValue('Name');
  if Assigned(LJSONValue) then
    LFont.Name := LJSONValue.Value;

  LJSONValue := LJSONObject.GetValue('Orientation');
  if Assigned(LJSONValue) then
    LFont.Orientation := (LJSONValue as TJSONNumber).AsInt;

  LJSONValue := LJSONObject.GetValue('Size');
  if Assigned(LJSONValue) then
    LFont.Size := (LJSONValue as TJSONNumber).AsInt;

  Result := TValue.From<TFont>(LFont);
end;

{ TCaseClassSerializer }

function TCaseClassSerializer.Deserialize(AValue: TJSONValue; const AData: TValue;
  AContext: IDeserializerContext): TValue;
var
  LJSONObject: TJSONObject;
  LJSONValue: TJSONValue;
  LVal: TCaseClass;
  LType: TRttiType;
begin

  if AData.IsEmpty then
    LVal := TCaseClass.Create
  else
    LVal := AData.AsType<TCaseClass>;

  LJSONObject := AValue as TJSONObject;

  LJSONValue := LJSONObject.GetValue('First');
  if Assigned(LJSONValue) then
    LVal.FirstProp := (LJSONValue as TJSONNumber).AsInt;

  LJSONValue := LJSONObject.GetValue('Second');
  if Assigned(LJSONValue) then
    LVal.SecondXProp := LJSONValue.Value;

  LJSONValue := LJSONObject.GetValue('Note');
  if Assigned(LJSONValue) then
  begin
    LType := TRttiUtils.Context.GetType(TNote);
    AContext.ReadDataMember(LJSONValue, LType, LVal.Note);
  end;

  Result := TValue.From<TCaseClass>(LVal);
end;

class function TCaseClassSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TCaseClass.ClassInfo;
end;

function TCaseClassSerializer.Serialize(const AValue: TValue; AContext: ISerializerContext): TJSONValue;
var
  LObj: TCaseClass;
  LJSON: TJSONObject;
begin
  LObj := AValue.AsType<TCaseClass>;

  LJSON := TJSONObject.Create;
  LJSON.AddPair('First', TJSONNumber.Create(LObj.FirstProp));
  LJSON.AddPair('Second', LObj.SecondXProp);
  LJSON.AddPair('Note', AContext.WriteDataMember(TValue.From<TNote>(LObj.Note)));

  Result := LJSON;
end;

end.
