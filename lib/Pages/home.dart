import 'dart:io';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:social/Models/user.dart' as Userclass;
import 'package:social/Pages/ChatScreen.dart';
import 'package:social/Pages/LiveUsers.dart';
import 'package:social/Pages/VideoCall.dart';
import 'package:social/Pages/activity_feed.dart';
import 'package:social/Pages/profile.dart';
import 'package:social/Pages/upload.dart';
import 'FrontPage.dart';
import 'create_account.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final StorageReference storageRef = FirebaseStorage.instance.ref();
final usersRef = FirebaseFirestore.instance.collection('users');
final postsRef = FirebaseFirestore.instance.collection('posts');
final commentsRef = FirebaseFirestore.instance.collection('comments');
final activityFeedRef = FirebaseFirestore.instance.collection('feed');
final followingRef = FirebaseFirestore.instance.collection('following');
final followersRef = FirebaseFirestore.instance.collection('followers');
final timelineRef = FirebaseFirestore.instance.collection('timeline');
final DateTime timestamp = DateTime.now();
Userclass.User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  bool isAuth = false;
  bool isInit = false;
  PageController pageController;
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    super.initState();
    googleSignIn.onCurrentUserChanged.listen(
      (account) {
        if (account != null) {
          // setState(() {
          // print("user $account");
          isAuth = true;
          isInit = true;
          // });
        } else {
          setState(() {
            isInit = true;
            isAuth = false;
          });
        }
      },
    );
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (err) {
      print('Error signing in: $err');
      setState(() {
        isInit = true;
      });
    });
    // Reauthenticate user when app is opened
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn(account);
    }).catchError((err) {
      print('Error signing in: $err');
      setState(() {
        isInit = true;
      });
    });
  }

  handleSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      await createUserInFirestore();
      setState(() {
        isInit = true;
        isAuth = true;
      });
      configurePushNotifications();
    } else {
      setState(() {
        isInit = true;
        isAuth = false;
      });
    }
  }

  configurePushNotifications() {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if (Platform.isIOS) getiOSPermission();

    _firebaseMessaging.getToken().then((token) {
      print("Firebase Messaging Token: $token\n");
      usersRef.doc(user.id).update({"androidNotificationToken": token});
    });

    snackbarFunction(String body, String type, Map<String, dynamic> message) {
      print("Notification shown!");
      SnackBar snackbar = SnackBar(
        content: Text(
          body,
          overflow: TextOverflow.ellipsis,
        ),
        action: type == 'activityFeedItem'
            ? null
            : SnackBarAction(
                label: type == 'chat' ? 'view' : 'receive',
                onPressed: () async {
                  if (type == 'chat') {
                    final senderUserId = message['data']['senderUserId'];
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => ChatScreen(user.id, senderUserId)));
                  } else {
                    final channelName = message['data']['channelName'];
                    DocumentSnapshot doc = await usersRef.doc(user.id).get();
                    currentUser = Userclass.User.fromDocument(doc);
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => VideoCall(
                              channelName: channelName,
                              currentUser: currentUser,
                              receiverUserId: user.id,
                              role: ClientRole.Broadcaster,
                            )));
                  }
                }),
      );
      _scaffoldKey.currentState.showSnackBar(snackbar);
    }

    _firebaseMessaging.configure(
      onLaunch: (Map<String, dynamic> message) async {
        print("on message: $message\n");
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];
        final String type = message['data']['type'];
        if (recipientId == user.id) {
          snackbarFunction(body, type, message);
        }
        print("Notification NOT shown");
      },
      onResume: (Map<String, dynamic> message) async {
        print("on message: $message\n");
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];
        final String type = message['data']['type'];

        if (recipientId == user.id) {
          snackbarFunction(body, type, message);
        }
        print("Notification NOT shown");
      },
      onMessage: (Map<String, dynamic> message) async {
        print("on message: $message\n");
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];
        final String type = message['data']['type'];
        if (recipientId == user.id) {
          snackbarFunction(body, type, message);
        }
        print("Notification NOT shown");
      },
    );
  }

  getiOSPermission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(alert: true, badge: true, sound: true));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print("Settings registered: $settings");
    });
  }

  createUserInFirestore() async {
    print("in create");
    // 1) check if user exists in users collection in database (according to their id)
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.doc(user.id).get();

    if (!doc.exists) {
      // 2) if the user doesn't exist, then we want to take them to the create account page
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));

      // 3) get username from create account, use it to make new user document in users collection
      usersRef.doc(user.id).set({
        "id": user.id,
        "username": username,
        "photoUrl": user.photoUrl,
        "email": user.email,
        "displayName": user.displayName,
        "bio": "",
        "timestamp": timestamp
      });
      doc = await usersRef.doc(user.id).get();
    }
    currentUser = Userclass.User.fromDocument(doc);
    // print(currentUser);
    // print(currentUser.username);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  login() {
    googleSignIn.signIn();
  }

  logout() {
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInCubic,
    );
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          LiveUsers(currentUser),
          FrontPage(currentUser),
          Upload(currentUser: currentUser),
          ActivityFeed(),
          Profile(
            profileId: currentUser?.id,
          ),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
          currentIndex: pageIndex,
          onTap: onTap,
          activeColor: Theme.of(context).primaryColor,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.whatshot),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.stars_sharp),
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.add_a_photo_rounded,
                size: 35.0,
              ),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_active),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
            ),
          ]),
    );
  }

  Widget buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                )),
            // Text(
            //   'Liveo',
            //   style: TextStyle(
            //     color: Colors.white,
            //     fontSize: 60.0,
            //   ),
            // ),
            Divider(),
            GestureDetector(
              child: isInit
                  ? Container(
                      width: 300,
                      height: 50,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                              'assets/images/google_signin_button.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  : Container(),
              onTap: login,
            ),
          ],
        ),
      ),
    );
  }

  Scaffold splashScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 15),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('IsInit: $isInit  isAuth: $isAuth');
    return
        // !isInit
        //     ? splashScreen()
        // :
        isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
