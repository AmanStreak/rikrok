// import 'package:flutter/material.dart';
// import 'package:tik_tok_ui/home.dart';

// void main() => runApp(MyApp());

// class MyApp extends StatelessWidget {
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//          // Uncomment in phase 3 to apply white to text
//         textTheme: Theme.of(context).textTheme.apply(
//           bodyColor: Colors.white,
//           displayColor: Colors.white
//         ),
//       ),
//       home: Home(),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:tik_tok_ui/login_signup/login.dart';
import 'package:tik_tok_ui/login_signup/pages/login.page.dart';
import 'package:tik_tok_ui/video/video.dart';

import 'oauth.dart';
// import 'package:tik_tok_ui/login_signup/pages/login.page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CameraExampleHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// LoginPage()
