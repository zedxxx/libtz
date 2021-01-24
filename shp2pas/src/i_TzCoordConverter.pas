unit i_TzCoordConverter;

interface

uses
  t_TzTypes;

type
  ITzCoordConverter = interface
  ['{4C6625CB-8C21-41E7-B1E3-80544616551D}']
    function FloatToFixed(const X, Y: Double): TFixedPoint; overload;
    function FloatToFixed(const APoint: TFloatPoint): TFixedPoint; overload;

    function FixedToFloat(const APoint: TFixedPoint): TFloatPoint;

    function GetPrecision: Integer;
    property Precision: Integer read GetPrecision;
  end;

implementation

end.

