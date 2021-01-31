unit u_TzWriterToPas;

interface

uses
  Classes,
  SysUtils,
  t_TzTypes,
  i_TzCoordConverter,
  u_TzWriterBase;

type
  TTzWriterToPas = class(TTzWriterBase)
  private
    FTzNameList: TStringList;
    FTzTree: string;

    procedure WriteTzTypesUnit;
    procedure WriteTzConstUnit;
    procedure WriteTzUnit(const ATimeZone: PTimeZoneRec);

    procedure CollectPoints(
      const ATzName: string;
      const ATimeZone: PTimeZoneRec;
      out APoints: string;
      out ATzArraysCount: Integer
    );
    function PointsToString(
      const ATzName: string;
      const APoints: TFixedPoints;
      const ATzArrayIndex: Integer
    ): string;

    procedure CollectBounds(
      const ATzName: string;
      const ATimeZone: PTimeZoneRec;
      const ATzArraysCount: Integer;
      out ABounds: string;
      out ATzBoundIndex: Integer
    );
    function BoundsToString(
      const ATzName: string;
      const ABounds: TFixedRectArray
    ): string;

    procedure CollectPolygons(
      const ATzName: string;
      const ATimeZone: PTimeZoneRec;
      out APolygons: string
    );

    function TzInfoToString(
      const ATzName: string;
      const ATzNameOrigin: string;
      const ABoundsIndex: Integer;
      const APolygonsCount: Integer
    ): string;
  public
    procedure OnTzRead(const ATimeZone: PTimeZoneRec); override;
    procedure OnTzTreeRead(const ATreeRoot: PTreeNode); override;
  public
    constructor Create(
      const AOutputPath: string;
      const ACoordConverter: ITzCoordConverter
    ); override;
    destructor Destroy; override;
  end;

implementation

const
  cTab = '  ';
  cCRLF = #13#10;

const
  cTzTypesUnitName = 't_TzTypes';
  cTzConstUnitName = 'c_TzConst';

{ TTzWriterToPas }

constructor TTzWriterToPas.Create(
  const AOutputPath: string;
  const ACoordConverter: ITzCoordConverter
);
begin
  inherited Create(AOutputPath, ACoordConverter);

  FTzNameList := TStringList.Create;
  FTzNameList.Sorted := True;
  FTzNameList.Duplicates := dupError;

  FTzTree := '';

  WriteTzTypesUnit;
end;

destructor TTzWriterToPas.Destroy;
begin
  WriteTzConstUnit;
  FreeAndNil(FTzNameList);

  inherited Destroy;
end;

procedure TTzWriterToPas.OnTzRead(const ATimeZone: PTimeZoneRec);
begin
  FTzNameList.Add(EscapeTzName(ATimeZone.Name));
  WriteTzUnit(ATimeZone);
end;

