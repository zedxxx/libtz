// --------------------------------------------------------------------------
// Object Pascal Wrapper for Shapefile C Library
//
//    This unit is based on the work of
//      Keven Meyer (kevin@cybertracker.co.za), 2002, MIT/LGPL lic
//      Alexander Weidauer (alex.weidauer@huckfinn.de), 2003, MIT/LGPL lic
//      Javier Santo Domingo (j-a-s-d@coderesearchlabs.com), 2006-2011, MIT lic
// --------------------------------------------------------------------------

unit libshp;

interface

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIf}

{$OVERFLOWCHECKS OFF}
{$MINENUMSIZE 4}

const
  libshp_dll = 'libshp.dll';

type
  PDouble = ^Double;
  PLongInt = ^LongInt;
  PLongIntArray = ^TLongIntArray;
  TLongIntArray = array of LongInt;
  PDoubleArray = ^TDoubleArray;
  TDoubleArray = array of Double;
  T3DArray = array [0..3] of Double;

  SAFile = PInteger;
  SAOffset = Cardinal;

  SAHooks = record
    FOpen: function(const filename: PAnsiChar; const access: PAnsiChar): SAFile; cdecl;
    FRead: function(p: pointer; size: SAOffset; nmemb: SAOffset; f: SAFile): SAOffset; cdecl;
    FWrite: function(p: pointer; size: SAOffset; nmemb: SAOffset; f: SAFile): SAOffset; cdecl;
    FSeek: function(f: SAFile; offset: SAOffset; whence: integer): SAOffset; cdecl;
    FTell: function(f: SAFile): SAOffset; cdecl;

    FFlush: function(f: SAFile): integer; cdecl;
    FClose: function(f: SAFile): integer; cdecl;
    FRemove: function(const filename: PAnsiChar): integer; cdecl;

    Error: procedure(const msg: PAnsiChar); cdecl;
    Atof: function(const str: PAnsiChar): Double; cdecl;
  end;
  PSAHooks = ^SAHooks;

  PPShpObject = ^PShpObject;
  PShpObject = ^ShpObject;

  PSHPInfo = ^SHPInfo;
  SHPInfo = record
    sHooks: SAHooks;

    fpSHP: SAFile;
    fpSHX: SAFile;
    nShapeType: LongInt;
    nFileSize: Cardinal;
    nRecords: LongInt;
    nMaxRecords: LongInt;
    panRecOffset: PCardinal;
    panRecSize: PCardinal;
    adBoundsMin: T3DArray;
    adBoundsMax: T3DArray;
    bUpdated: LongInt;

    pabyRec: PByte;
    nBufSize: Integer;
    bFastModeReadObject: Integer;
    pabyObjectBuf: PByte;
    nObjectBufSize: Integer;
    psCachedObject: PShpObject;
  end;

  SHPHandle = PSHPInfo;

  // SHPObject - represents on shape (without attributes) read from the .shp file.
  ShpObject = record
    nSHPType: Integer;
    nShapeId: Integer; // -1 is unknown/unassigned
    nParts: Integer;

    panPartStart: TLongIntArray;
    panPartType: TLongIntArray;

    nVertices: Integer;

    padfX: TDoubleArray;
    padfY: TDoubleArray;
    padfZ: TDoubleArray;
    padfM: TDoubleArray;

    dfXMin: Double;
    dfYMin: Double;
    dfZMin: Double;
    dfMMin: Double;

    dfXMax: Double;
    dfYMax: Double;
    dfZMax: Double;
    dfMMax: Double;

    bMeasureIsUsed: Integer;
    bFastModeReadObject: Integer;
  end;

