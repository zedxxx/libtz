unit u_TzReaderFromShp;

interface

uses
  libshp,
  t_TzTypes,
  i_TzReader,
  i_TzWriter,
  i_TzCoordConverter;

type
  TTzReaderFromShp = class(TInterfacedObject, ITzReader)
  private
    FTz: TTimeZoneRec;
    FFileName: string;
    FFileNameUTF8: UTF8String;
    FTzWriter: ITzWriter;
    FCoordConverter: ITzCoordConverter;
    FShapeObjectsProcessed: Integer;
    FTzName: array of string;
    FSAHooks: PSAHooks;
  private
    procedure ReadMetaData;
    procedure ReadShapeObjects;
    procedure TransformFloatToFixed;
    procedure PointsFloatToFixed(
      const APointsFloat: TFloatPoints;
      var APoints: TFixedPoints;
      var ABBox: TFixedRect
    );
    procedure MakeSpatialIndex;
  public
    { ITzReader }
    function Run: Integer;
  public
    constructor Create(
      const AShapeFileName: string;
      const ACoordConverter: ITzCoordConverter;
      const ATzWriter: ITzWriter
    );
  end;

implementation

uses
  SysUtils;

{ TTzReaderFromShp }

constructor TTzReaderFromShp.Create(
  const AShapeFileName: string;
  const ACoordConverter: ITzCoordConverter;
  const ATzWriter: ITzWriter
);
begin
  Assert(ATzWriter <> nil);

  if not FileExists(AShapeFileName) then begin
    raise Exception.Create('Shape file does not exists: ' + AShapeFileName);
  end;

  inherited Create;

  FFileName := AShapeFileName;
  FFileNameUTF8 := UTF8Encode(FFileName);

  FCoordConverter := ACoordConverter;
  FTzWriter := ATzWriter;
end;

function TTzReaderFromShp.Run: Integer;
begin
  FShapeObjectsProcessed := 0;

  New(FSAHooks);
  try
    SASetupUtf8Hooks(FSAHooks);
    ReadMetaData;
    ReadShapeObjects;
    MakeSpatialIndex;
  finally
    Dispose(FSAHooks);
  end;

  Result := FShapeObjectsProcessed;
end;

procedure TTzReaderFromShp.ReadMetaData;
var
  I, J: Integer;
  VCount: Integer;
  VHandle: DBFHandle;
  VType: DBFFieldType;
  VTitle: array [0..11] of AnsiChar;
  VWidth, VDecimals: Integer;
  VName: string;
begin
  VHandle := DBFOpenLL(PAnsiChar(FFileNameUTF8), 'rb', FSAHooks);
  if VHandle = nil then begin
    raise Exception.Create('DBFOpenLL failed: ' + FFileName);
  end;
  try
    VCount := DBFGetRecordCount(VHandle);
    SetLength(FTzName, VCount);
    for I := 0 to VCount - 1 do begin
      for J := 0 to DBFGetFieldCount(VHandle) - 1 do begin
        VType := DBFGetFieldInfo(VHandle, J, @VTitle[0], @VWidth, @VDecimals);
        if VType = ftString then begin
          VTitle[11] := #0;
          VName := string(VTitle);
          if LowerCase(VName) = 'tzid' then begin
            FTzName[I] := string(DBFReadStringAttribute(VHandle, I, J));
            Break;
          end;
        end;
      end;
    end;
  finally
    DBFClose(VHandle);
  end;
end;

function _IsHole(const APoints: PFloatPoints): Boolean;
var
  I, J, K: Integer;
  VArea: Double;
begin
  K := Length(APoints^);

  if K < 3 then begin
    raise Exception.Create('Polygon must have at least 3 points!');
  end;

  VArea := 0;
  J := K - 1;
  for I := 0 to K - 1 do begin
    VArea := VArea +
      (APoints^[J].X + APoints^[I].X) * (APoints^[J].Y - APoints^[I].Y);
    J := I;
  end;
  VArea := -VArea * 0.5;

  Result := VArea >= 0;
end;

procedure TTzReaderFromShp.ReadShapeObjects;
type
  TTzPolygon = record
    BBox: TFloatRect;
    Points: TFloatPoints;
  end;
  PTzPolygon = ^TTzPolygon;
var
  I, J, K, H: Integer;
  VHandle: SHPHandle;
  VShapeObject: PShpObject;
  VEntitiesCount: Integer;
  VShapeType: Integer;
  VPartIndex: Integer;
  VPoints: PFloatPoints;
  VPolygon: PTzPolygon;
  VPolygons: array of TTzPolygon;
