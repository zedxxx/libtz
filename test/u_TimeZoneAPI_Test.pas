unit u_TimeZoneAPI_Test;

interface

uses
  TestFramework;

type
  TTimeZoneAPI = class(TTestCase)
  protected
    procedure SetUp; override;
  published
    procedure TestAPI;
    procedure BenchAPI;
  end;

implementation

uses
  Windows,
  SysUtils,
  DateUtils,
  Diagnostics,
  libtz,
  u_TimeZone_TestCases;

function HtmlEncode(const AText: string): string;
var
  I, J: Integer;

  procedure Encode(const AStr: String);
  begin
    Move(AStr[1], Result[J], Length(AStr) * SizeOf(Char));
    Inc(J, Length(AStr));
  end;

begin
  SetLength(Result, Length(AText) * 6);
  J := 1;
  for I := 1 to length(AText) do begin
    case AText[I] of
      '<': Encode('&lt;');
      '>': Encode('&gt;');
      '&': Encode('&amp;');
      '"': Encode('&quot;');
    else
      Result[J] := AText[I];
      Inc(J);
    end;
  end;
  SetLength(Result, J - 1);
end;

procedure DumpTzInfoToKml(
  const ATzInfo: PTzInfo;
  const ATzInfoFull: PTzInfoFull
);
const
  CLineBreak = '</br>';
type
  THtmlFontStyle = (fsBold, fsUnderline, fsItalic);
  THtmlFontStyleSet = set of THtmlFontStyle;

  function HtmlFormat(const AText: string; const AFontStyle: THtmlFontStyleSet): string;
  begin
    Result := AText;
    if fsBold in AFontStyle then begin
      Result := Format('<b>%s</b>', [Result]);
    end;
    if fsUnderline in AFontStyle then begin
      Result := Format('<u>%s</u>', [Result]);
    end;
    if fsItalic in AFontStyle then begin
      Result := Format('<i>%s</i>', [Result]);
    end;
  end;

  function InitialFmt(const ATimeType, ATimeDesc: string; const AStartsAt, AEndsAt: TDateTime): string;
  const
    CDateFmt = 'yyyy-mm-dd hh:nn:ss';
  begin
    Result :=
      HtmlFormat(ATimeType, [fsBold, fsUnderline]) + ' time from ' +
      HtmlFormat(FormatDateTime(CDateFmt, AStartsAt), [fsBold]) + ' to ' +
      HtmlFormat(FormatDateTime(CDateFmt, AEndsAt), [fsBold]) + CLineBreak +
      HtmlFormat(ATimeDesc, [fsItalic]) + CLineBreak;
  end;

  function MoreFmt(const AAbbreviation, ADisplayName, ABias: string): string;
  begin
    Result :=
      'Time zone abbreviation: ' + HtmlFormat(AAbbreviation, [fsBold]) + CLineBreak +
      'Time zone display name: ' + HtmlFormat(ADisplayName, [fsBold]) + CLineBreak +
      'UTC bias (from universal time): ' + HtmlFormat(ABias, [fsBold]) + CLineBreak;
  end;

const
  CTimeType: array[TTzLocalTimeType] of string = (
    'Standard', 'Daylight', 'Ambiguous', 'Invalid'
  );
var
  I: Integer;
  VPeriod: PTzPeriod;
  VDesc: string;