const
  // Shape Types (nSHPType)
  SHPT_NULL         = 0;
  // 2D Shape Types
  SHPT_POINT        = 1; // Points
  SHPT_ARC          = 3; // Arcs (Polylines, possible in parts)
  SHPT_POLYGON      = 5; // Polygons (possible in parts)
  SHPT_MULTIPOINT   = 8; // MultiPoint (related points)
  // 3D Shape Types (may include "measure" values for vertices)
  SHPT_POINTZ       = 11;
  SHPT_ARCZ         = 13;
  SHPT_POLYGONZ     = 15;
  SHPT_MULTIPOINTZ  = 18;
  // 2D + Measure Types
  SHPT_POINTM       = 21;
  SHPT_ARCM         = 23;
  SHPT_POLYGONM     = 25;
  SHPT_MULTIPOINTM  = 28;
  // Complex with Z, and Measure
  SHPT_MULTIPATCH   = 31;

  // Part types - everything but SHPT_MULTIPATCH just uses SHPP_RING.
  SHPP_TRISTRIP     = 0;
  SHPP_TRIFAN       = 1;
  SHPP_OUTERRING    = 2;
  SHPP_INNERRING    = 3;
  SHPP_FIRSTRING    = 4;
  SHPP_RING         = 5;

procedure SASetupUtf8Hooks(psHooks: PSAHooks); cdecl; external libshp_dll;

// SHP API Prototypes
function SHPOpen(const pszShapeFile: PAnsiChar; const pszAccess: PAnsiChar): SHPHandle; cdecl; external libshp_dll;
function SHPOpenLL(const pszShapeFile: PAnsiChar; const pszAccess: PAnsiChar; psHooks: PSAHooks): SHPHandle; cdecl; external libshp_dll;
function SHPCreate(pszShapeFile: PAnsiChar; nShapeType: LongInt): SHPHandle; cdecl; external libshp_dll;
procedure SHPGetInfo(hSHP: SHPHandle; pnEntities: PLongInt; pnShapeType: PLongInt; padfMinBound: PDouble; padfMaxBound: PDouble); cdecl; external libshp_dll;
function SHPReadObject(hSHP: SHPHandle; iShape: LongInt): PShpObject; cdecl; external libshp_dll;
function SHPWriteObject(hSHP: SHPHandle; iShape: LongInt; psObject: PShpObject): LongInt; cdecl; external libshp_dll;
procedure SHPDestroyObject(psObject: PShpObject); cdecl; external libshp_dll;
procedure SHPComputeExtents(psObject: PShpObject); cdecl; external libshp_dll;

// SHP Create Object
function SHPCreateObject(nSHPType: LongInt; nShapeId: LongInt; nParts: LongInt;
  panPartStart: PLongInt; panPartType: PLongInt; nVertices: LongInt;
  padfX: PDouble; padfY: PDouble; padfZ: PDouble; padfM: PDouble): PShpObject; cdecl; external libshp_dll;

// SHP Create Simple Object
function SHPCreateSimpleObject(nSHPType: LongInt; nVertices: LongInt; padfX:
  PDouble; padfY: PDouble; padfZ: PDouble): PShpObject; cdecl; external libshp_dll;

// Close a Shapefile by a given handle
procedure SHPClose(hSHP: SHPHandle); cdecl; external libshp_dll;

// Get back the shape type sting
function SHPTypeName(nSHPType: LongInt): PAnsiChar; cdecl; external libshp_dll;

// Get back the part type sting
function SHPPartTypeName(nPartType: LongInt): PAnsiChar; cdecl; external libshp_dll;

// Write out a header for the .shp and .shx files as well as the contents of the index (.shx) file
procedure SHPWriteHeader(hSHP: SHPHandle); cdecl; external libshp_dll;

// Reset the winding of polygon objects to adhere to the specification
function SHPRewindObject(hSHP: SHPHandle; psObject: PShpObject): LongInt; cdecl; external libshp_dll;

// Shape quadtree indexing API.
// .. this can be two or four for binary or quad tree
const
  MAX_SUBNODE = 4;

