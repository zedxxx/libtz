unit u_TimeZoneInfoWriter;

interface

uses
  SysUtils,
  DateUtils,
  libtz;

type
  ITimeZoneInfoWriter = interface
    ['{1BC5FE76-EE9D-413C-BE2B-4D85031EE520}']

    function ToKml(const ATzInfoFull: PTzInfoFull): string;
  end;

function CreateTzInfoWriter: ITimeZoneInfoWriter;

implementation

type
  TTimeZoneInfoWriter = class(TInterfacedObject, ITimeZoneInfoWriter)
  private
    class function HtmlEncode(const AText: string): string; static;
  private
    { ITimeZoneInfoWriter }
    function ToKml(const ATzInfoFull: PTzInfoFull): string;
  end;

function CreateTzInfoWriter: ITimeZoneInfoWriter;
begin
  Result := TTimeZoneInfoWriter.Create;
end;

{ TTimeZoneInfoWriter }

function TTimeZoneInfoWriter.ToKml(const ATzInfoFull: PTzInfoFull): string;
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
      'UTC bias (from universal time): ' + HtmlFormat(ABias, [fsBold]);
  end;

  function YearOfPeriods: Word;
  begin
    if ATzInfoFull.PeriodsCount > 0 then begin
      Assert(ATzInfoFull.Periods <> nil);
      Result := YearOf(ATzInfoFull.Periods.StartsAt);
    end else begin
      raise Exception.Create('At least one time period expected!');
    end;
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
  Result := '';

  VDesc := 'Time zone name: ' + HtmlFormat(string(AnsiString(ATzInfoFull.Name)), [fsBold]) + CLineBreak;

  if ATzInfoFull.PeriodsCount = 1 then begin
    VDesc := VDesc + CLineBreak +
      Format('There is one time period in the %d year:', [YearOfPeriods()]);
  end else begin
    VDesc := VDesc + CLineBreak +
      Format('There are %d time periods in the %d year:', [ATzInfoFull.PeriodsCount, YearOfPeriods()]);
  end;

  VPeriod := ATzInfoFull.Periods;
  for I := 0 to ATzInfoFull.PeriodsCount - 1 do begin
    case VPeriod.TimeType of
      lttStandard: begin
        VDesc := VDesc + '<hr>' +
          '<p style="color:green;">' +
          InitialFmt(
            CTimeType[VPeriod.TimeType],
            'In this period the local time (wall clock) is not adjusted and ' +
            'follows the standard rules.',
            VPeriod.StartsAt,
            VPeriod.EndsAt
          ) +
          MoreFmt(
            string(AnsiString(VPeriod.Abbrv)),
            string(AnsiString(VPeriod.Name)),
            FormatDateTime('hh:mm', VPeriod.UtcOffset)
          ) +
          '</p>';
      end;

      lttDaylight: begin
        VDesc := VDesc + '<hr>' +
          '<p style="color:blue;">' +
          InitialFmt(
            CTimeType[VPeriod.TimeType],
            'In this period the local time (wall clock) is adjusted by a ' +
            'specified amout of time (usually an hour).' + CLineBreak +
            'It is considered "summer" time.',
            VPeriod.StartsAt,
            VPeriod.EndsAt
          ) +
          MoreFmt(
            string(AnsiString(VPeriod.Abbrv)),
            string(AnsiString(VPeriod.Name)),
            FormatDateTime('hh:mm', VPeriod.UtcOffset)
          ) +
          '</p>';
      end;

      lttAmbiguous: begin
        VDesc := VDesc + '<hr>' +
          '<p style="color:gray;">' +
          InitialFmt(
            CTimeType[VPeriod.TimeType],
            'In this period the local time (wall clock) can be treated either ' +
            'as being in DST or as begin in standard mode.',
            VPeriod.StartsAt,
            VPeriod.EndsAt
          ) +
          MoreFmt(
            HtmlEncode('<depends on settings>'),
            HtmlEncode('<depends on settings>'),
            HtmlEncode('<depends on settings>')
          ) +
          '</p>';
      end;

      lttInvalid: begin
        VDesc := VDesc + '<hr>' +
          '<p style="color:red;">' +
          InitialFmt(
            CTimeType[VPeriod.TimeType],
            'In this period the local time (wall clock) is invalid. This hour ' +
            'does not "exist" in this time zone.' + CLineBreak +
            'The clock should have been adjusted accordinly.',
            VPeriod.StartsAt,
            VPeriod.EndsAt
          ) +
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

class function TTimeZoneInfoWriter.HtmlEncode(const AText: string): string;
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

end.