procedure TTzWriterToPas.OnTzTreeRead(const ATreeRoot: PTreeNode);
var
  VNodesStr: array of string;

  procedure NodeToString(
    const ATzNodeZoneInfo: TStringList;
    const ANode: PTreeNode
  );
  var
    I, J: Integer;
    VSubNodes: string;
    VFirstZoneInfo: string;
  begin
    if Length(ANode.ShapeIds) = 0 then begin
      VFirstZoneInfo := '0';
    end else begin
      VFirstZoneInfo := IntToStr(ATzNodeZoneInfo.Count);
    end;

    for I := 0 to Length(ANode.ShapeIds) - 1 do begin
      ATzNodeZoneInfo.Add(FTzNameList.Strings[ANode.ShapeIds[I]]);
    end;

    VSubNodes := '';
    for I := 0 to 3 do begin
      if VSubNodes <> '' then begin
        VSubNodes := VSubNodes + ', ';
      end;
      if Length(ANode.SubNodes) <= I then begin
        VSubNodes := VSubNodes + 'nil';
      end else begin
        VSubNodes := VSubNodes + '@cTzNode_' + IntToStr(ANode.SubNodes[I].NodeId);
      end;
    end;

    for I := 0 to Length(ANode.SubNodes) - 1 do begin
      NodeToString(ATzNodeZoneInfo, ANode.SubNodes[I]);
    end;

    J := Length(VNodesStr);
    SetLength(VNodesStr, J + 1);

    VNodesStr[J] := cCRLF + '  ' + Format(
      'cTzNode_%d: TTimeZoneNode = (' + cCRLF + '  ' +
      '  Bound: (Min: (X: %d; Y: %d); Max: (X: %d; Y: %d));' + cCRLF + '  ' +
      '  ZoneInfoCount: %d;' + cCRLF + '  ' +
      '  FirstZoneInfoIndex: %s;' + cCRLF + '  ' +
      '  SubNode: (%s)' + cCRLF + '  ' +
      ');' + cCRLF,
      [ANode.NodeId, ANode.Bounds.Min.X, ANode.Bounds.Min.Y, ANode.Bounds.Max.X,
      ANode.Bounds.Max.Y, Length(ANode.ShapeIds), VFirstZoneInfo, VSubNodes]
    );
  end;

var
  I: Integer;
  VStr: string;
  VTzNodeZoneInfo: TStringList;
begin
  VTzNodeZoneInfo := TStringList.Create;
  try
    SetLength(VNodesStr, 0);
    NodeToString(VTzNodeZoneInfo, ATreeRoot);

    Assert(VTzNodeZoneInfo.Count < $FFFF);

    VStr := '';
    for I := 0 to VTzNodeZoneInfo.Count - 1 do begin
      if I = 0 then begin
        VStr := '    @c' + VTzNodeZoneInfo.Strings[I];
      end else begin
        VStr := VStr + ',' + cCRLF + '    @c' + VTzNodeZoneInfo.Strings[I];
      end;
    end;

    VStr := Format(
      '  cTzNodeZoneInfo: array [0..%d] of PTimeZoneInfo = (' + cCRLF +
      '%s' + cCRLF +
      '  );' + cCRLF,
      [VTzNodeZoneInfo.Count - 1, VStr]
    );

    for I := 0 to Length(VNodesStr) - 1 do begin
      FTzTree := FTzTree + VNodesStr[I];
    end;

    FTzTree := VStr + FTzTree + cCRLF +
      '  cTzTreeRoot: PTimeZoneNode = @cTzNode_0;' + cCRLF;
  finally
    VTzNodeZoneInfo.Free;
  end;
end;

procedure TTzWriterToPas.WriteTzTypesUnit;
const
  cIntType: array [Boolean] of string = ('SmallInt', 'Integer');