// region covered by this node list of shapes stored at this node.
// The papsShapeObj pointers or the whole list can be NULL
type
  PSHPTreeNode = ^SHPTreeNode;
  SHPTreeNode = record
    adfBoundsMin: T3DArray;
    adfBoundsMax: T3DArray;
    nShapeCount: LongInt;
    panShapeIds: PLongInt;
    papsShapeObj: PPShpObject;
    nSubNodes: LongInt;
    apsSubNode: array [0..MAX_SUBNODE-1] of PSHPTreeNode;
  end;

  PSHPTree = ^SHpTree;
  SHPTree = record
    hSHP: SHPHandle;
    nMaxDepth: LongInt;
    nDimension: LongInt;
    nTotalCount: LongInt;
    psRoot: PSHPTreeNode;
  end;

function SHPCreateTree(hSHP: SHPHandle; nDimension: LongInt; nMaxDepth: LongInt; padfBoundsMin: PDouble; padfBoundsMax: PDouble): PSHPTree; cdecl; external libshp_dll;
procedure SHPDestroyTree(hTree: PSHPTree); cdecl; external libshp_dll;
function SHPWriteTree(hTree: PSHPTree; pszFilename: PAnsiChar): LongInt; cdecl; external libshp_dll;
function SHPReadTree(pszFilename: PAnsiChar): SHpTree; cdecl; external libshp_dll;
function SHPTreeAddObject(hTree: PSHPTree; psObject: PShpObject): LongInt; cdecl; external libshp_dll;
function SHPTreeAddShapeId(hTree: PSHPTree; psObject: PShpObject): LongInt; cdecl; external libshp_dll;
function SHPTreeRemoveShapeId(hTree: PSHPTree; nShapeId: LongInt): LongInt; cdecl; external libshp_dll;
procedure SHPTreeTrimExtraNodes(hTree: PSHPTree); cdecl; external libshp_dll;
function SHPTreeFindLikelyShapes(hTree: PSHPTree; padfBoundsMin: PDouble; padfBoundsMax: PDouble; _para4: PLongInt): PLongInt; cdecl; external libshp_dll;
function SHPCheckBoundsOverlap(_para1: PDouble; _para2: PDouble; _para3: PDouble; _para4: PDouble; _para5: LongInt): LongInt; cdecl; external libshp_dll;

// DBF Support
type
  PDBFInfo = ^DBFInfo;
  DBFInfo = record
    sHooks: SAHooks;

    fp: SAFile;

    nRecords: LongInt;
    nRecordLength: LongInt;

    nHeaderLength: LongInt;

    nFields: LongInt;
    panFieldOffset: PLongInt;
    panFieldSize: PLongInt;
    panFieldDecimals: PLongInt;
    pachFieldType: PAnsiChar;

    pszHeader: PAnsiChar;

    nCurrentRecord: LongInt;
    bCurrentRecordModified: LongInt;
    pszCurrentRecord: PAnsiChar;

    nWorkFieldLength: Integer;
    pszWorkField: PAnsiChar;

    bNoHeader: LongInt;
    bUpdated: LongInt;

    // ...
  end;

  DBFHandle = PDBFInfo;

  DBFFieldType = (
    ftString,
    ftInteger,
    ftDouble,
    ftLogical,
    ftDate,
    ftInvalid
  );

const
  XBASE_FLDHDR_SZ = 32;
  XBASE_FLDNAME_LEN_READ = 11;
  XBASE_FLDNAME_LEN_WRITE = 10;

function DBFOpen(pszDBFFile: PAnsiChar; pszAccess: PAnsiChar): DBFHandle; cdecl; external libshp_dll;
function DBFOpenLL(const pszDBFFile: PAnsiChar; const pszAccess: PAnsiChar; pHooks: PSAHooks): DBFHandle; cdecl; external libshp_dll;
function DBFCreate(pszDBFFile: PAnsiChar): DBFHandle; cdecl; external libshp_dll;
function DBFCreateEx(pszDBFFile: PAnsiChar; pszCodePage: PAnsiChar): DBFHandle; cdecl; external libshp_dll;
function DBFGetFieldCount(psDBF: DBFHandle): LongInt; cdecl; external libshp_dll;
function DBFGetRecordCount(psDBF: DBFHandle): LongInt; cdecl; external libshp_dll;
function DBFAddField(hDBF: DBFHandle; pszFieldName: PAnsiChar; eType:DBFFieldType;
  nWidth: LongInt; nDecimals: LongInt): LongInt; cdecl; external libshp_dll;
