# DelphiKinect2Body

This is a demo project that uses a QT DLL that goes between Kinect20.lib and Delphi.

The source for the DLL can be found at:

https://github.com/ConroyBadger/Kinect2MultiDLL

The DLL was compiled with the Visual Studio 2013. If you are using a different
Visual Studio runtime redistributable you may need to rebuild the QT project.

You can get QT here:

https://www.qt.io/download/

The demo is a Win32 application written in Delphi 10. Simply run Kinect2Test.exe.

You should see the full HD color camera image with skeleton points overlaid when the kinect2 detects a body.

Special thanks to Antimodular Incorporated where I worked while writing this code. They have generously allowed it into the public domain.

http://lozano-hemmer.com/