import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social/Pages/home.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Firestore.instance.settings(timestampsInSnapshotsEnabled: true).then((_) {
  //   print("Timestamps enabled in snapshots\n");
  // }, onError: (_) {
  //   print("Error enabling timestamps in snapshots\n");
  // });
  // FirebaseFirestore.instance.settings(timestampsInSnapshotsEnabled: true).then((_) {
  //   print("Timestamps enabled in snapshots\n");
  // }, onError: (_) {
  //   print("Error enabling timestamps in snapshots\n");
  // });
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseFirestore.instance.settings = Settings();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xffFF0E23),
        accentColor: Color(0xff757575),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'ProductSans',
      ),
      home: SafeArea(child: Home()),
    );
  }
}
