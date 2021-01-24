unit u_TzCoordConverter;

interface

uses
  SysUtils,
  t_TzTypes,
  i_TzCoordConverter;

type
  TTzCoordConverter = class(TInterfacedObject, ITzCoordConverter)
  private
    const CLonScale = 180;
    const CLatScale = 90;
    const CMinPrecision = 8;
    const CMaxPrecision = 32;
  private
    FPrecision: Integer;
    function ToFixed(const AValue: Double; const AScale: Integer): Integer; inline;
    function ToFloat(const AValue: Integer; const AScale: Integer): Double; inline;
  private
    { ITzCoordConverter }
    function FloatToFixed(const X, Y: Double): TFixedPoint; overload; inline;
    function FloatToFixed(const APoint: TFloatPoint): TFixedPoint; overload; inline;
    function FixedToFloat(const APoint: TFixedPoint): TFloatPoint; inline;
    function GetPrecision: Integer;
  public
    constructor Create(const APrecision: Integer);
  end;

  ETzCoordConverter = class(Exception);

implementation

{ TTzCoordConverter }

constructor TTzCoordConverter.Create(const APrecision: Integer);
begin
  inherited Create;
  FPrecision := APrecision;

  if (FPrecision < CMinPrecision) or (FPrecision > CMaxPrecision) then begin
    raise ETzCoordConverter.CreateFmt(
      'Precision is out of range [%d..%d]: %d',
      [CMinPrecision, CMaxPrecision, FPrecision]
    );
  end;
end;

function TTzCoordConverter.ToFixed(const AValue: Double; const AScale: Integer): Integer;
begin
  Result := Trunc( (1 shl (FPrecision - 1) - 1) * AValue / AScale );
end;

function TTzCoordConverter.ToFloat(const AValue: Integer; const AScale: Integer): Double;
begin
  Result := Int64(AValue) * AScale / (1 shl (FPrecision - 1) - 1);
end;

function TTzCoordConverter.FixedToFloat(const APoint: TFixedPoint): TFloatPoint;
begin
  Result.X := ToFloat(APoint.X, CLonScale);
  Result.Y := ToFloat(APoint.Y, CLatScale);
end;

function TTzCoordConverter.FloatToFixed(const X, Y: Double): TFixedPoint;
begin
  Result.X := ToFixed(X, CLonScale);
  Result.Y := ToFixed(Y, CLatScale);
end;

function TTzCoordConverter.FloatToFixed(const APoint: TFloatPoint): TFixedPoint;
begin
  Result := FloatToFixed(APoint.X, APoint.Y);
end;

function TTzCoordConverter.GetPrecision: Integer;
begin
  Result := FPrecision;
end;

end.
