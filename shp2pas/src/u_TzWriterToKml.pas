unit u_TzWriterToKml;

interface

uses
  SysUtils,
  t_TzTypes,
  i_TzCoordConverter,
  u_TzWriterBase;

type
  TTzWriterToKml = class(TTzWriterBase)
  private
    type TInnerArray = array of string;
  private
    FFormatSettings: TFormatSettings;
  private
    function GetFillColor(const AIndex: Integer): Cardinal;
    function PointsToStr(const APoints: PFixedPoints): string;
    procedure WritePolygon(
      const AName: string;
      const AOuter: string;
      const AInner: TInnerArray;
      const AFillColor: Cardinal
    );
  protected
    procedure OnTzRead(const ATimeZone: PTimeZoneRec); override;
  public
    constructor Create(
      const AOutputPath: string;
      const ACoordConverter: ITzCoordConverter
    ); override;
  end;

implementation

const
  cLF = #10;
  cTab = #09;

{ TTzWriterToKml }

constructor TTzWriterToKml.Create(
  const AOutputPath: string;
  const ACoordConverter: ITzCoordConverter
);
begin
  inherited;
  FFormatSettings.DecimalSeparator := '.';
end;

procedure TTzWriterToKml.OnTzRead(const ATimeZone: PTimeZoneRec);
var
  I, J, K: Integer;
  VOuter: string;
  VInner: TInnerArray;
  VPoly: PFixedPolygon;
  VFillColor: Cardinal;
begin
  // header
  WriteString(
    '<?xml version="1.0" encoding="UTF-8"?>' + cLF +
    '<kml xmlns="http://www.opengis.net/kml/2.2" ' +
    'xmlns:gx="http://www.google.com/kml/ext/2.2" ' +
    'xmlns:kml="http://www.opengis.net/kml/2.2" ' +
    'xmlns:atom="http://www.w3.org/2005/Atom">' + cLF +
    '<Document>' + cLF
  );

  WriteString(
    cTab + '<name>' + ATimeZone.Name + '</name>' + cLF +
	  cTab + '<open>1</open>' + cLF
  );

  K := 0;
  VFillColor := GetFillColor(ATimeZone.Id);
  for I := 0 to Length(ATimeZone.FixedPolygon) - 1 do begin
    VPoly := @ATimeZone.FixedPolygon[I];

    VOuter := PointsToStr(@VPoly.Points);
    Assert(VOuter <> '');

    SetLength(VInner, Length(VPoly.Holes));
    for J := 0 to Length(VPoly.Holes) - 1 do begin
      VInner[J] := PointsToStr(@VPoly.Holes[J].Points);
      Assert(VInner[J] <> '');
    end;

    WritePolygon(IntToStr(K), VOuter, VInner, VFillColor);
    Inc(K);
  end;

  Assert(K > 0);

  // footer
  WriteString('</Document>' + cLF + '</kml>');

  SaveAndClear(EscapeTzName(ATimeZone.Name) + '.kml');
end;

function TTzWriterToKml.PointsToStr(const APoints: PFixedPoints): string;
var
  I: Integer;
  VPoint: TFloatPoint;
begin
  Result := '';
  for I := 0 to Length(APoints^) - 1 do begin
    VPoint := FCoordConverter.FixedToFloat(APoints^[I]);
    Result := Result + Format('%.6f,%.6f,0 ', [VPoint.X, VPoint.Y], FFormatSettings);
  end;
end;

procedure TTzWriterToKml.WritePolygon(
  const AName: string;
  const AOuter: string;
  const AInner: TInnerArray;
  const AFillColor: Cardinal
);
var
  I: Integer;
