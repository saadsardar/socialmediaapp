import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import "package:flutter/material.dart";
import 'package:image_picker/image_picker.dart';
import 'package:social/Models/user.dart';
import 'package:social/Widgets/progress.dart';

import 'home.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;

  EditProfile({this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  bool isLoading = false;
  User user;
  bool _displayNameValid = true;
  bool _usernameValid = true;
  bool _bioValid = true;
  File _pickedimage;
  ImagePicker _picker = ImagePicker();
  String dpurl = '';
  bool isSubmitting = false;

  Future _getImage() async {
    var pickedimagefile = await _picker.getImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 250,
    );
    setState(() {
      _pickedimage = File(pickedimagefile.path);
    });
  }

  Widget _imageField() {
    return Stack(
      children: <Widget>[
        CircleAvatar(
          backgroundColor: Theme.of(context).accentColor,
          backgroundImage: _pickedimage != null
              ? FileImage(_pickedimage)
              // : AssetImage('assets/images/logo.png'),
              : NetworkImage(user.photoUrl),
          // : CachedNetworkImage(imageUrl: user.photoUrl),
          radius: 60,
        ),
        Positioned(
          right: 0.0,
          bottom: 0.0,
          child: InkWell(
            child: Container(
              padding: EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(30),
              ),
              height: 35.0,
              width: 35.0,
              child: Icon(
                Icons.person_add_alt,
                color: Colors.white,
                size: 25,
              ),
            ),
            onTap: () async {
              await _getImage();
            },
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await usersRef.doc(widget.currentUserId).get();
    user = User.fromDocument(doc);
    displayNameController.text = user.displayName;
    bioController.text = user.bio;
    usernameController.text = user.username;
    setState(() {
      isLoading = false;
    });
  }

  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Text(
              "Display Name",
              style: TextStyle(color: Colors.grey),
            )),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            hintText: "Update Display Name",
            errorText: _displayNameValid ? null : "Display Name too short",
          ),
        )
      ],
    );
  }

  Column buildUserNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Text(
              "Username",
              style: TextStyle(color: Colors.grey),
            )),
        TextField(
          controller: usernameController,
          decoration: InputDecoration(
            hintText: "Update Display Name",
            errorText: _displayNameValid ? null : "Username too short",
          ),
        )
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Bio",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
            hintText: "Update Bio",
            errorText: _bioValid ? null : "Bio too long",
          ),
        )
      ],
    );
  }

  updateProfileData() async {
    setState(() {
      isSubmitting = true;
      displayNameController.text.trim().length < 3 ||
              displayNameController.text.isEmpty
          ? _displayNameValid = false
          : _displayNameValid = true;
      bioController.text.trim().length > 100
          ? _bioValid = false
          : _bioValid = true;
      usernameController.text.trim().length < 3 ||
              usernameController.text.isEmpty
          ? _usernameValid = false
          : _usernameValid = true;
    });

    if (_pickedimage != null) {
      final ref = FirebaseStorage.instance.ref().child('ProfilePic/${user.id}');
      await ref.putFile(_pickedimage).onComplete;
      dpurl = await ref.getDownloadURL();
    }

    if (_displayNameValid && _bioValid && _usernameValid) {
      await usersRef.doc(widget.currentUserId).update({
        "displayName": displayNameController.text,
        "bio": bioController.text,
        "username": usernameController.text,
        "photoUrl": dpurl == '' ? user.photoUrl : dpurl,
      });
      SnackBar snackbar = SnackBar(content: Text("Profile updated!"));
      _scaffoldKey.currentState.showSnackBar(snackbar);
    }
    setState(() {
      isSubmitting = false;
    });
  }

  logout() async {
    await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Edit'),
        leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            }),
      ),
      body: isLoading
          ? circularProgress()
          : ListView(
              children: <Widget>[
                Container(
                  child: Column(
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.only(
                            top: 16.0,
                            bottom: 8.0,
                          ),
                          child: _imageField()),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: <Widget>[
                            buildDisplayNameField(),
                            buildBioField(),
                            buildBioField(),
                          ],
                        ),
                      ),
                      isSubmitting
                          ? CircularProgressIndicator()
                          : RaisedButton(
                              color: Theme.of(context).primaryColor,
                              onPressed: updateProfileData,
                              child: Text(
                                "Update Profile",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.0,
                                  // fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                      // Padding(
                      //   padding: EdgeInsets.all(16.0),
                      //   child: FlatButton.icon(
                      //     onPressed: logout,
                      //     icon: Icon(Icons.cancel, color: Colors.red),
                      //     label: Text(
                      //       "Logout",
                      //       style: TextStyle(color: Colors.red, fontSize: 20.0),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
