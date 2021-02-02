import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social/Pages/post_screen.dart';
import 'package:social/Pages/profile.dart';
// import 'package:social/Widgets/header.dart';
import 'package:social/Widgets/progress.dart';

import 'package:timeago/timeago.dart' as timeago;

import 'home.dart';

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  // ignore: missing_return
  Future<List<ActivityFeedItem>> getActivityFeed() async {
    List<ActivityFeedItem> feedItems = [];
    try {
      QuerySnapshot snapshot = await activityFeedRef
          .doc(currentUser.id)
          .collection('feedItems')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      //var data = snapshot.docs;

      snapshot.docs.forEach((doc) {
        //print('${doc.data()}');
        //print("Yahan phans raha hai");
        feedItems.add(ActivityFeedItem.fromDocument(doc));
        //print(feedItems);
      });
      // return feedItems;
    } catch (e) {
      print(e);
    }
    return feedItems;
    // data.forEach((doc) {
    //   feedItems.add(ActivityFeedItem.fromDocument(doc));
    //   // print('Activity Feed Item: ${doc.data}');
    // });
    // print("List is:");
    //print(feedItems);

    //return snapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Colors.orange,
      // appBar: header(context, titleText: "Activity Feed"),
      appBar: AppBar(
        title: Text('Notifications'),
        // leading: IconButton(
        //     icon: Icon(
        //       Icons.arrow_back_rounded,
        //       color: Colors.white,
        //     ),
        //     onPressed: () {
        //       Navigator.of(context).pop();
        //     }),
      ),
      body: Container(
          child: FutureBuilder(
        future: getActivityFeed(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // print('no Data');
            return circularProgress();
          }
          //return Text("data");
          if (snapshot.data == null) {
            return Center(
              child: Text('No Notifications!'),
            );
          }
          return ListView(
            children: snapshot.data,
          );
        },
      )),
    );
  }
}

Widget mediaPreview;
String activityItemText;

class ActivityFeedItem extends StatelessWidget {
  final String username;
  final String userId;
  final String type; // 'like', 'follow', 'comment'
  final String mediaUrl;
  final String postId;
  final String userProfileImg;
  final String commentData;
  final Timestamp timestamp;
  final String ownerId;

  ActivityFeedItem(
      {this.username,
      this.userId,
      this.type,
      this.mediaUrl,
      this.postId,
      this.userProfileImg,
      this.commentData,
      this.timestamp,
      this.ownerId});

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    //print('${doc['username']}');
    return ActivityFeedItem(
      username: doc['username'],
      userId: doc['userId'],
      type: doc['type'],
      postId: doc['postId'],
      userProfileImg: doc['userProfileImg'],
      commentData: doc['commentData'],
      timestamp: doc['timestamp'],
      mediaUrl: doc['mediaUrl'],
      ownerId: doc['ownerId'],
    );
  }
  showPost(context) {
    print('Sending $userId & $postId');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          postId: postId,
          userId: ownerId,
        ),
      ),
    );
  }

  configureMediaPreview(context) {
    if (type == "like" || type == 'comment') {
      mediaPreview = GestureDetector(
        onTap: () => showPost(context),
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: CachedNetworkImageProvider(mediaUrl),
                  ),
                ),
              )),
        ),
      );
    } else {
      mediaPreview = null;
    }

    if (type == 'like') {
      activityItemText = "liked your post";
    } else if (type == 'follow') {
      activityItemText = "is following you";
    } else if (type == 'comment') {
      activityItemText = 'replied: $commentData';
    } else {
      activityItemText = "Error: Unknown type '$type'";
    }
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Colors.white54,
        child: ListTile(
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: userId),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: username,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ' $activityItemText',
                    ),
                  ]),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userProfileImg),
          ),
          subtitle: Text(
            timeago.format(timestamp.toDate()),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: mediaUrl == null ? null : mediaPreview,
        ),
      ),
    );
  }
}

showProfile(BuildContext context, {String profileId}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Profile(
        profileId: profileId,
      ),
    ),
  );
}