begin
  WriteString(
    cTab + '<Placemark>' + cLF +
    cTab + cTab + '<name>' + AName + '</name>' + cLF +
    cTab + cTab + '<Style>' + cLF +
    cTab + cTab + cTab + '<LineStyle>' + cLF +
    cTab + cTab + cTab + cTab + '<color>ffff0000</color>' + cLF +
    cTab + cTab + cTab + '</LineStyle>' + cLF +
    cTab + cTab + cTab + '<PolyStyle>' + cLF +
    cTab + cTab + cTab + cTab + '<color>80' + IntToHex(AFillColor, 6) + '</color>' + cLF +
    cTab + cTab + cTab + '</PolyStyle>' + cLF +
    cTab + cTab + '</Style>' + cLF +
    cTab + cTab + '<Polygon>' + cLF
  );

  WriteString(
    cTab + cTab + cTab + '<outerBoundaryIs>' + cLF +
    cTab + cTab + cTab + cTab + '<LinearRing>' + cLF +
    cTab + cTab + cTab + cTab + cTab + '<extrude>1</extrude>' + cLF +
    cTab + cTab + cTab + cTab + cTab + '<coordinates>' + cLF +
    cTab + cTab + cTab + cTab + cTab + cTab + AOuter + cLF +
    cTab + cTab + cTab + cTab + cTab + '</coordinates>' + cLF +
    cTab + cTab + cTab + cTab + '</LinearRing>' + cLF +
    cTab + cTab + cTab + '</outerBoundaryIs>' + cLF
  );

  for I := 0 to Length(AInner) - 1 do begin
    if AInner[I] = '' then begin
      Continue;
    end;
    WriteString(
      cTab + cTab + cTab + '<innerBoundaryIs>' + cLF +
      cTab + cTab + cTab + cTab + '<LinearRing>' + cLF +
      cTab + cTab + cTab + cTab + cTab + '<extrude>1</extrude>' + cLF +
      cTab + cTab + cTab + cTab + cTab + '<coordinates>' + cLF +
      cTab + cTab + cTab + cTab + cTab + cTab + AInner[I] + cLF +
      cTab + cTab + cTab + cTab + cTab + '</coordinates>' + cLF +
      cTab + cTab + cTab + cTab + '</LinearRing>' + cLF +
      cTab + cTab + cTab + '</innerBoundaryIs>' + cLF
    );
  end;

  WriteString(
    cTab + cTab + '</Polygon>' + cLF +
    cTab + '</Placemark>' + cLF
  );
end;

function TTzWriterToKml.GetFillColor(const AIndex: Integer): Cardinal;
const
  CStep = 7;
const
  //http://docwiki.embarcadero.com/RADStudio/Sydney/en/Colors_in_the_VCL#Web_Colors
  CWebColors: array [0..122] of Cardinal = (
    $FAFAFF, $F0FAFF, $F5F0FF, $E6F5FD, $F0FFFF, $DCF8FF, $DCF5F5, $D7EBFA,
    $B3DEF5, $FFF8F0, $FFF8F8, $FAE6E6, $EEF5FF, $E0FFFF, $D5EFFF, $ADDEFF,
    $B5E4FF, $87B8DE, $FFFFF0, $FAFFF5, $F0FFF0, $E6F0FA, $CDFAFF, $CDEBFF,
    $C4E4FF, $B9DAFF, $8CB4D2, $00FFFF, $008CFF, $0000FF, $00008B, $000080,
    $5C5CCD, $7280FA, $507FFF, $00D7FF, $4763FF, $3C14DC, $2A2AA5, $1E69D2,
    $60A4F4, $7AA0FF, $8080F0, $00A5FF, $0045FF, $2222B2, $13458B, $2D52A0,
    $3F85CD, $7A96E9, $8F8FBC, $AAE8EE, $D2FAFA, $008080, $228B22, $2FFFAD,
    $00FF7F, $90EE90, $D4FF7F, $578B2E, $20A5DA, $8CE6F0, $238E6B, $008000,
    $32CD9A, $00FC7C, $98FB98, $AACD66, $71B33C, $0B86B8, $6BB7BD, $2F6B55,
    $006400, $32CD32, $00FF00, $7FFF00, $9AFA00, $8FBC8F, $AAB220, $EEEEAF,
    $FFFFE0, $E6D8AD, $FACE87, $ED9564, $8B0000, $82004B, $CCD148, $D0E040,
    $FFFF00, $E6E0B0, $EBCE87, $E16941, $CD0000, $701919, $D1CE00, $A09E5F,
    $8B8B00, $808000, $FFBF00, $FF901E, $FF0000, $800000, $D30094, $CC3299,
    $FF00FF, $8B008B, $8515C7, $9370DB, $E22B8A, $D355BA, $DB7093, $800080,
    $9314FF, $C1B6FF, $EE82EE, $D670DA, $DDA0DD, $D8BFD8, $B469FF, $CBC0FF,
    $DEC4B0, $EE687B, $998877
  );
begin
  Result := CWebColors[(AIndex * CStep) mod Length(CWebColors)];
end;

end.