begin
  WriteString(
    'unit ' + cTzTypesUnitName + ';' + cCRLF +
    cCRLF +
    'interface' + cCRLF +
    cCRLF +
    'type' + cCRLF +
    cTab + 'TTimeZoneInt = ' + cIntType[FCoordConverter.Precision > 16] + ';' + cCRLF +
    cTab + 'PTimeZoneInt = ^TTimeZoneInt;' + cCRLF +
    cCRLF +
    cTab + 'TTimeZonePoint = packed record' + cCRLF +
    cTab + cTab + 'X: TTimeZoneInt;' + cCRLF +
    cTab + cTab + 'Y: TTimeZoneInt;' + cCRLF +
    cTab + 'end;' + cCRLF +
    cTab + 'PTimeZonePoint = ^TTimeZonePoint;' + cCRLF +
    cCRLF +
    cTab + 'TTimeZoneBound = record' + cCRLF +
    cTab + cTab + 'Min: TTimeZonePoint;' + cCRLF +
    cTab + cTab + 'Max: TTimeZonePoint;' + cCRLF +
    cTab + 'end;' + cCRLF +
    cTab + 'PTimeZoneBound = ^TTimeZoneBound;' + cCRLF +
    cCRLF +
    cTab + 'TTimeZoneHole = record' + cCRLF +
    cTab + cTab + 'Bound: PTimeZoneBound;' + cCRLF +
    cTab + cTab + 'PointsCount: Integer;' + cCRLF +
    cTab + cTab + 'FirstPoint: PTimeZonePoint;' + cCRLF +
    cTab + 'end;' + cCRLF +
    cTab + 'PTimeZoneHole = ^TTimeZoneHole;' + cCRLF +
    cCRLF +
    cTab + 'TTimeZonePolygon = record' + cCRLF +
    cTab + cTab + 'Bound: PTimeZoneBound;' + cCRLF +
    cTab + cTab + 'PointsCount: Integer;' + cCRLF +
    cTab + cTab + 'FirstPoint: PTimeZonePoint;' + cCRLF +
    cTab + cTab + 'HolesCount: Integer;' + cCRLF +
    cTab + cTab + 'FirstHole: PTimeZoneHole;' + cCRLF +
    cTab + 'end;' + cCRLF +
    cTab + 'PTimeZonePolygon = ^TTimeZonePolygon;' + cCRLF +
    cCRLF +
    cTab + 'TTimeZoneInfo = record' + cCRLF +
    cTab + cTab + 'TZID: PAnsiChar;' + cCRLF +
    cTab + cTab + 'Bound: PTimeZoneBound;' + cCRLF +
    cTab + cTab + 'PolygonsCount: Integer;' + cCRLF +
    cTab + cTab + 'FirstPolygon: PTimeZonePolygon;' + cCRLF +
    cTab + 'end;' + cCRLF +
    cTab + 'PTimeZoneInfo = ^TTimeZoneInfo;' + cCRLF +
    cCRLF +
    cTab + 'PTimeZoneNode = ^TTimeZoneNode;' + cCRLF +
    cTab + 'TTimeZoneNode = record' + cCRLF +
    cTab + cTab + 'Bound: TTimeZoneBound;' + cCRLF +
    cTab + cTab + 'ZoneInfoCount: Word;' + cCRLF +
    cTab + cTab + 'FirstZoneInfoIndex: Word;' + cCRLF +
    cTab + cTab + 'SubNode: array [0..3] of PTimeZoneNode;' + cCRLF +
    cTab + 'end;' + cCRLF +
    cCRLF +
    'implementation' + cCRLF +
    cCRLF +
    'end.'
  );

  SaveAndClear(cTzTypesUnitName + '.pas');
end;

procedure TTzWriterToPas.WriteTzConstUnit;
var
  I: Integer;
  VUses, VConst, VSep: string;
begin
  // prepare uses
  VUses := cTab + cTzTypesUnitName;
  for I := 0 to FTzNameList.Count - 1 do begin
    VUses := VUses + ',' + cCRLF + cTab + 'c_' + FTzNameList.Strings[I];
  end;
  VUses := VUses + ';' + cCRLF;

  // prepare const
  VConst := cCRLF + cTab;
  for I := 0 to FTzNameList.Count - 1 do begin
    if I = FTzNameList.Count - 1 then begin
      VSep := '';
    end else begin
      VSep := ',';
    end;
    VConst := VConst + cTab + '@c' + FTzNameList.Strings[I] + VSep + cCRLF + cTab;
  end;
  VConst :=
    cTab + Format('cPrecision = %d;', [FCoordConverter.Precision]) + cCRLF +
    cCRLF +
    cTab + '{$IFDEF DEBUG}' + cCRLF +
    cTab + Format('cTzInfo: array [0..%d] of PTimeZoneInfo = (%s);', [FTzNameList.Count - 1, VConst]) + cCRLF +
    cTab + '{$ENDIF}' + cCRLF;

  WriteString(
    'unit ' + cTzConstUnitName + ';' + cCRLF +
    cCRLF +
    'interface' + cCRLF +
    cCRLF +
    'uses' + cCRLF + VUses +
    cCRLF +
    'const' + cCRLF + VConst +
    cCRLF +
    FTzTree +
    cCRLF +
    'implementation' + cCRLF +
    cCRLF +
    'end.'
  );

  SaveAndClear(cTzConstUnitName + '.pas');
