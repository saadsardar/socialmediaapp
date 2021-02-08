import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social/Pages/home.dart';
import 'package:splashscreen/splashscreen.dart' as ss;

class SplashScreen extends StatefulWidget {
  static const routeName = '/splashScreen';

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    Future<Widget> wait5Sec() async {
      await Future.delayed(const Duration(seconds: 4));
      isLoggedIn = FirebaseAuth.instance.currentUser != null;
      return Future.value(
          // isLoggedIn ? HomePage() :
          Home());
    }

    return Scaffold(
      body: ss.SplashScreen(
        backgroundColor: Theme.of(context).primaryColor,
        navigateAfterFuture: wait5Sec(),
        image: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
        ),
        useLoader: false,
        photoSize: MediaQuery.of(context).size.width * 0.4,
      ),
    );
  }
}
