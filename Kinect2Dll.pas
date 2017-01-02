unit Kinect2Dll;

interface

uses
  Windows, SysUtils, Dialogs;

type
  TDepthFrameData = Word;
  PDepthFrameData = PWord;

  TIRFrameData = Word;
  PIRFrameData = PWord;

  TColorFrameData = Byte;
  PColorFrameData = PByte;

function KinectVersionString:String;

function AbleToLoadKinectLibrary:Boolean;
procedure UnloadKinectLibrary;

function  AbleToStartUpKinect2:Boolean;
procedure ShutDownKinect2;

const
  KINECT2_DLL_NAME = 'Kinect2DLL.dll';

  DEPTH_W = 512;
  DEPTH_H = 424;

  IR_W = 512;
  IR_H = 424;

  COLOR_W = 1920;
  COLOR_H = 1080;
  COLOR_BPP = 4;

// hand state
  HandState_Unknown	   = 0;
  HandState_NotTracked = 1;
  HandState_Open       = 2;
  HandState_Closed	   = 3;
  HandState_Lasso	     = 4;

// tracking confidence
  TrackingConfidence_Low  = 0;
  TrackingConfidence_High	= 1;

  JOINT_TYPE_COUNT = 25;

  BODY_COUNT = 6;

type
  TJointType = (JointType_SpineBase, JointType_SpineMid, JointType_Neck,
    JointType_Head, JointType_ShoulderLeft, JointType_ElbowLeft,
    JointType_WristLeft, JointType_HandLeft, JointType_ShoulderRight,
    JointType_ElbowRight, JointType_WristRight, JointType_HandRight,
    JointType_HipLeft, JointType_KneeLeft, JointType_AnkleLeft,
    JointType_FootLeft, JointType_HipRight, JointType_KneeRight,
    JointType_AnkleRight, JointType_FootRight, JointType_SpineShoulder,
    JointType_HandTipLeft, JointType_ThumbLeft, JointType_HandTipRight,
    JointType_ThumbRight, JointType_Count);

  TTrackingState = (TrackingState_NotTracked, TrackingState_Inferred,
    TrackingState_Tracked);

  TCameraSpacePoint = record
    X, Y, Z : Single;
  end;
  PCameraSpacePoint = ^TCameraSpacePoint;

  TJoint = record
    JointType     : TJointType;
    Position      : TCameraSpacePoint;
    TrackingState : TTrackingState;
  end;
  PJoint = ^TJoint;

  TJointArray = array[1..JOINT_TYPE_COUNT] of TJoint;

  THandState = Integer;

  TColorSpacePoint = record
    X,Y : Single;
  end;

  TJointColorPtArray = array[1..JOINT_TYPE_COUNT] of TColorSpacePoint;

  TBodyData = record
    TrackingID     : Int64;
    Tracked        : Boolean;
    Confidence     : Integer;
    LeftHandState  : THandState;
    RightHandState : THandState;
    Joint          : TJointArray;
    JointColorPt   : TJointColorPtArray;
  end;
  PBodyData = ^TBodyData;

  TBodyDataArray = array[1..BODY_COUNT] of TBodyData;
  PBodyDataArray = ^TBodyDataArray;

  TGetVersion = function:Integer; stdcall; // yes it's just an integer :)

  TAbleToInitialize = function:Boolean; stdcall;

  TAbleToStartStream = function:Boolean; stdcall;

  TGetDepthFrame = function:PDepthFrameData; stdcall;
  TGetIRFrame = function:PIRFrameData; stdcall;
  TGetColorFrame = function:PColorFrameData; stdcall;

  TDoneFrame = procedure; stdcall;

  TAbleToUpdateBodyFrame = function:Boolean; stdcall;

  TShutDown = procedure; stdcall;

  TGetColorData = function:PColorFrameData; stdcall;
  TGetBodyData = function:PBodyData; stdcall;

  TAbleToUpdateMultiFrame = function:Boolean; stdcall;

var
  HLibrary : HModule = 0;

  GetVersion    : TGetVersion = nil;
  AbleToStartUp : TAbleToInitialize = nil;
  ShutDown      : TShutDown = nil;

// depth
  AbleToStartDepth : TAbleToStartStream = nil;
  GetDepthFrame    : TGetDepthFrame = nil;
  DoneDepthFrame   : TDoneFrame = nil;

// IR
  AbleToStartIR : TAbleToStartStream = nil;
  GetIRFrame    : TGetIRFrame = nil;
  DoneIRFrame   : TDoneFrame = nil;

// color
  AbleToStartColor : TAbleToStartStream = nil;
  GetColorFrame    : TGetColorFrame = nil;
  DoneColorFrame   : TDoneFrame = nil;
  GetColorData     : TGetColorData = nil;

// multiframe
  AbleToStartMultiFrame  : TAbleToStartStream = nil;
  AbleToUpdateMultiFrame : TAbleToUpdateMultiFrame = nil;
  DoneMultiFrame         : TDoneFrame = nil;

// body
  AbleToStartBody       : TAbleToStartStream = nil;
  AbleToUpdateBodyFrame : TAbleToUpdateBodyFrame = nil;
  DoneBodyFrame         : TDoneFrame = nil;
  GetBodyData           : TGetBodyData = nil;