end;

procedure TTzWriterToPas.WriteTzUnit(const ATimeZone: PTimeZoneRec);

  function IsAscii(const AStr: string): Boolean;
  var
    I: Integer;
    P: PChar;
    VLen: Integer;
  begin
    Result := True;

    VLen := Length(AStr);
    if VLen = 0 then begin
      Exit;
    end;

    P := Pointer(AStr);
    for I := 0 to VLen - 1 do begin
      if Ord(P[I]) > 127 then begin
        Result := False;
        Exit;
      end;
    end;
  end;

var
  VPolygonsCount: Integer;
  VTzName: string;
  VPoints, VBounds, VPolygons, VTzInfo: string;
  VTzBoundsIndex: Integer;
  VTzArraysCount: Integer;
begin
  if not IsAscii(ATimeZone.Name) then begin
    Assert(False);
  end;

  VTzName := EscapeTzName(ATimeZone.Name);
  VPolygonsCount := Length(ATimeZone.FixedPolygon);

  CollectPoints(VTzName, ATimeZone, VPoints, VTzArraysCount);
  CollectBounds(VTzName, ATimeZone, VTzArraysCount, VBounds, VTzBoundsIndex);
  CollectPolygons(VTzName, ATimeZone, VPolygons);

  VTzInfo := TzInfoToString(VTzName, ATimeZone.Name, VTzBoundsIndex, VPolygonsCount);

  WriteString(
    'unit c_' + VTzName + ';' + cCRLF +
    cCRLF +
    'interface' + cCRLF +
    cCRLF +
    'uses' + cCRLF +
    cTab + cTzTypesUnitName + ';' + cCRLF +
    cCRLF +
    'const' + cCRLF +
    VPoints + cCRLF +
    VBounds + cCRLF +
    VPolygons + cCRLF +
    VTzInfo + cCRLF +
    'implementation' + cCRLF +
    cCRLF +
    'end.'
  );

  SaveAndClear('c_' + VTzName + '.pas');
end;

procedure TTzWriterToPas.CollectPoints(
  const ATzName: string;
  const ATimeZone: PTimeZoneRec;
  out APoints: string;
  out ATzArraysCount: Integer
);
var
  I, J: Integer;
  VPoly: PFixedPolygon;
  VList: TStringList;
begin
  ATzArraysCount := 0;

  VList := TStringList.Create;
  try
    for I := 0 to Length(ATimeZone.FixedPolygon) - 1 do begin
      VPoly := @ATimeZone.FixedPolygon[I];

      VList.Add(PointsToString(ATzName, VPoly.Points, ATzArraysCount));
      Inc(ATzArraysCount);

      for J := 0 to Length(VPoly.Holes) - 1 do begin
        VList.Add(PointsToString(ATzName, VPoly.Holes[J].Points, ATzArraysCount));
        Inc(ATzArraysCount);
      end;
    end;

    APoints := VList.Text;
  finally
    VList.Free;
  end;
end;

function TTzWriterToPas.PointsToString(
  const ATzName: string;
  const APoints: TFixedPoints;
  const ATzArrayIndex: Integer
): string;
var
  I: Integer;
  VPoints, VSep: string;
begin
  Assert(Length(APoints) > 0);

  VPoints := '';
  for I := 0 to Length(APoints) - 1 do begin
    if I mod 4 = 0 then begin
      VPoints := VPoints + cCRLF + cTab + cTab;
    end;
    if I = Length(APoints) - 1 then begin
      VSep := cCRLF + cTab;
    end else begin
      VSep := ', ';
    end;
    VPoints := VPoints + Format('(X: %d; Y: %d)', [APoints[I].X, APoints[I].Y]) + VSep;
  end;

  Result := cTab + Format(
    'c%sPoints_%d: array [0..%d] of TTimeZonePoint = (%s);',
    [ATzName, ATzArrayIndex, Length(APoints) - 1, VPoints]
  );