begin
  VPeriod := ATzInfoFull.Periods;
  for I := 0 to ATzInfoFull.PeriodsCount - 1 do begin
    case VPeriod.TimeType of
      lttStandard: begin
        VDesc := VDesc + CLineBreak +
          '<p style="color:green;">' +
          InitialFmt(
            CTimeType[VPeriod.TimeType],
            'In this period the local time (wall clock) is not adjusted and ' +
            'follows the standard rules.',
            VPeriod.StartsAt,
            VPeriod.EndsAt
          ) + CLineBreak +
          MoreFmt(
            string(AnsiString(VPeriod.Abbrv)),
            string(AnsiString(VPeriod.Name)),
            FormatDateTime('hh:mm', VPeriod.UtcOffset)
          ) +
          '</p>';
      end;

      lttDaylight: begin
        VDesc := VDesc + CLineBreak +
          '<p style="color:blue;">' +
          InitialFmt(
            CTimeType[VPeriod.TimeType],
            'In this period the local time (wall clock) is adjusted by a ' +
            'specified amout of time (usually an hour).' + CLineBreak +
            'It is considered "summer" time.',
            VPeriod.StartsAt,
            VPeriod.EndsAt
          ) + CLineBreak +
          MoreFmt(
            string(AnsiString(VPeriod.Abbrv)),
            string(AnsiString(VPeriod.Name)),
            FormatDateTime('hh:mm', VPeriod.UtcOffset)
          ) +
          '</p>';
      end;

      lttAmbiguous: begin
        VDesc := VDesc + CLineBreak +
          '<p style="color:gray;">' +
          InitialFmt(
            CTimeType[VPeriod.TimeType],
            'In this period the local time (wall clock) can be treated either ' +
            'as being in DST or as begin in standard mode.',
            VPeriod.StartsAt,
            VPeriod.EndsAt
          ) + CLineBreak +
          MoreFmt(
            HtmlEncode('<depends on settings>'),
            HtmlEncode('<depends on settings>'),
            HtmlEncode('<depends on settings>')
          ) +
          '</p>';
      end;

      lttInvalid: begin
        VDesc := VDesc + CLineBreak +
          '<p style="color:red;">' +
          InitialFmt(
            CTimeType[VPeriod.TimeType],
            'In this period the local time (wall clock) is invalid. This hour ' +
            'does not "exist" in this time zone.' + CLineBreak +
            'The clock should have been adjusted accordinly.',
            VPeriod.StartsAt,
            VPeriod.EndsAt
          ) + CLineBreak +
          MoreFmt(
            HtmlEncode('<none>'),
            HtmlEncode('<none>'),
            HtmlEncode('<none>')
          ) +
          '</p>';
      end;
    else
      raise Exception.CreateFmt(
        'Unexpected Period TimeType: %d', [Integer(VPeriod.TimeType)]
      );
    end;

    Inc(VPeriod);
  end;


  // ToDo
end;

{ TTimeZoneAPI }

procedure TTimeZoneAPI.SetUp;
begin
  inherited SetUp;

  Check(LibTzInitialize, 'Library is not initialized!');
end;

procedure TTimeZoneAPI.TestAPI;
var
  I: Integer;
  VCtx: Pointer;
  VResult: Boolean;
  VUtcTime: TDateTime;
  VTzInfo: TTzInfo;
  VTzInfoFull: TTzInfoFull;
  VTzVersion: PTzVersionInfo;
begin
  VCtx := tz_ctx_new();
  try
    Assert(VCtx <> nil);
    for I := 0 to Length(cTestCases) - 1 do begin
      VUtcTime := ISO8601ToDate(cTestCases[I].UTC);

      VResult := tz_get_info(VCtx, cTestCases[I].X, cTestCases[I].Y, VUtcTime, @VTzInfo);
      tz_check_result(VCtx, VResult);

      CheckEqualsString(cTestCases[I].Name, string(VTzInfo.Name));
      CheckEquals(cTestCases[I].Offset, VTzInfo.Offset);

      VUtcTime := ISO8601ToDate('2000-02-02T12:00:00');
      VResult := tz_get_info_full(VCtx, cTestCases[I].X, cTestCases[I].Y, VUtcTime, @VTzInfoFull);
      tz_check_result(VCtx, VResult);

      if I = 0 then begin
        DumpTzInfoToKml(@VTzInfo, @VTzInfoFull);
      end;
    end;
  finally
    tz_ctx_free(VCtx);
  end;

  VTzVersion := tz_get_version();

  OutputDebugString(
    PChar(
      'libtz v' + string(VTzVersion.Lib) + ', ' +
      'tzdb v' + string(VTzVersion.Data) + ', ' +
      'tzborder v' + string(VTzVersion.Border)
    )
  );
end;

procedure TTimeZoneAPI.BenchAPI;
const
  cBenchCount = 10000;
var
  I, J: Integer;
  VCtx: Pointer;
  VResult: Boolean;
  VUtcTime: TDateTime;
  VTzInfo: TTzInfo;
  VTime: TStopwatch;
begin
  VCtx := tz_ctx_new();
  try
    VTime := TStopwatch.Create;

    for J := 0 to cBenchCount - 1 do begin
      for I := 0 to Length(cBenchCases) - 1 do begin
        VUtcTime := ISO8601ToDate(cBenchCases[I].UTC);

        VTime.Start;
        VResult := tz_get_info(VCtx, cBenchCases[I].X, cBenchCases[I].Y, VUtcTime, @VTzInfo);
        VTime.Stop;

        tz_check_result(VCtx, VResult);
      end;
    end;

    OutputDebugString(PChar(IntToStr(VTime.ElapsedMilliseconds) + ' ms'));
  finally
    tz_ctx_free(VCtx);
  end;
end;

initialization
  RegisterTest(TTimeZoneAPI.Suite);

end.
