import 'dart:async';
import 'dart:convert';

import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:amazon_cognito_identity_dart_2/sig_v4.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Setup AWS User Pool Id & Client Id settings here:
const _awsUserPoolId = 'ap-southeast-1_xxxxxxxxx';
const _awsClientId = '24ic538t5p2j5vtet22tcnk94r';

const _identityPoolId = 'ap-southeast-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';

// Setup endpoints here:
const _region = 'ap-southeast-1';
const _endpoint =
    'https://xxxxxxxxxx.execute-api.ap-southeast-1.amazonaws.com/dev';

final userPool = CognitoUserPool(_awsUserPoolId, _awsClientId);

/// Extend CognitoStorage with Shared Preferences to persist account
/// login sessions
class Storage extends CognitoStorage {
  final SharedPreferences _prefs;
  Storage(this._prefs);

  @override
  Future getItem(String key) async {
    String item;
    try {
      item = json.decode(_prefs.getString(key)) as String;
    } catch (e) {
      return null;
    }
    return item;
  }

  @override
  Future setItem(String key, dynamic value) async {
    await _prefs.setString(key, json.encode(value));
    return getItem(key);
  }

  @override
  Future removeItem(String key) async {
    final item = getItem(key);
    if (item != null) {
      await _prefs.remove(key);
      return item;
    }
    return null;
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}

class Counter {
  int count;
  Counter(this.count);

  factory Counter.fromJson(json) {
    return Counter(json['count'] as int);
  }
}

class User {
  String email;
  String name;
  String password;
  bool confirmed = false;
  bool hasAccess = false;

  User({this.email, this.name});

  /// Decode user from Cognito User Attributes
  factory User.fromUserAttributes(List<CognitoUserAttribute> attributes) {
    final user = User();
    attributes.forEach((attribute) {
      if (attribute.getName() == 'email') {
        user.email = attribute.getValue();
      } else if (attribute.getName() == 'name') {
        user.name = attribute.getValue();
      }
    });
    return user;
  }
}

class CounterService {
  AwsSigV4Client awsSigV4Client;
  CounterService(this.awsSigV4Client);

  /// Retrieve user's previous count from Lambda + DynamoDB
  Future<Counter> getCounter() async {
    final signedRequest =
        SigV4Request(awsSigV4Client, method: 'GET', path: '/counter');
    final response =
        await http.get(signedRequest.url, headers: signedRequest.headers);
    return Counter.fromJson(json.decode(response.body));
  }

  /// Increment user's count in DynamoDB
  Future<Counter> incrementCounter() async {
    final signedRequest =
        SigV4Request(awsSigV4Client, method: 'PUT', path: '/counter');
    final response =
        await http.put(signedRequest.url, headers: signedRequest.headers);
    return Counter.fromJson(json.decode(response.body));
  }
}

class UserService {
  final CognitoUserPool _userPool;
  CognitoUser _cognitoUser;
  CognitoUserSession _session;
  UserService(this._userPool);
  CognitoCredentials credentials;

  /// Initiate user session from local storage if present
  Future<bool> init() async {
    final prefs = await SharedPreferences.getInstance();
    final storage = Storage(prefs);
    _userPool.storage = storage;

    _cognitoUser = await _userPool.getCurrentUser();
    if (_cognitoUser == null) {
      return false;
    }
    _session = await _cognitoUser.getSession();
    return _session.isValid();
  }

  /// Get existing user from session with his/her attributes
  Future<User> getCurrentUser() async {
    if (_cognitoUser == null || _session == null) {
      return null;
    }
    if (!_session.isValid()) {
      return null;
    }
    final attributes = await _cognitoUser.getUserAttributes();
    if (attributes == null) {
      return null;
    }
    final user = User.fromUserAttributes(attributes);
    user.hasAccess = true;
    return user;
  }

  /// Retrieve user credentials -- for use with other AWS services
  Future<CognitoCredentials> getCredentials() async {
    if (_cognitoUser == null || _session == null) {
      return null;
    }
    credentials = CognitoCredentials(_identityPoolId, _userPool);
    await credentials.getAwsCredentials(_session.getIdToken().getJwtToken());
    return credentials;
  }