end;

procedure TTzWriterToPas.CollectBounds(
  const ATzName: string;
  const ATimeZone: PTimeZoneRec;
  const ATzArraysCount: Integer;
  out ABounds: string;
  out ATzBoundIndex: Integer
);
var
  I, J, K: Integer;
  VPoly: PFixedPolygon;
  VPolygonsCount: Integer;
  VBoundsArray: TFixedRectArray;
begin
  Assert(ATzArraysCount > 0);

  VPolygonsCount := Length(ATimeZone.FixedPolygon);

  if VPolygonsCount > 1 then begin
    ATzBoundIndex := ATzArraysCount;
    SetLength(VBoundsArray, ATzArraysCount + 1);
    VBoundsArray[ATzBoundIndex] := ATimeZone.FixedBBox;
  end else begin
    ATzBoundIndex := 0;
    SetLength(VBoundsArray, ATzArraysCount);
    // tz bound equals to the polygon bound
  end;

  K := 0;
  for I := 0 to VPolygonsCount - 1 do begin
    Assert(K < ATzArraysCount);

    VPoly := @ATimeZone.FixedPolygon[I];

    VBoundsArray[K] := VPoly.BBox;
    Inc(K);

    for J := 0 to Length(VPoly.Holes) - 1 do begin
      Assert(K < ATzArraysCount);

      VBoundsArray[K] := VPoly.Holes[J].BBox;
      Inc(K);
    end;
  end;
  Assert(K = ATzArraysCount);

  ABounds := BoundsToString(ATzName, VBoundsArray);
end;

function TTzWriterToPas.BoundsToString(
  const ATzName: string;
  const ABounds: TFixedRectArray
): string;
var
  I: Integer;
  VBounds, VSep: string;
begin
  VBounds := cCRLF + cTab;

  for I := 0 to Length(ABounds) - 1 do begin
    if I = Length(ABounds) - 1 then begin
      VSep := '';
    end else begin
      VSep := ',';
    end;
    VBounds := VBounds + cTab +
      Format(
        '(Min: (X: %d; Y: %d); Max: (X: %d; Y: %d))',
        [ABounds[I].Min.X, ABounds[I].Min.Y, ABounds[I].Max.X, ABounds[I].Max.Y]
      ) + VSep + cCRLF + cTab;
  end;

  Result := cTab + Format(
    'c%sBounds: array [0..%d] of TTimeZoneBound = (%s);',
    [ATzName, Length(ABounds) - 1, VBounds]
  ) + cCRLF;
end;

procedure TTzWriterToPas.CollectPolygons(
  const ATzName: string;
  const ATimeZone: PTimeZoneRec;
  out APolygons: string
);
type
  TPointsInfo = record
    PointsCount: Integer;
    PointsArrayIndex: Integer;
  end;
  TPolyInfo = record
    PointsInfo: TPointsInfo;
    HolesCount: Integer;
    FirstHoleIndex: Integer;
  end;
var
  I, J: Integer;
  VPoly: PFixedPolygon;
  VPolygonsCount: Integer;
  VPointsArrayIndex: Integer;
  VPolyInfo: array of TPolyInfo;
  VHolesInfo: array of TPointsInfo;
  VHolesCount: Integer;
  VPolygons, VHoles, VHole, VSep: string;
