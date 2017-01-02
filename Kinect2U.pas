unit Kinect2U;

interface

uses
  Windows, Kinect2DLL, Graphics, SysUtils, Classes;

type
  TByteTable = array[0..High(TDepthFrameData)] of Byte;

  TKinect2 = class(TObject)
  private
    ByteTable : TByteTable;

    FrameRateFrame : Integer;

    DepthData : PDepthFrameData;
    IRData    : PIRFrameData;
    ColorData : PColorFrameData;

    BodyData : TBodyDataArray;

    procedure BuildByteTable;

    procedure SetMinDepth(V:TDepthFrameData);
    procedure SetMaxDepth(V:TDepthFrameData);
    procedure SyncBodyData;

  public
    FMinDepth : TDepthFrameData;
    FMaxDepth : TDepthFrameData;

    DepthBmp  : TBitmap;
    RGBOffset : Integer;

    DllLoaded : Boolean;
    Ready     : Boolean;

    FrameCount  : Integer;
    MeasuredFPS : Single;
    LastFrameRateTime : DWord;

    property MinDepth:TDepthFrameData read FMinDepth write SetMinDepth;
    property MaxDepth:TDepthFrameData read FMaxDepth write SetMaxDepth;

    constructor Create;
    destructor Destroy; override;

    function DLLVersion:String;

    procedure StartUp;
    procedure ShutDown;

// depth
    function  AbleToStartDepthStream:Boolean;
    function  AbleToGetDepthFrame:Boolean;
    procedure DoneDepth;

// IR
    function  AbleToStartIRStream:Boolean;
    function  AbleToGetIRFrame:Boolean;
    procedure DoneIR;

// color
    function  AbleToStartColorStream:Boolean;
    function  AbleToGetColorFrame:Boolean;
    procedure DoneColor;

// body
    function  AbleToStartBodyStream:Boolean;
    function  AbleToUpdateBody:Boolean;
    procedure DoneBody;

// multiframe
    function  AbleToStartMultiFrame:Boolean;
    function  AbleToUpdateMultiFrame:Boolean;
    procedure DoneMultiFrame;

    procedure DrawDepthBmp(Bmp:TBitmap);
    procedure DrawIRBmp(Bmp:TBitmap;Divisor:Integer);
    procedure DrawColorBmp(Bmp:TBitmap);

    procedure MeasureFrameRate;

    procedure DrawBodies(Bmp:TBitmap);

    function TrackedBodies: Integer;
  end;

var
  Kinect2 : TKinect2;

implementation

uses
  BmpUtils;

const
  FrameRateAverages  = 10;

constructor TKinect2.Create;
begin
  DepthBmp:=TBitmap.Create;
  DepthBmp.Width:=DEPTH_W;
  DepthBmp.Height:=DEPTH_H;
  DepthBmp.PixelFormat:=pf24Bit;
  ClearBmp(DepthBmp,clBlack);

  DllLoaded:=False;
  Ready:=False;

  FMinDepth:=1;
  FMaxDepth:=1000;//High(TDepthFrameData);
  BuildByteTable;

  RGBOffset:=0;

  FrameCount:=0;
  FrameRateFrame:=0;

  DepthData:=nil;
  IRData:=nil;
  ColorData:=nil;

  MeasuredFPS:=0;
  LastFrameRateTime:=GetTickCount;
end;

destructor TKinect2.Destroy;
begin
  if Assigned(DepthBmp) then DepthBmp.Free;
end;

function TKinect2.DLLVersion:String;
begin
  Result:=KinectVersionString;
end;

procedure TKinect2.StartUp;
begin
  if AbleToLoadKinectLibrary then begin
    DllLoaded:=True;
    Ready:=AbleToStartUpKinect2;
  end;
end;

procedure TKinect2.ShutDown;
begin
  if Ready then begin
    ShutDownKinect2;
    Ready:=False;
  end;

  UnloadKinectLibrary;
end;

procedure TKinect2.MeasureFrameRate;
var
  Time    : DWord;
  Elapsed : Single;
begin
  Inc(FrameCount);

// average it out a bit so it's readable
  if (FrameCount-FrameRateFrame)>=FrameRateAverages then begin
    Time:=GetTickCount;
    Elapsed:=(Time-LastFrameRateTime)/1000;
    if Elapsed=0 then MeasuredFPS:=999
    else MeasuredFPS:=FrameRateAverages/Elapsed;

    LastFrameRateTime:=Time;
    FrameRateFrame:=FrameCount;
  end;
end;

function TKinect2.AbleToStartDepthStream:Boolean;
begin
  Result:=AbleToStartDepth;
end;

function TKinect2.AbleToGetDepthFrame: Boolean;
begin
  DepthData:=GetDepthFrame;

  if Assigned(DepthData) then begin
    MeasureFrameRate;
    Result:=True;
  end
  else Result:=False;

// we need to call this either way
end;

procedure TKinect2.DoneDepth;
begin
  DoneDepthFrame;
end;

function TKinect2.AbleToStartIRStream:Boolean;
begin
  Result:=AbleToStartIR;
end;

function TKinect2.AbleToGetIRFrame: Boolean;
begin
  IRData:=GetIRFrame;

  if Assigned(IRData) then begin
    MeasureFrameRate;
    Result:=True;
  end
  else Result:=False;
end;

procedure TKinect2.DoneIR;
begin
  DoneIRFrame;
end;

function TKinect2.AbleToStartColorStream:Boolean;
begin
  Result:=AbleToStartColor;
end;

