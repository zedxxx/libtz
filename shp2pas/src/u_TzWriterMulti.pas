unit u_TzWriterMulti;

interface

uses
  t_TzTypes,
  i_TzWriter,
  i_TzCoordConverter;

type
  TTzWriterType = (tzwKml, tzwPas);
  TTzWriterPath = array [TTzWriterType] of string;

  TTzWriterMulti = class(TInterfacedObject, ITzWriter)
  private
    FWriter: array [TTzWriterType] of ITzWriter;
  private
    { ITzWriter }
    procedure OnTzRead(const ATimeZone: PTimeZoneRec);
    procedure OnTzTreeRead(const ATreeRoot: PTreeNode);
  public
    constructor Create(
      const AOutputPath: TTzWriterPath;
      const ACoordConverter: ITzCoordConverter
    );
  end;

implementation

uses
  u_TzWriterBase,
  u_TzWriterToKml,
  u_TzWriterToPas;

{ TTzWriterMulti }

constructor TTzWriterMulti.Create(
  const AOutputPath: TTzWriterPath;
  const ACoordConverter: ITzCoordConverter
);
const
  CTzWriterClass: array [TTzWriterType] of TTzWriterBaseClass = (
    TTzWriterToKml, TTzWriterToPas
  );
var
  I: TTzWriterType;
  VPath: string;
begin
  inherited Create;
  for I := Low(TTzWriterType) to High(TTzWriterType) do begin
    VPath := AOutputPath[I];
    if VPath <> '' then begin
      FWriter[I] := CTzWriterClass[I].Create(VPath, ACoordConverter);
    end else begin
      FWriter[I] := nil;
    end;
  end;
end;

procedure TTzWriterMulti.OnTzRead(const ATimeZone: PTimeZoneRec);
var
  I: TTzWriterType;
begin
  for I := Low(TTzWriterType) to High(TTzWriterType) do begin
    if FWriter[I] <> nil then begin
      FWriter[I].OnTzRead(ATimeZone);
    end;
  end;
end;

procedure TTzWriterMulti.OnTzTreeRead(const ATreeRoot: PTreeNode);
var
  I: TTzWriterType;
begin
  for I := Low(TTzWriterType) to High(TTzWriterType) do begin
    if FWriter[I] <> nil then begin
      FWriter[I].OnTzTreeRead(ATreeRoot);
    end;
  end;
end;

end.