function DBFGetFieldInfo(psDBF: DBFHandle; iField: LongInt; pszFieldName: PAnsiChar;
  pnWidth: PLongInt; pnDecimals: PLongInt): DBFFieldType; cdecl; external libshp_dll;
function DBFGetFieldIndex(psDBF: DBFHandle; pszFieldName: PAnsiChar): LongInt; cdecl; external libshp_dll;
function DBFReadIntegerAttribute(hDBF: DBFHandle;
  iShape: LongInt; iField: LongInt): LongInt; cdecl; external libshp_dll;
function DBFReadDoubleAttribute(hDBF: DBFHandle;
  iShape: LongInt; iField: LongInt): Double; cdecl; external libshp_dll;
function DBFReadStringAttribute(hDBF: DBFHandle;
  iShape: LongInt; iField: LongInt): PAnsiChar; cdecl; external libshp_dll;
function DBFIsAttributeNULL(hDBF: DBFHandle;
  iShape: LongInt; iField: LongInt): LongInt; cdecl; external libshp_dll;
function DBFWriteIntegerAttribute(hDBF: DBFHandle;
  iShape: LongInt; iField: LongInt; nFieldValue: LongInt): LongInt; cdecl; external libshp_dll;
function DBFWriteDoubleAttribute(hDBF: DBFHandle;
  iShape: LongInt; iField: LongInt; dFieldValue: Double): LongInt; cdecl; external libshp_dll;
function DBFWriteStringAttribute(hDBF: DBFHandle;
  iShape: LongInt; iField: LongInt; pszFieldValue: PAnsiChar): LongInt; cdecl; external libshp_dll;
function DBFWriteNULLAttribute(hDBF: DBFHandle;
  iShape: LongInt; iField: LongInt): LongInt; cdecl; external libshp_dll;
function DBFReadTuple(psDBF: DBFHandle; hEntity: LongInt): PAnsiChar; cdecl; external libshp_dll;
function DBFWriteTuple(psDBF: DBFHandle; hEntity: LongInt;
  var pRawTuple): LongInt; cdecl; external libshp_dll;
function DBFCloneEmpty(psDBF: DBFHandle; pszFilename: PAnsiChar): DBFHandle; cdecl; external libshp_dll;
procedure DBFClose(hDBF: DBFHandle); cdecl; external libshp_dll;
function DBFGetNativeFieldType(hDBF: DBFHandle; iField: LongInt): AnsiChar; cdecl; external libshp_dll;
function DBFWriteLogicalAttribute(hDBF: DBFHandle; iShape: LongInt;
  iField: LongInt; lValue: PAnsiChar): LongInt; cdecl; external libshp_dll;
function DBFReadLogicalAttribute(hDBF: DBFHandle; iShape: LongInt;
  iField: LongInt): PAnsiChar; cdecl; external libshp_dll;
procedure DBFUpdateHeader(hDBF: DBFHandle); cdecl; external libshp_dll;
function DBFIsRecordDeleted(hDBF: DBFHandle; iShape: LongInt): LongInt; cdecl; external libshp_dll;
function DBFMarkRecordDeleted(hDBF: DBFHandle;
  iShape: LongInt; bIsDeleted: LongInt): LongInt; cdecl; external libshp_dll;
function DBFGetCodePage(hDBF: DBFHandle): PAnsiChar; cdecl; external libshp_dll;
function DBFWriteAttributeDirectly(hDBF: DBFHandle;
  hEntity: LongInt; iField: LongInt; var pValue): LongInt; cdecl; external libshp_dll;

implementation

end.
