import 'package:flutter/material.dart';
import 'package:social/Widgets/header.dart';
import 'package:social/Widgets/post.dart';
import 'package:social/Widgets/progress.dart';

import 'home.dart';

class PostScreen extends StatelessWidget {
  final String userId;
  final String postId;

  PostScreen({this.userId, this.postId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: postsRef.doc(userId).collection('userPosts').doc(postId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        //print(postId);
        Post post = Post.fromDocument(snapshot.data);
        print(snapshot.data['postId']);
        return Center(
          child: Scaffold(
            appBar: AppBar(
              title: Text(post.description),
              leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
            ),
            body: ListView(
              children: <Widget>[
                Container(
                  child: post,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
