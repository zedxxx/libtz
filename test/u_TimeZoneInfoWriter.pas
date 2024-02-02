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
    FFormatSettings: TFormatSettings;
  private
    class function GetDescription(const ATzInfoFull: PTzInfoFull): string;
    class function HtmlEncode(const AText: string): string; static;
  private
    { ITimeZoneInfoWriter }
    function ToKml(const ATzInfoFull: PTzInfoFull): string;
  public
    constructor Create;
  end;

function CreateTzInfoWriter: ITimeZoneInfoWriter;
begin
  Result := TTimeZoneInfoWriter.Create;
end;

{ TTimeZoneInfoWriter }

constructor TTimeZoneInfoWriter.Create;
begin
  inherited Create;
  FFormatSettings.DecimalSeparator := '.';
end;

function TTimeZoneInfoWriter.ToKml(const ATzInfoFull: PTzInfoFull): string;
type
  TPolyRec = record
    Outer: string;
    Inner: array of string;
  end;

  function PointsToStr(const ACount: Integer; APoints: PTzDoublePoint): string;
  var
    I: Integer;
  begin
    Result := '';
    for I := 0 to ACount - 1 do begin
      Result := Result + Format('%.6f,%.6f,0 ', [APoints.X, APoints.Y], FFormatSettings);
      Inc(APoints);
    end;
  end;

  function PolygonsToStr(const APolygons: TArray<TPolyRec>): string;
  var
    I, J: Integer;
  begin
    Result := '';
    for I := 0 to Length(APolygons) - 1 do begin
      Result := Result +
        '<Placemark><name>' + IntToStr(I+1) + '</name>' +
        '<Style><LineStyle><color>ffff0000</color></LineStyle>' +
        '<PolyStyle><color>66ff5555</color></PolyStyle>' +
        '</Style><Polygon>' +
        '<outerBoundaryIs><LinearRing><extrude>1</extrude><coordinates> ' +
        APolygons[I].Outer +
        '</coordinates></LinearRing></outerBoundaryIs>';

      for J := 0 to Length(APolygons[I].Inner) - 1 do begin
        Result := Result +
          '<innerBoundaryIs><LinearRing><extrude>1</extrude><coordinates>' +
          APolygons[I].Inner[J] +
          '</coordinates></LinearRing></innerBoundaryIs>';
      end;

      Result := Result + '</Polygon></Placemark>';
    end;
  end;

  function GetPolygonsArray: TArray<TPolyRec>;
  var
    I, J, K: Integer;
    VPoly: PTzPolygon;
  begin
    K := -1;
    SetLength(Result, ATzInfoFull.PolygonsCount);
    VPoly := ATzInfoFull.Polygons;
    for I := 0 to ATzInfoFull.PolygonsCount - 1 do begin
      if not VPoly.IsHole then begin
        Inc(K);
        Result[K].Outer := PointsToStr(VPoly.PointsCount, VPoly.Points);
      end else begin
        Assert(K>=0);
        J := Length(Result[K].Inner);
        SetLength(Result[K].Inner, J+1);
        Result[K].Inner[J] := PointsToStr(VPoly.PointsCount, VPoly.Points);
      end;
      Inc(VPoly);
    end;
    SetLength(Result, K+1);
  end;

begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8"?>' +
    '<kml xmlns="http://www.opengis.net/kml/2.2" ' +
    'xmlns:gx="http://www.google.com/kml/ext/2.2" ' +
    'xmlns:kml="http://www.opengis.net/kml/2.2" ' +
    'xmlns:atom="http://www.w3.org/2005/Atom">' +
    '<Document>' +
    '<name>' + string(AnsiString(ATzInfoFull.Name)) + '</name>' +
    '<description><![CDATA[' + GetDescription(ATzInfoFull) + ']]></description>' +
	  '<open>1</open>' +
    PolygonsToStr( GetPolygonsArray() ) +
    '</Document></kml>';
end;

class function TTimeZoneInfoWriter.GetDescription(const ATzInfoFull: PTzInfoFull): string;
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
begin
  if ATzInfoFull.PeriodsCount = 1 then begin
    Result := Format('There is one time period in the %d year:', [YearOfPeriods()]);
  end else begin
    Result := Format('There are %d time periods in the %d year:', [ATzInfoFull.PeriodsCount, YearOfPeriods()]);
  end;

  VPeriod := ATzInfoFull.Periods;
  for I := 0 to ATzInfoFull.PeriodsCount - 1 do begin
    case VPeriod.TimeType of
      lttStandard: begin
        Result := Result + '<hr>' +
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
        Result := Result + '<hr>' +
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
        Result := Result + '<hr>' +
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
        Result := Result + '<hr>' +
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
