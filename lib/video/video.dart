import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tik_tok_ui/video/videoeditor.dart';
import 'package:video_player/video_player.dart';

class CameraExampleHome extends StatefulWidget {
  @override
  CameraExampleHomeState createState() {
    return CameraExampleHomeState();
  }
}

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
  throw ArgumentError('Unknown lens direction');
}

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

class CameraExampleHomeState extends State<CameraExampleHome>
    with WidgetsBindingObserver {
  CameraController controller;
  String imagePath;
  String videoPath;
  VideoPlayerController videoController;
  VoidCallback videoPlayerListener;
  bool enableAudio = true;
  bool recordingStart = true;
  bool editRecordedVideo = true;
  List<CameraDescription> cameras;
  bool appCameraLens = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeCamera().then((_) {
      initializeBackCamera();
    });
  }

  initializeCamera() async {
    cameras = await availableCameras();
    return cameras;
  }

  initializeFrontCamera() {
    print('FrontCamera');
    controller = CameraController(cameras[1], ResolutionPreset.medium);
    initializingCameraController();
  }

  initializeBackCamera() {
    print('BackCamera');
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    initializingCameraController();
  }

  initializingCameraController() {
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller.description);
      }
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Container(
              child: Center(
                child: cameraPreviewWidget(),
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                // border: Border.all(
                //   color: controller != null && controller.value.isRecordingVideo
                //       ? Colors.redAccent
                //       : Colors.grey,
                //   width: 3.0,
                // ),
              ),
            ),
            Positioned(
                top: 80.0,
                left: 10.0,
                child: Container(
                    padding: EdgeInsets.all(5.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: recordingStart
                        ? Icon(
                            Icons.fiber_smart_record,
                            color: Colors.blue,
                          )
                        : Icon(
                            Icons.fiber_smart_record,
                            color: Colors.red,
                          ))),
            Positioned(
                right: MediaQuery.of(context).size.width * 0.03,
                top: MediaQuery.of(context).size.height * 0.15,
                child: _captureControlRowWidget()),
            // _toggleAudioWidget(),
            // Padding(
            //   padding: const EdgeInsets.all(5.0),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.start,
            //     children: <Widget>[
            //       // _cameraTogglesRowWidget(),
            //       // _thumbnailWidget(),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Camera Not Working',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      );
    }
  }

  /// Toggle recording audio
  Widget _toggleAudioWidget() {
    return Padding(
      padding: const EdgeInsets.only(left: 25),
      child: Row(
        children: <Widget>[
          const Text('Enable Audio:'),
          Switch(
            value: enableAudio,
            onChanged: (bool value) {
              enableAudio = value;
              if (controller != null) {
                onNewCameraSelected(controller.description);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Display the thumbnail of the captured image or video.
  // Widget _thumbnailWidget() {
  //   return Expanded(
  //     child: Align(
  //       alignment: Alignment.centerRight,
  //       child: Row(
  //         mainAxisSize: MainAxisSize.min,
  //         children: <Widget>[
  //           videoController == null && imagePath == null
  //               ? Container()
  //               : SizedBox(
  //                   child: (videoController == null)
  //                       ? Image.file(File(imagePath))
  //                       : Container(
  //                           child: Center(
  //                             child: AspectRatio(
  //                                 aspectRatio:
  //                                     videoController.value.size != null
  //                                         ? videoController.value.aspectRatio
  //                                         : 1.0,
  //                                 child: VideoPlayer(videoController)),
  //                           ),
  //                           decoration: BoxDecoration(
  //                               border: Border.all(color: Colors.pink)),
  //                         ),
  //                   width: 64.0,
  //                   height: 64.0,
  //                 ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // IconButton(
        //   icon: const Icon(Icons.camera_alt),
        //   color: Colors.blue,
        //   onPressed: controller != null &&
        //           controller.value.isInitialized &&
        //           !controller.value.isRecordingVideo
        //       ? onTakePictureButtonPressed
        //       : null,
        // ),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: Container(
            padding: EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.videocam,
                size: 30.0,
              ),
              color: Colors.blue,
              onPressed: () {
                controller != null &&
                        controller.value.isInitialized &&
                        !controller.value.isRecordingVideo
                    ? onVideoRecordButtonPressed()
                    : null;
                setState(() {
                  recordingStart = false;
                });
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: Container(
            padding: EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: controller != null && controller.value.isRecordingPaused
                  ? Icon(
                      Icons.play_arrow,
                      size: 30.0,
                      color: Colors.grey,
                    )
                  : Icon(
                      Icons.pause,
                      size: 30.0,
                      color: Colors.grey,
                    ),
              // color: Colors.blue,
              onPressed: controller != null &&
                      controller.value.isInitialized &&
                      controller.value.isRecordingVideo
                  ? (controller != null && controller.value.isRecordingPaused
                      ? onResumeButtonPressed
                      : onPauseButtonPressed)
                  : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: Container(
            padding: EdgeInsets.all(7.0),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
                icon: const Icon(
                  Icons.stop,
                  size: 30.0,
                  color: Colors.red,
                ),
                // color: Colors.red,
                onPressed: () {
                  controller != null &&
                          controller.value.isInitialized &&
                          controller.value.isRecordingVideo
                      ? onStopButtonPressed()
                      : null;
                  setState(() {
                    recordingStart = true;
                  });
                }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: Container(
            padding: EdgeInsets.all(7.0),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.audiotrack,
                color: Colors.green,
                size: 30.0,
              ),
              onPressed: () {
                enableAudio = !enableAudio;
                if (controller != null) {
                  onNewCameraSelected(controller.description);
                }
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: Container(
            padding: EdgeInsets.all(7.0),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.video_library,
                size: 30.0,
                color: Colors.deepPurple,
              ),
              onPressed: () {
                editRecordedVideo = false;
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) =>
                          VideoEditHomePage(editRecordedVideo, videoPath)),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: Container(
            padding: EdgeInsets.all(7.0),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.switch_camera,
                size: 30.0,
                color: Colors.deepPurple,
              ),
              onPressed: () {
                setState(() {
                  appCameraLens = !appCameraLens;
                  print(appCameraLens);
                });
                if (appCameraLens) {
                  initializeBackCamera();
                } else {
                  initializeFrontCamera();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Display a row of toggle to select the camera (or a message if no camera is available).
  // Widget _cameraTogglesRowWidget() {
  //   final List<Widget> toggles = <Widget>[];

  //   if (false) {
  //     return const Text('No camera found');
  //   } else {
  //     for (CameraDescription cameraDescription in cameras) {
  //       toggles.add(
  //         SizedBox(
  //           width: 90.0,
  //           child: RadioListTile<CameraDescription>(
  //             title: Icon(getCameraLensIcon(cameraDescription.lensDirection)),
  //             groupValue: controller?.description,
  //             value: cameraDescription,
  //             onChanged: controller != null && controller.value.isRecordingVideo
  //                 ? null
  //                 : onNewCameraSelected,
  //           ),
  //         ),
  //       );
  //     }
  //   }

  //   return Row(children: toggles);
  // }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: enableAudio,
    );

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showInSnackBar('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

//  void onTakePictureButtonPressed() {
//    takePicture().then((String filePath) {
//      if (mounted) {
//        setState(() {
//          imagePath = filePath;
//          videoController?.dispose();
//          videoController = null;
//        });
//        if (filePath != null) showInSnackBar('Picture saved to $filePath');
//      }
//    });
//  }

  void onVideoRecordButtonPressed() {
    startVideoRecording().then((String filePath) {
      if (mounted) setState(() {});
      if (filePath != null) showInSnackBar('Saving video to $filePath');
    });
  }

  void onStopButtonPressed() {
    stopVideoRecording().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video recorded to: $videoPath');
      editRecordedVideo = true;
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) =>
                VideoEditHomePage(editRecordedVideo, videoPath)),
      );
    });
  }

  void onPauseButtonPressed() {
    pauseVideoRecording().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video recording paused');
    });
  }

  void onResumeButtonPressed() {
    resumeVideoRecording().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video recording resumed');
    });
  }

  Future<String> startVideoRecording() async {
    if (!controller.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }

    final Directory extDir = await getExternalStorageDirectory();
    final String dirPath = '${extDir.path}/Movies/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.mp4';

    if (controller.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return null;
    }

    try {
      videoPath = filePath;
      await controller.startVideoRecording(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  Future<void> stopVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }

    // await _startVideoPlayer();
  }

  Future<void> pauseVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.pauseVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> resumeVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.resumeVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

//  Future<void> _startVideoPlayer() async {
//    final VideoPlayerController vcontroller =
//        VideoPlayerController.file(File(videoPath));
//    videoPlayerListener = () {
//      if (videoController != null && videoController.value.size != null) {
//        // Refreshing the state to update video player with the correct ratio.
//        if (mounted) setState(() {});
//        videoController.removeListener(videoPlayerListener);
//      }
//    };
//    vcontroller.addListener(videoPlayerListener);
//    await vcontroller.setLooping(true);
//    await vcontroller.initialize();
//    await videoController?.dispose();
//    if (mounted) {
//      setState(() {
//        imagePath = null;
//        videoController = vcontroller;
//      });
//    }
//    await vcontroller.play();
//  }

//  Future<String> takePicture() async {
//    if (!controller.value.isInitialized) {
//      showInSnackBar('Error: select a camera first.');
//      return null;
//    }
//    final Directory extDir = await getExternalStorageDirectory();
//    final String dirPath = '${extDir.path}/Pictures/flutter_test';
//    await Directory(dirPath).create(recursive: true);
//    final String filePath = '$dirPath/${timestamp()}.jpg';
//
//    if (controller.value.isTakingPicture) {
//      // A capture is already pending, do nothing.
//      return null;
//    }
//
//    try {
//      await controller.takePicture(filePath);
//    } on CameraException catch (e) {
//      _showCameraException(e);
//      return null;
//    }
//    return filePath;
//  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}

//class CameraApp extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      home: CameraExampleHome(),
//    );
//  }
//}
//
//List<CameraDescription> cameras = [];
//
//Future<void> main() async {
//  // Fetch the available cameras before initializing the app.
//  try {
//    WidgetsFlutterBinding.ensureInitialized();
//    cameras = await availableCameras();
//  } on CameraException catch (e) {
//    logError(e.code, e.description);
//  }
//  runApp(CameraApp());
//}
