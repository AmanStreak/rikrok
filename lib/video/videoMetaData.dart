import 'package:flutter/material.dart';

class VideoMetaData extends StatefulWidget {
  @override
  _VideoMetaDateState createState() => _VideoMetaDateState();
}

class _VideoMetaDateState extends State<VideoMetaData> {
  TextEditingController descriptionController = TextEditingController();
  TextEditingController tagsController = TextEditingController();
  String videoDescription, videoTags;
  DateTime uploadDateTime;
  final formkey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  void saveVideDetails() {
    if (selectedLanguages.containsValue(true)) {
      if (formkey.currentState.validate()) {
        formkey.currentState.save();
        uploadDateTime = DateTime.now();
        print('$uploadDateTime');
        print('Tags $videoTags desc $videoDescription');
      } else {
        print('value can\'t be saved');
      }
    } else {
      SnackBar snackBar = SnackBar(
        content: Text('Select atleast one language'),
      );
      scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  Map<String, bool> selectedLanguages = {
    'Hindi': false,
    'English': false,
    'Punjabi': false,
    'Tamil': false,
    'Telugu': false,
    'Bengali': false,
    'Marathi': false,
    'Gujarati': false,
    'Urdu': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          'Video Details',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Builder(
          builder: (context) => SingleChildScrollView(child: VideoForm())),
    );
  }

  Widget VideoForm() {
    return Container(
      padding: EdgeInsets.all(10.0),
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Form(
        key: formkey,
        child: ListView(
          children: <Widget>[
            TextFormField(
              validator: (input) {
                if (input.isEmpty) {
                  return 'Enter Description';
                }
              },
              onSaved: (input) => videoDescription = input,
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                icon: Icon(Icons.description, color: Colors.deepPurple),
              ),
            ),
            TextFormField(
              controller: tagsController,
              validator: (input) {
                if (input.isEmpty) {
                  return 'Enter Tags';
                }
              },
              onSaved: (input) => videoTags = input,
              maxLines: 5,
              decoration: InputDecoration(
                helperMaxLines: 10,
                labelText: 'Tags',
                icon: Icon(Icons.label_important, color: Colors.deepPurple),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.05,
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                'Select Video Language :',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17.0,
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.025,
            ),
            Wrap(
              alignment: WrapAlignment.start,
              spacing: 10.0,
              children: <Widget>[
                ChoiceChip(
                  backgroundColor: Colors.deepPurple,
                  selectedColor: Colors.orange,
                  selected: selectedLanguages['Hindi'],
                  onSelected: (bool selected) {
                    setState(() {
                      selectedLanguages['Hindi'] = !selectedLanguages['Hindi'];
                    });
                  },
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(7.0),
                      bottomRight: Radius.circular(7.0),
                    ),
                  ),
                  elevation: 4.0,
                  label: Text(
                    'Hindi',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ChoiceChip(
                  backgroundColor: Colors.deepPurple,
                  selectedColor: Colors.orange,
                  selected: selectedLanguages['English'],
                  onSelected: (bool selected) {
                    setState(() {
                      selectedLanguages['English'] =
                          !selectedLanguages['English'];
                    });
                  },
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(7.0),
                      bottomRight: Radius.circular(7.0),
                    ),
                  ),
                  elevation: 4.0,
                  label: Text(
                    'English',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ChoiceChip(
                  selected: selectedLanguages['Punjabi'],
                  backgroundColor: Colors.deepPurple,
                  selectedColor: Colors.orange,
                  onSelected: (bool selected) {
                    setState(() {
                      selectedLanguages['Punjabi'] =
                          !selectedLanguages['Punjabi'];
                    });
                  },
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(7.0),
                      bottomRight: Radius.circular(7.0),
                    ),
                  ),
                  elevation: 4.0,
                  label: Text(
                    'Punjabi',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ChoiceChip(
                  selected: selectedLanguages['Tamil'],
                  backgroundColor: Colors.deepPurple,
                  selectedColor: Colors.orange,
                  onSelected: (bool selected) {
                    setState(() {
                      selectedLanguages['Tamil'] = !selectedLanguages['Tamil'];
                    });
                  },
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(7.0),
                      bottomRight: Radius.circular(7.0),
                    ),
                  ),
                  elevation: 4.0,
                  label: Text(
                    'Tamil',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ChoiceChip(
                  selected: selectedLanguages['Telugu'],
                  backgroundColor: Colors.deepPurple,
                  selectedColor: Colors.orange,
                  onSelected: (bool selected) {
                    setState(() {
                      selectedLanguages['Telugu'] =
                          !selectedLanguages['Telugu'];
                    });
                  },
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(7.0),
                      bottomRight: Radius.circular(7.0),
                    ),
                  ),
                  elevation: 4.0,
                  label: Text(
                    'Telugu',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ChoiceChip(
                  selected: selectedLanguages['Bengali'],
                  backgroundColor: Colors.deepPurple,
                  selectedColor: Colors.orange,
                  onSelected: (bool selected) {
                    setState(() {
                      selectedLanguages['Bengali'] =
                          !selectedLanguages['Bengali'];
                    });
                  },
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(7.0),
                      bottomRight: Radius.circular(7.0),
                    ),
                  ),
                  elevation: 4.0,
                  label: Text(
                    'Bengali',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ChoiceChip(
                  selected: selectedLanguages['Marathi'],
                  backgroundColor: Colors.deepPurple,
                  selectedColor: Colors.orange,
                  onSelected: (bool selected) {
                    setState(() {
                      selectedLanguages['Marathi'] =
                          !selectedLanguages['Marathi'];
                    });
                  },
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(7.0),
                      bottomRight: Radius.circular(7.0),
                    ),
                  ),
                  elevation: 4.0,
                  label: Text(
                    'Marathi',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ChoiceChip(
                  selected: selectedLanguages['Gujarati'],
                  backgroundColor: Colors.deepPurple,
                  selectedColor: Colors.orange,
                  onSelected: (bool selected) {
                    setState(() {
                      selectedLanguages['Gujarati'] =
                          !selectedLanguages['Gujarati'];
                    });
                  },
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(7.0),
                      bottomRight: Radius.circular(7.0),
                    ),
                  ),
                  elevation: 4.0,
                  label: Text(
                    'Gujarati',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ChoiceChip(
                  selected: selectedLanguages['Urdu'],
                  backgroundColor: Colors.deepPurple,
                  selectedColor: Colors.orange,
                  onSelected: (bool selected) {
                    setState(() {
                      selectedLanguages['Urdu'] = !selectedLanguages['Urdu'];
                    });
                  },
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(7.0),
                      bottomRight: Radius.circular(7.0),
                    ),
                  ),
                  elevation: 4.0,
                  label: Text(
                    'Urdu',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.045,
            ),
            RaisedButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 120),
              color: Colors.deepPurple,
              splashColor: Colors.purpleAccent,
              child: Text(
                'SUBMIT',
                style: TextStyle(
                    color: Colors.white, fontSize: 17.0, letterSpacing: 1.0),
              ),
              onPressed: () {
                saveVideDetails();
              },
            ),
          ],
        ),
      ),
    );
  }
}
