import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social/Models/user.dart';
import 'package:social/Pages/search.dart';
// import 'package:social/Widgets/header.dart';
import 'package:social/Widgets/post.dart';
import 'package:social/Widgets/progress.dart';

import 'home.dart';

final usersRef = FirebaseFirestore.instance.collection('users');

class Timeline extends StatefulWidget {
  final User currentUser;

  Timeline({this.currentUser});

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts;
  List<String> followingList = [];
  // List<String> postsList = [];

  @override
  void initState() {
    super.initState();
    //getTimeline();
    getPosts();
    getFollowing();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // getTimeline() async {
  //   QuerySnapshot snapshot = await timelineRef
  //       .doc(widget.currentUser.id)
  //       .collection('timelinePosts')
  //       .orderBy('timestamp', descending: true)
  //       .get();
  //   List<Post> posts =
  //       snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
  //   setState(() {
  //     this.posts = posts;
  //   });
  // }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .doc(currentUser.id)
        .collection('userFollowing')
        .get();
    setState(() {
      followingList = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  getPosts() async {
     print("1111");
    QuerySnapshot snapshot = await postsRef.get();
    final data = snapshot.docs;
    data.forEach(
      (e) async {
        var id = e.id;
        //print("id is $id");
        QuerySnapshot snapshot2 =
            await postsRef.doc(id).collection('userPosts').get();
        //final data2 = snapshot2.docs;
        // data.forEach((e) {
        //   e.data();
        List<Post> 
        posts =
            snapshot2.docs.map((doc) => Post.fromDocument(doc)).toList();
        setState(() {
          this.posts = posts;
        });
        //});
        // var map = e.data();
      },
    );
  }

  //.doc(currentUser.id)
  // .collection('userFollowing')
  // .get();
  // setState(() {
  //   postsList = snapshot.docs.map((doc) => doc.id).toList();
  // });

  buildTimeline() {
    if (posts == null) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return buildUsersToFollow();
    } else {
      return ListView(children: posts);
    }
  }

  buildUsersToFollow() {
    return StreamBuilder(
      stream:
          usersRef.orderBy('timestamp', descending: true).limit(30).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> userResults = [];
        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocument(doc);
          final bool isAuthUser = currentUser.id == user.id;
          final bool isFollowingUser = followingList.contains(user.id);
          // remove auth user from recommended list
          if (isAuthUser) {
            return;
          } else if (isFollowingUser) {
            return;
          } else {
            UserResult userResult = UserResult(user);
            userResults.add(userResult);
          }
        });
        return Container(
          color: Theme.of(context).accentColor.withOpacity(0.2),
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.person_add,
                      color: Theme.of(context).primaryColor,
                      size: 30.0,
                    ),
                    SizedBox(
                      width: 8.0,
                    ),
                    Text(
                      "Users to Follow",
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 30.0,
                      ),
                    ),
                  ],
                ),
              ),
              Column(children: userResults),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
        // appBar: header(context, isAppTitle: true),
        body: RefreshIndicator(
            onRefresh: () => getPosts(), child: buildTimeline()));
  }
}
