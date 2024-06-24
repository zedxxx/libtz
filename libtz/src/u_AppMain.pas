unit u_AppMain;

interface

uses
  t_TimeZoneCtx;

function tz_ctx_new: Pointer; cdecl;
procedure tz_ctx_free(const ACtx: Pointer); cdecl;

function tz_get_info(const ACtx: Pointer; const ALon, ALat: Double;
  const AUtcTime: TDateTime; const AInfo: PTzInfo): Boolean; cdecl;

function tz_get_info_full(const ACtx: Pointer; const ALon, ALat: Double;
  const AUtcTime: TDateTime; const AInfo: PTzInfoFull): Boolean; cdecl;

function tz_get_error(const ACtx: Pointer): PAnsiChar; cdecl;
function tz_get_version: PTzVersionInfo; cdecl;

implementation

uses
  SysUtils,
  u_TimeZoneCtx;

procedure _SaveErrorMessage(const ACtx: Pointer; const AMsg: string); overload;
begin
  Assert(ACtx <> nil);
  try
    TTimeZoneCtx(ACtx).SetError( UTF8Encode(AMsg) );
  except
    // do nothing
  end;
end;

procedure _SaveErrorMessage(const ACtx: Pointer; const AErr: Exception); overload;
begin
  Assert(ACtx <> nil);
  try
    TTimeZoneCtx(ACtx).SetError( UTF8Encode(AErr.ClassName + ': ' + AErr.Message) );
  except
    // do nothing
  end;
end;

//----------------------------------------------------------------------------//

function tz_ctx_new: Pointer;
begin
  try
    Result := TTimeZoneCtx.Create;
  except
    Result := nil;
  end;
end;

procedure tz_ctx_free(const ACtx: Pointer);
begin
  if ACtx = nil then begin
    Exit;
  end;
  try
    TTimeZoneCtx(ACtx).Free;
  except
    // do nothing
  end;
end;

function tz_get_info(const ACtx: Pointer; const ALon, ALat: Double;
  const AUtcTime: TDateTime; const AInfo: PTzInfo): Boolean;
begin
  Result := False;

  if ACtx = nil then begin
    Exit;
  end;

  try
    TTimeZoneCtx(ACtx).GetInfo(ALon, ALat, AUtcTime, AInfo);
    Result := True;
  except
    on E: Exception do begin
      _SaveErrorMessage(ACtx, E);
    end;
  end;
end;

function tz_get_info_full(const ACtx: Pointer; const ALon, ALat: Double;
  const AUtcTime: TDateTime; const AInfo: PTzInfoFull): Boolean;
begin
  Result := False;

  if ACtx = nil then begin
    Exit;
  end;

  try
    TTimeZoneCtx(ACtx).GetInfoFull(ALon, ALat, AUtcTime, AInfo);
    Result := True;
  except
    on E: Exception do begin
      _SaveErrorMessage(ACtx, E);
    end;
  end;
end;

function tz_get_error(const ACtx: Pointer): PAnsiChar;
begin
  if ACtx = nil then begin
    Result := 'Context is not allocated!';
    Exit;
  end;
  try
    Result := TTimeZoneCtx(ACtx).GetError;
  except
    Result := 'tz_get_error() fail!';
  end;
end;

const
  CVersionInfo: TTzVersionInfo = (
    Lib    : '1.2.0';
    Data   : '2024a'; // https://github.com/pavkam/tzdb/releases
    Border : '2024a'; // https://github.com/evansiroky/timezone-boundary-builder/releases
  );

function tz_get_version: PTzVersionInfo;
begin
  Result := @CVersionInfo;
end;

end.
