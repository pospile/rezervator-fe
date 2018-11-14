import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:rezervator/sign_button.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:rezervator/calendar.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn();

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Demo',
      home: MyHomePage(title: 'Firebase Auth Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<String> _message = Future<String>.value('');
  String _photoUrl =
      'https://firebasestorage.googleapis.com/v0/b/rezervator-a6964.appspot.com/o/user.png?alt=media&token=f7f54368-32d8-4e0f-8f4e-65734b55b4be';
  bool showIndicator = false;
  Widget loadingWidget = LinearProgressIndicator();
  Future<RemoteConfig> remoteConfig = RemoteConfig.instance;

  _MyHomePageState() {
    Firestore firestore = Firestore.instance;
    firestore.settings(timestampsInSnapshotsEnabled: true);

    FirebaseAuth.instance.currentUser().then((user) {
      if (user != null) {
        debugPrint(user.photoUrl);
        setState(() {
          _finishLoginProcess(user);
        });
      } else {
        setState(() {
          debugPrint('Prosím přihlašte se');
          _message = Future<String>.value('Prosím přihlašte se');
        });
      }
    });
  }

  Future<bool> _fetchRemoteConfig() async {
    await remoteConfig.then((remote) {
      remote.fetch(expiration: const Duration(hours: 1));
      remote.activateFetched();
      return remote.getBool('appRunning');
    });
  }


  Future<String> _startFacebookLogin() async {
    final FacebookLoginResult fbUser = await FacebookLogin()
        .logInWithReadPermissions(['email', 'public_profile']);
    final FacebookAccessToken fbAuth = await fbUser.accessToken;
    final FirebaseUser user = await _auth.signInWithFacebook(
      accessToken: fbAuth.token,
    );
    assert(user.email != null);
    assert(user.displayName != null);
    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    _auth.currentUser().then((FirebaseUser user) {
      _finishLoginProcess(user);
      return 'signInWithFacebook succeeded: $user';
    });
  }

  Future<String> _startGoogleLogin() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final FirebaseUser user = await _auth.signInWithGoogle(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    assert(user.email != null);
    assert(user.displayName != null);
    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    _auth.currentUser().then((FirebaseUser user) {
      _finishLoginProcess(user);
      return 'signInWithGoogle succeeded: $user';
    });
  }

  void _finishLoginProcess(FirebaseUser user) {
    Firestore.instance
        .collection('user')
        .where("email", isEqualTo: user.email)
        .snapshots()
        .listen((data) {
          debugPrint(data.documents.length.toString());
          if (data.documents.length != 0) {
            data.documents.forEach((doc) {
              print(doc.documentID);
            });
          }
          else {
            Firestore.instance.collection('user').document()
                .setData({ 'email': user.email, 'displayName': user.displayName, 'photoUrl': user.photoUrl, 'emailVerified': user.isEmailVerified, 'provider': user.providerId});
          }
        });

    setState(() {
      _photoUrl = user.photoUrl;
      _message = Future<String>.value('');
      showIndicator = true;

      new Timer(new Duration(seconds: 3), () {
        Route route = MaterialPageRoute(builder: (context) => Calendar());
        Navigator.pushReplacement(context, route);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.white,
        title: Text(
          'Rezervator',
          style: Theme.of(context).textTheme.headline,
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          showIndicator ? loadingWidget : Text(''),
          Padding(
            padding: EdgeInsets.only(
                top: 20.0, bottom: showIndicator ? 150.0 : 5.0, left: 10.0),
          ),
          Image.network(
            _photoUrl,
            height: 100.0,
            fit: BoxFit.fitHeight,
          ),
          showIndicator
              ? Text('')
              : Padding(
                  padding: EdgeInsets.only(top: 130.0),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        MaterialButton(
                          child:
                              button('Přihlásit s Google', 'assets/google.png'),
                          onPressed: () {
                            setState(() {
                              print('Sign in succesfull');
                              _startGoogleLogin();
                            });
                          },
                          color: Colors.white,
                        ),
                        MaterialButton(
                          child: button('nebo Facebook', 'assets/facebook.png',
                              Colors.white),
                          onPressed: () {
                            setState(() {
                              print('Sign in succesfull');
                              _startFacebookLogin();
                            });
                          },
                          color: Color.fromRGBO(58, 89, 152, 1.0),
                        ),
                      ],
                    ),
                  ),
                ),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 30.0),
              child: FutureBuilder<String>(
                  future: _message,
                  builder: (_, AsyncSnapshot<String> snapshot) {
                    return Text(snapshot.data ?? '',
                        style: const TextStyle(
                            color: Color.fromARGB(255, 0, 155, 0)));
                  })),
        ],
      ),
    );
  }
}