function FullDLLName:String;

implementation

function KinectVersionString:String;
var
  V : Integer;
begin
  if HLibrary=0 then Result:='???'
  else begin
    V:=getVersion;
    Result:=IntToStr(V);
  end;
end;

function FullDLLName:String;
begin
  Result:=KINECT2_DLL_NAME;
end;

function AbleToLoadKinectLibrary:Boolean;
var
  FileName : String;
  RC       : Integer;
begin
  Result:=False;
  if HLibrary<>0 then Exit;

  FileName:=FullDLLName;
  if not FileExists(FileName) then begin
    ShowMessage(FileName+' not found');
  end;
  HLibrary:=LoadLibrary(PChar(FileName));
  if HLibrary=0 then begin
    RC:=GetLastError;
    Exit;
  end;

// version
  GetVersion:=GetProcAddress(HLibrary,'getVersion');
  if not Assigned(GetVersion) then Exit;

// startup / shutdown
  AbleToStartUp:=GetProcAddress(HLibrary,'ableToStartUp');
  if not Assigned(AbleToStartUp) then Exit;

  ShutDown:=GetProcAddress(HLibrary,'shutDown');
  if not Assigned(ShutDown) then Exit;

// depth
  AbleToStartDepth:=GetProcAddress(HLibrary,'ableToStartDepth');
  if not Assigned(AbleToStartDepth) then Exit;

  GetDepthFrame:=GetProcAddress(HLibrary,'getDepthFrame');
  if not Assigned(GetDepthFrame) then Exit;

  DoneDepthFrame:=GetProcAddress(HLibrary,'doneDepthFrame');
  if not Assigned(DoneDepthFrame) then Exit;

// IR
  AbleToStartIR:=GetProcAddress(HLibrary,'ableToStartIR');
  if not Assigned(AbleToStartIR) then Exit;

  GetIRFrame:=GetProcAddress(HLibrary,'getIRFrame');
  if not Assigned(GetIRFrame) then Exit;

  DoneIRFrame:=GetProcAddress(HLibrary,'doneIRFrame');
  if not Assigned(DoneIRFrame) then Exit;

// color
  AbleToStartColor:=GetProcAddress(HLibrary,'ableToStartColor');
  if not Assigned(AbleToStartColor) then Exit;

  GetColorFrame:=GetProcAddress(HLibrary,'getColorFrame');
  if not Assigned(GetColorFrame) then Exit;

  DoneColorFrame:=GetProcAddress(HLibrary,'doneColorFrame');
  if not Assigned(DoneColorFrame) then Exit;

  GetColorData:=GetProcAddress(HLibrary,'getColorData');
  if not Assigned(GetColorData) then Exit;

// multiframe
  AbleToStartMultiFrame:=GetProcAddress(HLibrary,'ableToStartMultiFrame');
  if not Assigned(AbleToStartMultiFrame) then Exit;

  AbleToUpdateMultiFrame:=GetProcAddress(HLibrary,'ableToUpdateMultiFrame');
  if not Assigned(AbleToUpdateMultiFrame) then Exit;

  DoneMultiFrame:=GetProcAddress(HLibrary,'doneMultiFrame');
  if not Assigned(DoneMultiFrame) then Exit;

// body
  AbleToStartBody:=GetProcAddress(HLibrary,'ableToStartBody');
  if not Assigned(AbleToStartBody) then Exit;

  AbleToUpdateBodyFrame:=GetProcAddress(HLibrary,'ableToUpdateBodyFrame');
  if not Assigned(AbleToUpdateBodyFrame) then Exit;

  GetBodyData:=GetProcAddress(HLibrary,'getBodyData');
  if not Assigned(GetBodyData) then Exit;

  DoneBodyFrame:=GetProcAddress(HLibrary,'doneBodyFrame');
  if not Assigned(DoneBodyFrame) then Exit;

  Result:=True;
end;

procedure UnloadKinectLibrary;
begin
  if HLibrary=0 then Exit;

  GetVersion:=nil;
  AbleToStartUp:=nil;
  ShutDown:=nil;

// depth
  AbleToStartDepth:=nil;
  GetDepthFrame:=nil;
  DoneDepthFrame:= nil;

// IR
  AbleToStartIR:=nil;
  GetIRFrame:=nil;
  DoneIRFrame:=nil;

// color
  AbleToStartColor:=nil;
  GetColorFrame:=nil;
  DoneColorFrame:=nil;
  GetColorData:=nil;

// multiframe
  AbleToStartMultiFrame:=nil;
  AbleToUpdateMultiFrame:=nil;
  DoneMultiFrame:=nil;

// body
  AbleToStartBody:=nil;
  AbleToUpdateBodyFrame:=nil;
  DoneBodyFrame:=nil;
  if not Assigned(DoneBodyFrame) then Exit;
  GetBodyData:=nil;

  FreeLibrary(HLibrary);

  HLibrary:=0;
end;

function AbleToStartUpKinect2:Boolean;
begin
  Result:=AbleToStartUp;
end;

procedure ShutDownKinect2;
begin
  ShutDown;
end;

end.