  /// Login user
  Future<User> login(String email, String password) async {
    _cognitoUser = CognitoUser(email, _userPool, storage: _userPool.storage);

    final authDetails = AuthenticationDetails(
      username: email,
      password: password,
    );

    bool isConfirmed;
    try {
      _session = await _cognitoUser.authenticateUser(authDetails);
      isConfirmed = true;
    } on CognitoClientException catch (e) {
      if (e.code == 'UserNotConfirmedException') {
        isConfirmed = false;
      } else {
        rethrow;
      }
    }

    if (!_session.isValid()) {
      return null;
    }

    final attributes = await _cognitoUser.getUserAttributes();
    final user = User.fromUserAttributes(attributes);
    user.confirmed = isConfirmed;
    user.hasAccess = true;

    return user;
  }

  /// Confirm user's account with confirmation code sent to email
  Future<bool> confirmAccount(String email, String confirmationCode) async {
    _cognitoUser = CognitoUser(email, _userPool, storage: _userPool.storage);

    return await _cognitoUser.confirmRegistration(confirmationCode);
  }

  /// Resend confirmation code to user's email
  Future<void> resendConfirmationCode(String email) async {
    _cognitoUser = CognitoUser(email, _userPool, storage: _userPool.storage);
    await _cognitoUser.resendConfirmationCode();
  }

  /// Check if user's current session is valid
  Future<bool> checkAuthenticated() async {
    if (_cognitoUser == null || _session == null) {
      return false;
    }
    return _session.isValid();
  }

  /// Sign upuser
  Future<User> signUp(String email, String password, String name) async {
    CognitoUserPoolData data;
    final userAttributes = [
      AttributeArg(name: 'name', value: name),
    ];
    data =
        await _userPool.signUp(email, password, userAttributes: userAttributes);

    final user = User();
    user.email = email;
    user.name = name;
    user.confirmed = data.userConfirmed;

    return user;
  }

