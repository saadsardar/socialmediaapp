import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social/Models/user.dart';
import 'package:social/Pages/search.dart';
// import 'package:social/Widgets/header.dart';
import 'package:social/Widgets/post.dart';
import 'package:social/Widgets/progress.dart';

import 'home.dart';

final usersRef = FirebaseFirestore.instance.collection('users');

class Bar extends StatefulWidget {
  final User currentUser;

  Bar({this.currentUser});

  @override
  _BarState createState() => _BarState();
}

class _BarState extends State<Bar> {
  List<Post> posts = [];
  List<String> followingList = [];
  bool isInit = false;
  // List<String> postsList = [];

  @override
  void initState() {
    super.initState();
    //getBar();
    // getPosts();
    // getFollowing();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // getBar() async {
  //   QuerySnapshot snapshot = await BarRef
  //       .doc(widget.currentUser.id)
  //       .collection('BarPosts')
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
    // setState(() {
    followingList = snapshot.docs.map((doc) => doc.id).toList();
    // });
  }

  getPosts() async {
    // posts.clear();
    List<Post> posts1 = [];
    print("In getpost");
    final snap = await FirebaseFirestore.instance.collection('users').get();
    // QuerySnapshot snapshot = await postsRef.get();
    final data = snap.docs;
    // print('Data : $data');

    for (var e in data) {
      final id = e.id;
      // print("id is $id");
      QuerySnapshot snapshot2 =
          await postsRef.doc(id).collection('userPosts').get();
      if (snapshot2 != null) {
        final data2 = snapshot2.docs;
        data2.forEach((e) {
          //var map= e.data();
          posts1.add(Post.fromDocument(e));
          // print(posts);
        });
      }
    }
    // isInit = true;
    //   e.data();
    // List<Post> posts1 =
    //     snapshot2.docs.map((doc) => Post.fromDocument(doc)).toList();

    // posts1.forEach((e) {
    //   if(e != null)
    //   {posts.add(e);
    //   print(e);}
    // });
    //print(posts1);
    // posts.add(posts1);
    // this.posts += posts1;
    //}
    //});
    // var map = e.data();
    //   },
    // );
    isInit = true;
    setState(() {
      this.posts = posts1;
    });
  }

  //.doc(currentUser.id)
  // .collection('userFollowing')
  // .get();
  // setState(() {
  //   postsList = snapshot.docs.map((doc) => doc.id).toList();
  // });

  //orignal buildBar
  // buildBar() {
  //   if (posts == null) {
  //     return circularProgress();
  //   } else if (posts.isEmpty) {
  //     return buildUsersToFollow();
  //   } else {
  //     return ListView(children: posts);
  //   }
  // }
  buildBar() {
    if (posts.isEmpty && !isInit) {
      return circularProgress();
    } else if (posts.isEmpty && isInit) {
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
    if (!isInit) {
      print('Not isinit');
      getPosts();
      getFollowing();
    }
    return Scaffold(
      // appBar: header(context, isAppTitle: true),
      body: buildBar(),
    );
    // RefreshIndicator(
    //     onRefresh: () => getPosts(), child: buildBar()));
  }
}
