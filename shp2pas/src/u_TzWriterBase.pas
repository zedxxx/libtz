unit u_TzWriterBase;

interface

uses
  Classes,
  t_TzTypes,
  i_TzWriter,
  i_TzCoordConverter;

type
  TTzWriterBase = class(TInterfacedObject, ITzWriter)
  private
    FStream: TMemoryStream;
    class function GetPreparedOutputPath(const AOutputPath: string): string;
  protected
    FOutputPath: string;
    FCoordConverter: ITzCoordConverter;
    procedure WriteString(const AStr: string);
    procedure SaveAndClear(const AFileName: string);
    class function EscapeTzName(const AName: string): string;
  protected
    { ITzWriter }
    procedure OnTzRead(const ATimeZone: PTimeZoneRec); virtual; abstract;
    procedure OnTzTreeRead(const ATreeRoot: PTreeNode); virtual;
  public
    constructor Create(
      const AOutputPath: string;
      const ACoordConverter: ITzCoordConverter
    ); virtual;
    destructor Destroy; override;
  end;

  TTzWriterBaseClass = class of TTzWriterBase;

implementation

uses
  SysUtils,
  {$IFDEF FPC}
  FileUtil;
  {$ELSE}
  IOUtils;
  {$ENDIF}

{ TTzWriterBase }

constructor TTzWriterBase.Create(
  const AOutputPath: string;
  const ACoordConverter: ITzCoordConverter
);
begin
  Assert(AOutputPath <> '');
  Assert(ACoordConverter <> nil);

  inherited Create;

  FOutputPath := GetPreparedOutputPath(AOutputPath);
  FCoordConverter := ACoordConverter;

  FStream := TMemoryStream.Create;
end;

destructor TTzWriterBase.Destroy;
begin
  FStream.Free;
  FCoordConverter := nil;
  inherited Destroy;
end;

procedure TTzWriterBase.OnTzTreeRead(const ATreeRoot: PTreeNode);
begin
  // do nothing
end;

class function TTzWriterBase.EscapeTzName(const AName: string): string;
begin
  Result := StringReplace(AName, '/', '', [rfReplaceAll]);
  Result := StringReplace(Result, '-', '_m_', [rfReplaceAll]);
  Result := StringReplace(Result, '+', '_p_', [rfReplaceAll]);
end;

procedure TTzWriterBase.WriteString(const AStr: string);
var
  VStr: UTF8String;
begin
  if AStr <> '' then begin
    VStr := UTF8Encode(AStr);
    FStream.WriteBuffer(VStr[1], Length(VStr));
  end;
end;

procedure TTzWriterBase.SaveAndClear(const AFileName: string);
begin
  FStream.SaveToFile(FOutputPath + AFileName);
  FStream.Clear;
end;

class function TTzWriterBase.GetPreparedOutputPath(const AOutputPath: string): string;
begin
  Result := Trim(AOutputPath);
  if Result = '' then begin
    raise Exception.Create('Output Path can''t be empty!');
  end;

  Result := IncludeTrailingPathDelimiter(Result);

  if DirectoryExists(Result) then begin
    {$IFDEF FPC}
    if not FileUtil.DeleteDirectory(Result, True) then begin
      RaiseLastOSError;
    end;
    {$ELSE}
    IOUtils.TDirectory.Delete(Result, True);
    if not ForceDirectories(Result) then begin
      RaiseLastOSError;
    end;
    {$ENDIF}
  end else
  if not ForceDirectories(Result) then begin
    RaiseLastOSError;
  end;
end;

end.