begin
  VHandle := SHPOpenLL(PAnsiChar(FFileNameUTF8), 'rb', FSAHooks);
  if VHandle = nil then begin
    raise Exception.Create('SHPOpenLL failed: ' + FFileName);
  end;
  try
    ShpGetInfo(VHandle, @VEntitiesCount, @VShapeType, nil, nil);

    for I := 0 to VEntitiesCount - 1 do begin
      VShapeObject := SHPReadObject(VHandle, I);
      if VShapeObject = nil then begin
        Continue;
      end;
      try
        if not VShapeObject.nSHPType in [3, 5, 13, 15] then begin
          Continue;
        end;

        FTz.Id := VShapeObject.nShapeId;

        if FTz.Id >= Length(FTzName) then begin
          Assert(False);
          Continue;
        end;
        FTz.Name := FTzName[FTz.Id];

        SetLength(VPolygons, VShapeObject.nParts);

        K := VShapeObject.nVertices;
        for J := VShapeObject.nParts - 1 downto 0 do begin
          SetLength(VPolygons[J].Points, K - VShapeObject.panPartStart[J]);
          K := VShapeObject.panPartStart[J];
        end;

        K := 0;
        VPolygon := nil;
        VPoints := nil;
        VPartIndex := 0;

        for J := 0 to VShapeObject.nVertices - 1 do begin
          if
            (VPartIndex < VShapeObject.nParts) and
            (J = VShapeObject.panPartStart[VPartIndex])
          then begin
            Inc(VPartIndex);

            VPolygon := @VPolygons[VPartIndex - 1];
            ResetBboxFloat(VPolygon.BBox);

            VPoints := @VPolygon.Points;

            K := 0;
          end;

          Assert(VPolygon <> nil);
          Assert(VPoints <> nil);
          Assert(K < Length(VPoints^));

          VPoints^[K].X := VShapeObject.padfX[J];
          VPoints^[K].Y := VShapeObject.padfY[J];

          UpdateBboxFloat(VPolygon.BBox, @VPoints^[K]);

          Inc(K);
        end;

        K := 0;
        SetLength(FTz.Polygon, Length(VPolygons));
        for J := 0 to Length(VPolygons) - 1 do begin
          VPolygon := @VPolygons[J];
          if not _IsHole(@VPolygon.Points) then begin
            with FTz.Polygon[K] do begin
              BBox   := VPolygon.BBox;
              Points := VPolygon.Points;
              Holes  := nil;
            end;
            Inc(K);
          end else begin
            if K = 0 then begin
              // There is no parent polygon for the current hole
              Assert(False, 'Found a hole before polygon!');
              Continue; // skip this hole
            end;
            H := Length(FTz.Polygon[K-1].Holes);
            SetLength(FTz.Polygon[K-1].Holes, H+1);
            with FTz.Polygon[K-1].Holes[H] do begin
              BBox := VPolygon.BBox;
              Points := VPolygon.Points;
            end;
          end;
        end;
        SetLength(FTz.Polygon, K);

        FTz.UpdateBbox;
        TransformFloatToFixed;

        FTzWriter.OnTzRead(@FTz);
        Inc(FShapeObjectsProcessed);
      finally
        SHPDestroyObject(VShapeObject);
      end;
    end;
  finally
    SHPClose(VHandle);
  end;
end;

procedure TTzReaderFromShp.PointsFloatToFixed(
  const APointsFloat: TFloatPoints;
  var APoints: TFixedPoints;
  var ABBox: TFixedRect
);
var
  I, J: Integer;
begin
  ResetBboxFixed(ABBox);

  J := 0;
  SetLength(APoints, Length(APointsFloat));

  for I := 0 to Length(APointsFloat) - 1 do begin
    // losses conversion: float -> fixed
    APoints[J] := FCoordConverter.FloatToFixed(APointsFloat[I]);

    if (J = 0) or (APoints[J] <> APoints[J-1]) then begin
      UpdateBboxFixed(ABBox, @APoints[J]);
      Inc(J);
    end;
  end;

  if J >= 3 then begin
    // first and last points must be equal
    if APoints[0] <> APoints[J-1] then begin
      SetLength(APoints, J+1);
      APoints[J] := APoints[0];
    end else begin
      SetLength(APoints, J);
    end;
  end else begin
    SetLength(APoints, 0);
  end;
end;

procedure TTzReaderFromShp.TransformFloatToFixed;
var
  I, J, K, H: Integer;
