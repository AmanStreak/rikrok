import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tik_tok_ui/video/videoMetaData.dart';
import 'package:video_trimmer/trim_editor.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:video_trimmer/video_viewer.dart';

class VideoEditHomePage extends StatelessWidget {
  final String videoPath;
  final bool editRecordedVideo;

  VideoEditHomePage(this.editRecordedVideo, this.videoPath);

  File file;

  final Trimmer _trimmer = Trimmer();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text("Edit Your Video"),
      ),
      body: SafeArea(
        child: Center(
          child:
              editRecordedVideo ? editVideoRecordedByUser() : selectUserVideo(),
        ),
      ),
    );
  }

  editVideoRecordedByUser() {
    return FutureBuilder(
      future: _trimmer.loadVideo(videoFile: File(videoPath)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return TrimmerView(_trimmer);
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }

  selectUserVideo() {
    // return FutureBuilder(
    //   future: ImagePicker.pickVideo(
    //     source: ImageSource.gallery,
    //   ),
    //   builder: (context, snapshot){
    //     return Container(
    //       if(snapshot.connectionState == ConnectionState.active){
    //       FutureBuilder(
    //         future: _trimmer.loadVideo(videoFile: file),
    //         builder: (context, snapshot){
    //           Navigator.of(context).push(MaterialPageRoute(builder: (context) {
    //             return TrimmerView(_trimmer);
    //           }));
    //         }
    //       );
    //     }
    //     );
    //   } ,
    // );

    // file = await ImagePicker.pickVideo(
    //   source: ImageSource.gallery,
    // );

    return Builder(
      builder: (context) => Container(
        child: RaisedButton(
          child: Text("LOAD VIDEO"),
          onPressed: () async {
            file = await ImagePicker.pickVideo(
              source: ImageSource.gallery,
            );
            if (file != null) {
              await _trimmer.loadVideo(videoFile: file);
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return TrimmerView(_trimmer);
              }));
            }
          },
        ),
      ),
    );
  }
}

class TrimmerView extends StatefulWidget {
  final Trimmer _trimmer;
  TrimmerView(this._trimmer);
  @override
  _TrimmerViewState createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView> {
  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;
  bool _progressVisibility = false;

  Future<String> _saveVideo() async {
    setState(() {
      _progressVisibility = true;
    });

    String _value;

    await widget._trimmer
        .saveTrimmedVideo(startValue: _startValue, endValue: _endValue)
        .then((value) {
      setState(() {
        _progressVisibility = false;
        _value = value;
      });
    });

    return _value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.only(bottom: 30.0),
            color: Colors.black,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Visibility(
                  visible: _progressVisibility,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.red,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                Expanded(
                  child: VideoViewer(),
                ),
                Center(
                  child: TrimEditor(
                    borderPaintColor: Colors.deepPurple,
                    viewerHeight: 50.0,
                    viewerWidth: MediaQuery.of(context).size.width,
                    onChangeStart: (value) {
                      _startValue = value;
                    },
                    onChangeEnd: (value) {
                      _endValue = value;
                    },
                    onChangePlaybackState: (value) {
                      setState(() {
                        _isPlaying = value;
                      });
                    },
                  ),
                ),
                FlatButton(
                  child: _isPlaying
                      ? Icon(
                          Icons.pause,
                          size: 70.0,
                          color: Colors.deepPurple,
                        )
                      : Icon(
                          Icons.play_arrow,
                          size: 70.0,
                          color: Colors.deepPurple,
                        ),
                  onPressed: () async {
                    bool playbackState =
                        await widget._trimmer.videPlaybackControl(
                      startValue: _startValue,
                      endValue: _endValue,
                    );
                    setState(() {
                      _isPlaying = playbackState;
                    });
                  },
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.07,
                ),
                RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  padding:
                      EdgeInsets.symmetric(vertical: 15.0, horizontal: 120),
                  color: Colors.deepPurple,
                  splashColor: Colors.purpleAccent,
                  onPressed: _progressVisibility
                      ? null
                      : () async {
                          _saveVideo().then((outputPath) {
                            print('OUTPUT PATH: $outputPath');
                            final snackBar = SnackBar(
                                content: Text('Video Saved successfully'));
                            Scaffold.of(context).showSnackBar(snackBar);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => VideoMetaData()),
                            );
                          });
                        },
                  child: Text(
                    "Continue",
                    style: TextStyle(color: Colors.white, fontSize: 17.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
