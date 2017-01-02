unit Kinect2;

interface

uses
  Kinect2DLL;

type
  TKinect2 = class(TObject)
  private

  public
    MinDepth : TDepthFrameData;
    MaxDepth : TDepthFrameData;

    DepthBmp : TBitmap;

    constructor Create;
    destructor Destroy; override;

    function GetDLLVersion:String;

    procedure StartUp;
    procedure ShutDown;

    function  AbleToUpdate:Boolean;

    procedure DrawDepthBmp;
  end;

var
  Kinect2 : TKinect2;

implementation

constructor TKinect2.Create;
begin

end;

destructor TKinect2.Destroy;
begin

end;

function TKinect2.GetDLLVersion:String;
begin
  Result:=KinectVersionString;
end;

procedure TKinect2.StartUp;
begin

end;


procedure TKinect2.ShutDown;
begin

end;


function TKinect2.AbleToUpdate: Boolean;
begin

end;

end.
