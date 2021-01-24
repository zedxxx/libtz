unit t_TzTypes;

interface

type
  // float geometry
  TFloatPoint = record
    X: Double;
    Y: Double;
  end;
  PFloatPoint = ^TFloatPoint;

  TFloatRect = record
    Min: TFloatPoint;
    Max: TFloatPoint;
  end;
  PFloatRect = ^TFloatRect;

  TFloatPoints = array of TFloatPoint;
  PFloatPoints = ^TFloatPoints;

  TFloatHole = record
    BBox: TFloatRect;
    Points: TFloatPoints;
  end;
  PFloatHole = ^TFloatHole;

  TFloatHoles = array of TFloatHole;

  TFloatPolygon = record
    BBox: TFloatRect;
    Points: TFloatPoints;
    Holes: TFloatHoles;
  end;
  PFloatPolygon = ^TFloatPolygon;

  // fixed geometry
  TFixedPoint = record
    X: Integer;
    Y: Integer;
    class operator Equal(const A, B: TFixedPoint): Boolean; inline;
    class operator NotEqual(const A, B: TFixedPoint): Boolean; inline;
  end;
  PFixedPoint = ^TFixedPoint;

  TFixedRect = record
    Min: TFixedPoint;
    Max: TFixedPoint;
  end;
  PFixedRect = ^TFixedRect;
  TFixedRectArray = array of TFixedRect;

  TFixedPoints = array of TFixedPoint;
  PFixedPoints = ^TFixedPoints;

  TFixedHole = record
    BBox: TFixedRect;
    Points: TFixedPoints;
  end;
  PFixedHole = ^TFixedHole;

  TFixedHoles = array of TFixedHole;

  TFixedPolygon = record
    BBox: TFixedRect;
    Points: TFixedPoints;
    Holes: TFixedHoles;
  end;
  PFixedPolygon = ^TFixedPolygon;

  // time zone
  TTimeZoneRec = record
    Id: Integer;
    Name: string;

    BBox: TFloatRect;
    Polygon: array of TFloatPolygon;

    FixedBBox: TFixedRect;
    FixedPolygon: array of TFixedPolygon;

    procedure UpdateBbox; inline;
    procedure UpdateFixedBbox; inline;
  end;
  PTimeZoneRec = ^TTimeZoneRec;

  PTreeNode = ^TTreeNode;
  TTreeNode = record
    NodeId: Integer;
    Bounds: TFixedRect;
    ShapeIds: array of Integer;
    SubNodes: array of PTreeNode;
  end;

procedure ResetBboxFloat(var ABbox: TFloatRect); inline;
procedure UpdateBboxFloat(var ABbox: TFloatRect; const APoint: PFloatPoint); inline;

procedure ResetBboxFixed(var ABbox: TFixedRect); inline;
procedure UpdateBboxFixed(var ABbox: TFixedRect; const APoint: PFixedPoint); inline;

implementation

procedure ResetBboxFloat(var ABbox: TFloatRect);
begin
  ABbox.Min.X := 180;
  ABbox.Min.Y := 90;
  ABbox.Max.X := -180;
  ABbox.Max.Y := -90;
end;

procedure UpdateBboxFloat(var ABbox: TFloatRect; const APoint: PFloatPoint);
begin
  if ABbox.Min.X > APoint.X then ABbox.Min.X := APoint.X;
  if ABbox.Min.Y > APoint.Y then ABbox.Min.Y := APoint.Y;
  if ABbox.Max.X < APoint.X then ABbox.Max.X := APoint.X;
  if ABbox.Max.Y < APoint.Y then ABbox.Max.Y := APoint.Y;
end;

procedure ResetBboxFixed(var ABbox: TFixedRect);
begin
  ABbox.Min.X := MaxInt;
  ABbox.Min.Y := MaxInt;
  ABbox.Max.X := -MaxInt;
  ABbox.Max.Y := -MaxInt;
end;

procedure UpdateBboxFixed(var ABbox: TFixedRect; const APoint: PFixedPoint);
begin
  if ABbox.Min.X > APoint.X then ABbox.Min.X := APoint.X;
  if ABbox.Min.Y > APoint.Y then ABbox.Min.Y := APoint.Y;
  if ABbox.Max.X < APoint.X then ABbox.Max.X := APoint.X;
  if ABbox.Max.Y < APoint.Y then ABbox.Max.Y := APoint.Y;
end;

{ TFixedPoint }

class operator TFixedPoint.Equal(const A, B: TFixedPoint): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y);
end;

class operator TFixedPoint.NotEqual(const A, B: TFixedPoint): Boolean;
begin
  Result := (A.X <> B.X) or (A.Y <> B.Y);
end;

{ TTimeZoneRec }

procedure TTimeZoneRec.UpdateFixedBbox;
var
  I: Integer;
begin
  ResetBboxFixed(FixedBBox);
  for I := 0 to Length(FixedPolygon) - 1 do begin
    if Length(FixedPolygon[I].Points) > 0 then begin
      UpdateBboxFixed(FixedBBox, @FixedPolygon[I].BBox.Min);
      UpdateBboxFixed(FixedBBox, @FixedPolygon[I].BBox.Max);
    end;
  end;
end;

procedure TTimeZoneRec.UpdateBbox;
var
  I: Integer;
begin
  ResetBboxFloat(BBox);
  for I := 0 to Length(Polygon) - 1 do begin
    if Length(Polygon[I].Points) > 0 then begin
      UpdateBboxFloat(BBox, @Polygon[I].BBox.Min);
      UpdateBboxFloat(BBox, @Polygon[I].BBox.Max);
    end;
  end;
end;

end.