function TKinect2.AbleToGetColorFrame: Boolean;
begin
  ColorData:=GetColorFrame;

  if Assigned(ColorData) then begin
    MeasureFrameRate;
    Result:=True;
  end
  else Result:=False;
end;

procedure TKinect2.DoneColor;
begin
  DoneColorFrame;
end;

function TKinect2.AbleToStartMultiFrame:Boolean;
begin
  Result:=Kinect2DLL.AbleToStartMultiFrame;
end;

function TKinect2.AbleToUpdateMultiFrame: Boolean;
begin
  Result:=Kinect2DLL.AbleToUpdateMultiFrame;
  if Result then MeasureFrameRate;
end;

procedure TKinect2.DoneMultiFrame;
begin
  Kinect2DLL.DoneMultiFrame;
end;

function TKinect2.AbleToStartBodyStream:Boolean;
begin
  Result:=Kinect2DLL.AbleToStartBody;
end;

procedure TKinect2.SyncBodyData;
var
  BodyPtr : PBodyData;
  Size    : Integer;
begin
  BodyPtr:=Kinect2DLL.GetBodyData;
  Size:=SizeOf(BodyData);
  Move(BodyPtr^,BodyData[1],Size);
end;

function TKinect2.AbleToUpdateBody:Boolean;
begin
  Result:=Kinect2DLL.AbleToUpdateBodyFrame;
  if Result then begin
    SyncBodyData;
    Kinect2DLL.DoneBodyFrame;
  end;
end;

procedure TKinect2.DoneBody;
begin
  Kinect2DLL.DoneBodyFrame;
end;

procedure TKinect2.SetMinDepth(V:TDepthFrameData);
begin
  FMinDepth:=V;
  BuildByteTable;
end;

procedure TKinect2.SetMaxDepth(V:TDepthFrameData);
begin
  FMaxDepth:=V;
  BuildByteTable;
end;

procedure TKinect2.BuildByteTable;
var
  I : TDepthFrameData;
  F : Single;
  V : Byte;
begin
  for I:=0 to High(TDepthFrameData) do begin
    if I<FMinDepth then V:=0
    else if I>FMaxDepth then V:=0
    else begin
      F:=(I-FMinDepth)/(FMaxDepth-FMinDepth);
      V:=Round(F*255);
    end;
    ByteTable[I]:=V;
  end;
end;

procedure TKinect2.DrawDepthBmp(Bmp:TBitmap);
var
  Data : PDepthFrameData;
  Line : PByteArray;
  X,Y  : Integer;
begin
  Data:=DepthData;
  for Y:=0 to DEPTH_H-1 do begin
    Line:=Bmp.ScanLine[Y];
    for X:=0 to DEPTH_W-1 do begin
      Line^[X*3+0]:=ByteTable[Data^];
      Line^[X*3+1]:=ByteTable[Data^];
      Line^[X*3+2]:=ByteTable[Data^];
      Inc(Data);
    end;
  end;
end;

procedure TKinect2.DrawIRBmp(Bmp:TBitmap;Divisor:Integer);
var
  Data : PIRFrameData;
  Line : PByteArray;
  X,Y  : Integer;
begin
  Data:=IRData;
  for Y:=0 to DEPTH_H-1 do begin
    Line:=Bmp.ScanLine[Y];
    for X:=0 to DEPTH_W-1 do begin
      Line^[X*3+0]:=0;
      Line^[X*3+1]:=((Data^ shr Divisor) and $FF);
      Line^[X*3+2]:=0;
      Inc(Data);
    end;
  end;
end;

procedure TKinect2.DrawColorBmp(Bmp:TBitmap);
var
  Data : PColorFrameData;
  Line : PByteArray;
  X,Y  : Integer;
  BPR  : Integer;
begin
  Assert(Bmp.PixelFormat=pf32Bit,'');

 // ColorData:=GetColorData;

  BPR:=COLOR_W*COLOR_BPP;
  Data:=ColorData;
  for Y:=0 to COLOR_H-1 do begin
    Line:=Bmp.ScanLine[Y];
    Move(Data^,Line^,BPR);
    Inc(Data,BPR);
  end;
end;

procedure TKinect2.DrawBodies(Bmp:TBitmap);
const
  Size = 5;
var
  B,J,X,Y  : Integer;
  Xf,Yf    : Single;
begin
  Bmp.Canvas.Pen.Color:=clBlue;
  Bmp.Canvas.Brush.Color:=clRed;
  for B:=1 to BODY_COUNT do if BodyData[B].Tracked then begin
    for J:=1 to JOINT_TYPE_COUNT do begin
      if BodyData[B].Joint[J].TrackingState=TrackingState_Tracked then begin // <>TrackingState_NotTracked then begin
        Xf:=BodyData[B].JointColorPt[J].X;
        Yf:=BodyData[B].JointColorPt[J].Y;

        X:=Round(Xf);
        Y:=Round(Yf);

        if J=(Ord(JointType_Head)+1) then Bmp.Canvas.Brush.Color:=clWhite
        else if J in [Ord(JointType_ShoulderLeft)+1,
                      Ord(JointType_ShoulderRight)+1] then
        begin
          Bmp.Canvas.Brush.Color:=clLime;
        end
        else Bmp.Canvas.Brush.Color:=clGray;
        Bmp.Canvas.Ellipse(X-Size,Y-Size,X+Size+1,Y+Size+1);
      end;
    end;
  end;
end;

function TKinect2.TrackedBodies:Integer;
var
  I : Integer;
begin
  Result:=0;
  for I:=1 to BODY_COUNT do begin
    if BodyData[I].Tracked then Inc(Result);
  end;
end;

end.


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