begin
  VPolygonsCount := Length(ATimeZone.FixedPolygon);

  SetLength(VPolyInfo, VPolygonsCount);
  SetLength(VHolesInfo, 0);

  VHolesCount := 0;
  VPointsArrayIndex := 0;
  for I := 0 to VPolygonsCount - 1 do begin

    VPoly := @ATimeZone.FixedPolygon[I];

    VPolyInfo[I].PointsInfo.PointsCount := Length(VPoly.Points);
    VPolyInfo[I].PointsInfo.PointsArrayIndex := VPointsArrayIndex;
    VPolyInfo[I].HolesCount := Length(VPoly.Holes);
    VPolyInfo[I].FirstHoleIndex := VHolesCount;

    Inc(VPointsArrayIndex);

    SetLength(VHolesInfo, VHolesCount + VPolyInfo[I].HolesCount);
    for J := 0 to VPolyInfo[I].HolesCount - 1 do begin
      VHolesInfo[VHolesCount].PointsCount := Length(VPoly.Holes[J].Points);
      VHolesInfo[VHolesCount].PointsArrayIndex := VPointsArrayIndex;

      Inc(VHolesCount);
      Inc(VPointsArrayIndex);
    end;
  end;

  if VHolesCount > 0 then begin
    VHoles := cCRLF;
    for I := 0 to VHolesCount - 1 do begin
      if I = VHolesCount - 1 then begin
        VSep := cCRLF + cTab;
      end else begin
        VSep := ',' + cCRLF;
      end;
      VHoles := VHoles + cTab + cTab +
        Format(
          '(Bound: @c%sBounds[%d]; PointsCount: %d; FirstPoint: @c%sPoints_%d[0])',
          [ATzName, VHolesInfo[I].PointsArrayIndex,
           VHolesInfo[I].PointsCount, ATzName, VHolesInfo[I].PointsArrayIndex]
        ) + VSep;
    end;
    VHoles := cTab +
      Format(
        'c%sHoles: array[0..%d] of TTimeZoneHole = (%s);',
        [ATzName, VHolesCount - 1, VHoles]
      ) + cCRLF + cCRLF;
  end else begin
    VHoles := '';
  end;

  VPolygons := cCRLF;
  for I := 0 to VPolygonsCount - 1 do begin
    if I = VPolygonsCount - 1 then begin
      VSep := cCRLF + cTab;
    end else begin
      VSep := ',' + cCRLF;
    end;
    if VPolyInfo[I].HolesCount > 0 then begin
      VHole := Format('@c%sHoles[%d]', [ATzName, VPolyInfo[I].FirstHoleIndex]);
    end else begin
      VHole := 'nil';
    end;
    VPolygons := VPolygons + cTab + cTab +
      Format(
        '(Bound: @c%sBounds[%d]; PointsCount: %d; FirstPoint: @c%sPoints_%d[0]; ' +
        'HolesCount: %d; FirstHole: %s)',
        [ATzName, VPolyInfo[I].PointsInfo.PointsArrayIndex,
         VPolyInfo[I].PointsInfo.PointsCount, ATzName, VPolyInfo[I].PointsInfo.PointsArrayIndex,
         VPolyInfo[I].HolesCount, VHole]
      ) + VSep;
  end;
  VPolygons := cTab +
    Format(
      'c%sPolygons: array[0..%d] of TTimeZonePolygon = (%s);',
      [ATzName, VPolygonsCount - 1, VPolygons]
    ) + cCRLF;

  APolygons := VHoles + VPolygons;
end;

function TTzWriterToPas.TzInfoToString(
  const ATzName: string;
  const ATzNameOrigin: string;
  const ABoundsIndex: Integer;
  const APolygonsCount: Integer
): string;
begin
  Result :=
    cTab + 'c' + ATzName + ': TTimeZoneInfo = (' + cCRLF +
    cTab + cTab + Format('TZID: ''%s'';', [ATzNameOrigin]) + cCRLF +
    cTab + cTab + Format('Bound: @c%sBounds[%d];', [ATzName, ABoundsIndex]) + cCRLF +
    cTab + cTab + Format('PolygonsCount: %d;', [APolygonsCount]) + cCRLF +
    cTab + cTab + Format('FirstPolygon: @c%sPolygons[0]', [ATzName]) + cCRLF +
    cTab + ');' + cCRLF;
end;

end.
