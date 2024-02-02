unit libtz;

interface

uses
  SysUtils;

const
  libtz_dll = 'libtz.dll';

{$MINENUMSIZE 4}
type
  ELibTzError = class(Exception);

  TTzInfo = record
    Name: PAnsiChar;
    Offset: TDateTime;
  end;
  PTzInfo = ^TTzInfo;

  TTzDoublePoint = record
    X: Double;
    Y: Double;
  end;
  PTzDoublePoint = ^TTzDoublePoint;

  TTzPolygon = record
    IsHole: LongBool;

    PointsCount: Integer;
    Points: PTzDoublePoint;
  end;
  PTzPolygon = ^TTzPolygon;

  TTzLocalTimeType = (
    lttStandard,
    lttDaylight,
    lttAmbiguous,
    lttInvalid
  );

  TTzPeriod = record
    Abbrv: PAnsiChar;
    Name: PAnsiChar;

    UtcOffset: TDateTime;

    StartsAt: TDateTime;
    EndsAt: TDateTime;

    TimeType: TTzLocalTimeType;
  end;
  PTzPeriod = ^TTzPeriod;

  TTzInfoFull = record
    Name: PAnsiChar;

    PeriodsCount: Integer;
    Periods: PTzPeriod;

    PolygonsCount: Integer;
    Polygons: PTzPolygon;
  end;
  PTzInfoFull = ^TTzInfoFull;

  TTzVersionInfo = record
    Lib: PAnsiChar;
    Data: PAnsiChar;
    Border: PAnsiChar;
  end;
  PTzVersionInfo = ^TTzVersionInfo;

var
  tz_ctx_new: function(): Pointer; cdecl;
  tz_ctx_free: procedure(const ACtx: Pointer); cdecl;

  tz_get_info: function(const ACtx: Pointer; const ALon, ALat: Double;
    const AUtcTime: TDateTime; const AInfo: PTzInfo): Boolean; cdecl;

  tz_get_info_full: function(const ACtx: Pointer; const ALon, ALat: Double;
    const AUtcTime: TDateTime; const AInfo: PTzInfoFull): Boolean; cdecl;

  tz_get_error: function(const ACtx: Pointer): PAnsiChar; cdecl;
  tz_get_version: function(): PTzVersionInfo; cdecl;

procedure tz_check_result(const ACtx: Pointer; const AResult: Boolean);

function LibTzInitialize(const ALibName: string = libtz_dll): Boolean;

implementation

uses
  Windows,
  SyncObjs;

var
  GLock: TCriticalSection = nil;
  GHandle: THandle = 0;
  GInitialized: Boolean = False;

procedure tz_check_result(const ACtx: Pointer; const AResult: Boolean);
var
  P: PAnsiChar;
  VMsg: string;
begin
  Assert(ACtx <> nil);

  if AResult then begin
    Exit;
  end;

  P := tz_get_error(ACtx);

  if P <> nil then begin
    VMsg := {$IFDEF UNICODE}UTF8ToString(P){$ELSE}UTF8Decode(P){$ENDIF};
  end else begin
    VMsg := 'unknown error'
  end;

  raise ELibTzError.Create(VMsg);
end;

procedure LibTzFreeAndNil(var AHandle: THandle);
begin
  tz_ctx_new := nil;
  tz_ctx_free := nil;
  tz_get_info := nil;
  tz_get_info_full := nil;
  tz_get_error := nil;
  tz_get_version := nil;

  if AHandle <> 0 then begin
    FreeLibrary(AHandle);
    AHandle := 0;
  end;
end;

function LibTzInitialize(const ALibName: string = libtz_dll): Boolean;
var
  VHandle: THandle;

  function _LoadProc(const AName: string): Pointer;
  begin
    Result := GetProcAddress(VHandle, PChar(AName));
    if Result = nil then begin
      raise Exception.CreateFmt('Unable to find "%s()" in %s', [AName, ALibName]);
    end;
  end;

begin
  if GInitialized then begin
    Result := GHandle <> 0;
    Exit;
  end;

  GLock.Acquire;
  try
    if GInitialized then begin
      Result := GHandle <> 0;
      Exit;
    end;
    VHandle := 0;
    try
      VHandle := SafeLoadLibrary(ExtractFilePath(ParamStr(0)) + ALibName);
      if VHandle = 0 then begin
        VHandle := SafeLoadLibrary(ALibName);
      end;
      if VHandle = 0 then begin
        raise Exception.CreateFmt('Unable to load library %s', [ALibName]);
      end;

      tz_ctx_new := _LoadProc('tz_ctx_new');
      tz_ctx_free := _LoadProc('tz_ctx_free');
      tz_get_info := _LoadProc('tz_get_info');
      tz_get_info_full := _LoadProc('tz_get_info_full');
      tz_get_error := _LoadProc('tz_get_error');
      tz_get_version := _LoadProc('tz_get_version');

      GHandle := VHandle;
      Result := True;
    except
      on E: Exception do begin
        LibTzFreeAndNil(VHandle);
        raise;
      end;
    end;
  finally
    GInitialized := True;
    GLock.Release;
  end;
end;

initialization
  GLock := TCriticalSection.Create;

finalization
  LibTzFreeAndNil(GHandle);
  FreeAndNil(GLock);

end.
