import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tik_tok_ui/video/video.dart';

import 'package:tik_tok_ui/widgets/video_description.dart';
import 'package:tik_tok_ui/widgets/actions_toolbar.dart';
import 'package:tik_tok_ui/widgets/bottom_toolbar.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  CameraController controller;

  initializeCamera() async {
    List<CameraDescription> cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  Widget openCamera() {
    if (controller == null) {
      return Container(
        child: Text('Open Camera'),
      );
    }
    return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller));
  }

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  CameraExampleHomeState cameraExampleHome = CameraExampleHomeState();

  Widget get topSection => Container(
        height: 100.0,
        padding: EdgeInsets.only(bottom: 15.0),
        alignment: Alignment(0.0, 1.0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Following'),
              Container(
                width: 15.0,
              ),
              Text('For you',
                  style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold))
            ]),
      );

  Widget get middleSection => Expanded(
      child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[VideoDescription(), ActionsToolbar()]));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          openCamera(),
          Column(
            children: <Widget>[
              // Top section
              topSection,

              // Middle expanded
              middleSection,

              // Bottom Section
              BottomToolbar(),
            ],
          ),
        ],
      ),
    );
  }
}