  Future<void> signOut() async {
    if (credentials != null) {
      await credentials.resetAwsCredentials();
    }
    if (_cognitoUser != null) {
      return _cognitoUser.signOut();
    }
  }
}

void main() => runApp(SecureCounterApp());

class SecureCounterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cognito on Flutter',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const HomePage(title: 'Cognito on Flutter'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding:
                  const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
              width: screenSize.width,
              child: RaisedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpScreen()),
                  );
                },
                color: Colors.blue,
                child: const Text(
                  'Sign Up',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
              width: screenSize.width,
              child: RaisedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ConfirmationScreen()),
                  );
                },
                color: Colors.blue,
                child: const Text(
                  'Confirm Account',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
              width: screenSize.width,
              child: RaisedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                color: Colors.blue,
                child: const Text(
                  'Login',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
              width: screenSize.width,
              child: RaisedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SecureCounterScreen()),
                  );
                },
                color: Colors.blue,
                child: const Text(
                  'Secure Counter',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  User _user = User();
  final userService = UserService(userPool);

  Future<void> submit(BuildContext context) async {
    _formKey.currentState.save();

    String message;
    bool signUpSuccess = false;
    try {
      _user = await userService.signUp(_user.email, _user.password, _user.name);
      signUpSuccess = true;
      message = 'User sign up successful!';
    } on CognitoClientException catch (e) {
      if (e.code == 'UsernameExistsException' ||
          e.code == 'InvalidParameterException' ||
          e.code == 'ResourceNotFoundException') {
        message = e.message;
      } else {
        message = 'Unknown client error occurred';
      }
    } catch (e) {
      message = 'Unknown error occurred';
    }

    final snackBar = SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {
          if (signUpSuccess) {
            Navigator.pop(context);
            if (!_user.confirmed) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ConfirmationScreen(email: _user.email)),
              );
            }
          }
        },
      ),
      duration: const Duration(seconds: 30),
    );

    Scaffold.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Builder(
        builder: (BuildContext context) {
          return Form(
            key: _formKey,
            child: ListView(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.account_box),
                  title: TextFormField(
                    decoration: const InputDecoration(labelText: 'Name'),
                    onSaved: (String name) {
                      _user.name = name;
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: TextFormField(
                    decoration: const InputDecoration(
                        hintText: 'example@inspire.my', labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (String email) {
                      _user.email = email;
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'Password!',
                    ),
                    obscureText: true,
                    onSaved: (String password) {
                      _user.password = password;
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20.0),
                  width: screenSize.width,
                  margin: const EdgeInsets.only(
                    top: 10.0,
                  ),
                  child: RaisedButton(
                    onPressed: () {
                      submit(context);
                    },
                    color: Colors.blue,
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({Key key, this.email}) : super(key: key);

  final String email;

  @override
  _ConfirmationScreenState createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String confirmationCode;
  final User _user = User();
  final _userService = UserService(userPool);

  Future<void> _submit(BuildContext context) async {
    _formKey.currentState.save();
    bool accountConfirmed;
    String message;
    try {
      accountConfirmed =
          await _userService.confirmAccount(_user.email, confirmationCode);
      message = 'Account successfully confirmed!';
    } on CognitoClientException catch (e) {
      if (e.code == 'InvalidParameterException' ||
          e.code == 'CodeMismatchException' ||
          e.code == 'NotAuthorizedException' ||
          e.code == 'UserNotFoundException' ||
          e.code == 'ResourceNotFoundException') {
        message = e.message;
      } else {
        message = 'Unknown client error occurred';
      }
    } catch (e) {
      message = 'Unknown error occurred';
    }

    final snackBar = SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {
          if (accountConfirmed) {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => LoginScreen(email: _user.email)),
            );
          }
        },
      ),
      duration: const Duration(seconds: 30),
    );

    Scaffold.of(context).showSnackBar(snackBar);
  }

  Future<void> _resendConfirmation(BuildContext context) async {
    _formKey.currentState.save();
    String message;
    try {
      await _userService.resendConfirmationCode(_user.email);
      message = 'Confirmation code sent to ${_user.email}!';
    } on CognitoClientException catch (e) {
      if (e.code == 'LimitExceededException' ||
          e.code == 'InvalidParameterException' ||
          e.code == 'ResourceNotFoundException') {
        message = e.message;
      } else {
        message = 'Unknown client error occurred';
      }
    } catch (e) {
      message = 'Unknown error occurred';
    }

    final snackBar = SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {},
      ),
      duration: const Duration(seconds: 30),
    );

    Scaffold.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Account'),
      ),
      body: Builder(
          builder: (BuildContext context) => Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: TextFormField(
                        initialValue: widget.email,
                        decoration: const InputDecoration(
                            hintText: 'example@inspire.my', labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        onSaved: (String email) {
                          _user.email = email;
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'Confirmation Code'),
                        onSaved: (String code) {
                          confirmationCode = code;
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      width: screenSize.width,
                      margin: const EdgeInsets.only(
                        top: 10.0,
                      ),
                      child: RaisedButton(
                        onPressed: () {
                          _submit(context);
                        },
                        color: Colors.blue,
                        child: const Text(
                          'Submit',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    Center(
                      child: InkWell(
                        onTap: () {
                          _resendConfirmation(context);
                        },
                        child: const Text(
                          'Resend Confirmation Code',
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key key, this.email}) : super(key: key);

  final String email;

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _userService = UserService(userPool);
  User _user = User();
  bool _isAuthenticated = false;

  Future<UserService> _getValues() async {
    await _userService.init();
    _isAuthenticated = await _userService.checkAuthenticated();
    return _userService;
  }

  Future<void> submit(BuildContext context) async {
    _formKey.currentState.save();
    String message;
    try {
      _user = await _userService.login(_user.email, _user.password);
      message = 'User sucessfully logged in!';
      if (!_user.confirmed) {
        message = 'Please confirm user account';
      }
    } on CognitoClientException catch (e) {
      if (e.code == 'InvalidParameterException' ||
          e.code == 'NotAuthorizedException' ||
          e.code == 'UserNotFoundException' ||
          e.code == 'ResourceNotFoundException') {
        message = e.message;
      } else {
        message = 'An unknown client error occured';
      }
    } catch (e) {
      message = 'An unknown error occurred';
    }
    final snackBar = SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () async {
          if (_user.hasAccess) {
            Navigator.pop(context);
            if (!_user.confirmed) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ConfirmationScreen(email: _user.email)),
              );
            }
          }
        },
      ),
      duration: const Duration(seconds: 30),
    );

    Scaffold.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getValues(),
        builder: (context, AsyncSnapshot<UserService> snapshot) {
          if (snapshot.hasData) {
            if (_isAuthenticated) {
              return const SecureCounterScreen();
            }
            final Size screenSize = MediaQuery.of(context).size;
            return Scaffold(
              appBar: AppBar(
                title: const Text('Login'),
              ),
              body: Builder(
                builder: (BuildContext context) {
                  return Form(
                    key: _formKey,
                    child: ListView(
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.email),
                          title: TextFormField(
                            initialValue: widget.email,
                            decoration: const InputDecoration(
                                hintText: 'example@inspire.my',
                                labelText: 'Email'),
                            keyboardType: TextInputType.emailAddress,
                            onSaved: (String email) {
                              _user.email = email;
                            },
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.lock),
                          title: TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Password'),
                            obscureText: true,
                            onSaved: (String password) {
                              _user.password = password;
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(20.0),
                          width: screenSize.width,
                          margin: const EdgeInsets.only(
                            top: 10.0,
                          ),
                          child: RaisedButton(
                            onPressed: () {
                              submit(context);
                            },
                            color: Colors.blue,
                            child: const Text(
                              'Login',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }
          return Scaffold(appBar: AppBar(title: const Text('Loading...')));
        });
  }
}

class SecureCounterScreen extends StatefulWidget {
  const SecureCounterScreen({Key key}) : super(key: key);

  @override
  _SecureCounterScreenState createState() => _SecureCounterScreenState();
}

class _SecureCounterScreenState extends State<SecureCounterScreen> {
  final _userService = UserService(userPool);
  CounterService _counterService;
  AwsSigV4Client _awsSigV4Client;
  User _user = User();
  Counter _counter = Counter(0);
  bool _isAuthenticated = false;

  Future<void> _incrementCounter() async {
    final counter = await _counterService.incrementCounter();
    setState(() {
      _counter = counter;
    });
  }

  Future<UserService> _getValues(BuildContext context) async {
    try {
      await _userService.init();
      _isAuthenticated = await _userService.checkAuthenticated();
      if (_isAuthenticated) {
        // get user attributes from cognito
        _user = await _userService.getCurrentUser();

        // get session credentials
        final credentials = await _userService.getCredentials();
        _awsSigV4Client = AwsSigV4Client(
            credentials.accessKeyId, credentials.secretAccessKey, _endpoint,
            region: _region, sessionToken: credentials.sessionToken);

        // get previous count
        _counterService = CounterService(_awsSigV4Client);
        _counter = await _counterService.getCounter();
      }
      return _userService;
    } on CognitoClientException catch (e) {
      if (e.code == 'NotAuthorizedException') {
        await _userService.signOut();
        Navigator.pop(context);
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getValues(context),
        builder: (context, AsyncSnapshot<UserService> snapshot) {
          if (snapshot.hasData) {
            if (!_isAuthenticated) {
              return const LoginScreen();
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('Secure Counter'),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Welcome ${_user.name}!',
                      style: Theme.of(context).textTheme.headline4,
                    ),
                    const Divider(),
                    const Text(
                      'You have pushed the button this many times:',
                    ),
                    Text(
                      '${_counter.count}',
                      style: Theme.of(context).textTheme.headline4,
                    ),
                    const Divider(),
                    Center(
                      child: InkWell(
                        onTap: () {
                          _userService.signOut();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  if (snapshot.hasData) {
                    _incrementCounter();
                  }
                },
                tooltip: 'Increment',
                child: const Icon(Icons.add),
              ),
            );
          }
          return Scaffold(appBar: AppBar(title: const Text('Loading...')));
        });
  }
}