unit u_TimeZoneCtx;

interface

uses
  TZDB,
  t_TimeZoneCtx,
  u_TimeZoneDetect;

type
  TTimeZoneCtx = class
  private
    FTzDetect: TTimeZoneDetect;

    FTzName: PAnsiChar;
    FTzBundled: TBundledTimeZone;

    FErrorMessage: UTF8String;

    class function OffsetFromLongitude(const ALon: Double): TDateTime;
  public
    procedure SetError(const AMsg: UTF8String);
    function GetError: PAnsiChar;

    procedure GetInfo(
      const ALon, ALat: Double;
      const AUtcTime: TDateTime;
      const AInfo: PTzInfo
    );
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  SysUtils,
  Math;

{ TTimeZoneCtx }

constructor TTimeZoneCtx.Create;
begin
  inherited Create;

  FTzName := nil;
  FTzBundled := nil;
  FErrorMessage := '';

  FTzDetect := TTimeZoneDetect.Create;
end;

destructor TTimeZoneCtx.Destroy;
begin
  FTzName := nil;
  FTzBundled := nil;
  FErrorMessage := '';

  FreeAndNil(FTzDetect);

  inherited Destroy;
end;

procedure TTimeZoneCtx.GetInfo(const ALon, ALat: Double;
  const AUtcTime: TDateTime; const AInfo: PTzInfo);
var
  VTzLocalTime: TDateTime;
begin
  AInfo.Name := FTzDetect.LonLatToTzName(ALon, ALat);

  if AInfo.Name = nil then begin
    FTzName := nil;
    AInfo.Offset := OffsetFromLongitude(ALon);
    Exit;
  end;

  if FTzName <> AInfo.Name then begin
    FTzName := AInfo.Name;
    FTzBundled := TBundledTimeZone.GetTimeZone(string(FTzName));
  end;
  Assert(FTzBundled <> nil);

  VTzLocalTime := FTzBundled.ToLocalTime(AUtcTime);

  {$IFDEF FPC}
  AInfo.Offset := FTzBundled.GetUtcOffset(VTzLocalTime) / 3600 / 24;
  {$ELSE}
  AInfo.Offset := FTzBundled.GetUtcOffset(VTzLocalTime).TotalHours / 24;
  {$ENDIF}
end;

class function TTimeZoneCtx.OffsetFromLongitude(const ALon: Double): TDateTime;
var
  VPosNo: Double;
  VHours: Double;
  VDirection: Integer;
begin
  if ALon < 0 then begin
    VDirection := -1;
  end else begin
    VDirection := 1;
  end;

  VPosNo := Sqrt(Power(ALon, 2));
  if VPosNo <= 7.5 then begin
    Result := 0;
    Exit;
  end;

  VPosNo := VPosNo - 7.5;
  VHours := VPosNo / 15;
  if FMod(VPosNo, 15) > 0 then begin
    VHours := VHours + 1;
  end;

  Result := VDirection * Floor(VHours) / 24;
end;

function TTimeZoneCtx.GetError: PAnsiChar;
begin
  Result := PAnsiChar(FErrorMessage);
end;

procedure TTimeZoneCtx.SetError(const AMsg: UTF8String);
begin
  FErrorMessage := AMsg;
end;

end.