begin
  J := 0;
  SetLength(FTz.FixedPolygon, Length(FTz.Polygon));

  for I := 0 to Length(FTz.Polygon) - 1 do begin

    PointsFloatToFixed(
      FTz.Polygon[I].Points,
      FTz.FixedPolygon[J].Points,
      FTz.FixedPolygon[J].BBox
    );

    if Length(FTz.FixedPolygon[J].Points) = 0 then begin
      // polygon collapsed
      Continue;
    end;

    K := 0;
    SetLength(FTz.FixedPolygon[J].Holes, Length(FTz.Polygon[I].Holes));

    for H := 0 to Length(FTz.Polygon[I].Holes) - 1 do begin
      PointsFloatToFixed(
        FTz.Polygon[I].Holes[H].Points,
        FTz.FixedPolygon[J].Holes[K].Points,
        FTz.FixedPolygon[J].Holes[K].BBox
      );
      if Length(FTz.FixedPolygon[J].Holes[K].Points) = 0 then begin
        // hole collapsed
        Continue;
      end;
      Inc(K);
    end;
    SetLength(FTz.FixedPolygon[J].Holes, K);

    Inc(J);
  end;
  SetLength(FTz.FixedPolygon, J);

  FTz.UpdateFixedBbox;
end;


procedure TTzReaderFromShp.MakeSpatialIndex;

  procedure AddSubNode(
    var ANodeId: Integer;
    const ANode: PSHPTreeNode;
    const ANodeInternal: PTreeNode
  );
  var
    I: Integer;
    VShapeId: PLongInt;
  begin
    if ANode = nil then begin
      Exit;
    end;

    ANodeInternal.NodeId := ANodeId;
    Inc(ANodeId);

    // copy bounds (losses conversion)
    ANodeInternal.Bounds.Min := FCoordConverter.FloatToFixed(ANode.adfBoundsMin[0], ANode.adfBoundsMin[1]);
    ANodeInternal.Bounds.Max := FCoordConverter.FloatToFixed(ANode.adfBoundsMax[0], ANode.adfBoundsMax[1]);

    // copy node shape IDs
    VShapeId := ANode.panShapeIds;
    SetLength(ANodeInternal.ShapeIds, ANode.nShapeCount);
    for I := 0 to ANode.nShapeCount - 1 do begin
      ANodeInternal.ShapeIds[I] := VShapeId^;
      Inc(VShapeId);
    end;

    // add subnodes recursively
    if ANode.nSubNodes > MAX_SUBNODE then begin
      raise Exception.CreateFmt('Unexpected SubNodes Count = %d', [ANode.nSubNodes]);
    end;
    SetLength(ANodeInternal.SubNodes, ANode.nSubNodes);
    for I := 0 to ANode.nSubNodes - 1 do begin
      New(ANodeInternal.SubNodes[I]);
      AddSubNode(ANodeId, ANode.apsSubNode[I], ANodeInternal.SubNodes[I]);
    end;
  end;

  procedure DisposeSubNodes(const ANodeInternal: PTreeNode);
  var
    I: Integer;
  begin
    for I := 0 to Length(ANodeInternal.SubNodes) - 1 do begin
      DisposeSubNodes(ANodeInternal.SubNodes[I]);
      Dispose(ANodeInternal.SubNodes[I]);
      ANodeInternal.SubNodes[I] := nil;
    end;
  end;

  {$IFDEF DEBUG}
  procedure DumpNode(const ANode: PTreeNode);
  var
    I: Integer;
    VIds: string;
  begin
    VIds := '';
    for I := 0 to Length(ANode.ShapeIds) - 1 do begin
       if VIds <> '' then begin
         VIds := VIds + ', ';
       end;
       VIds := VIds + IntToStr(ANode.ShapeIds[I]);
    end;
    Writeln(ANode.NodeId, ': ', VIds);

    for I := 0 to Length(ANode.SubNodes) - 1 do begin
      DumpNode(ANode.SubNodes[I]);
    end;
  end;
  {$ENDIF}

var
  VNodeId: Integer;
  VHandle: SHPHandle;
  VTree: PSHPTree;
  VTreeInternal: TTreeNode;
begin
  VHandle := SHPOpenLL(PAnsiChar(FFileNameUTF8), 'rb', FSAHooks);
  if VHandle = nil then begin
    raise Exception.Create('SHPOpenLL failed: ' + FFileName);
  end;
  try
    VTree := SHPCreateTree(VHandle, 2, 0, nil, nil);
    if VTree = nil then begin
      raise Exception.Create('SHPCreateTree failed: ' + FFileName);
    end;
    try
      SHPTreeTrimExtraNodes(VTree);
      try
        VNodeId := 0;
        AddSubNode(VNodeId, VTree.psRoot, @VTreeInternal);
        FTzWriter.OnTzTreeRead(@VTreeInternal);
        {$IFDEF DEBUG}
        Writeln('MaxDepth: ', VTree.nMaxDepth);
        Writeln('Dimension: ', VTree.nDimension);
        Writeln('TotalCount: ', VTree.nTotalCount);
        Writeln('Nodes:');
        DumpNode(@VTreeInternal);
        {$ENDIF}
      finally
        DisposeSubNodes(@VTreeInternal)
      end;
    finally
      SHPDestroyTree(VTree);
    end;
  finally
    SHPClose(VHandle);
  end;
end;

end.
