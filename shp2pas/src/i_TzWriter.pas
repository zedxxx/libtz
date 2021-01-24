unit i_TzWriter;

interface

uses
  t_TzTypes;

type
  ITzWriter = interface
    ['{41B07312-18B4-4C05-AD81-D2619EA12FA2}']
    procedure OnTzRead(const ATimeZone: PTimeZoneRec);
    procedure OnTzTreeRead(const ATreeRoot: PTreeNode);
  end;

implementation

end.
