import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social/Models/user.dart';
import 'package:social/Pages/ChatScreen.dart';
import 'package:social/Pages/PaymentScreen.dart';
import 'package:social/Widgets/post.dart';
import 'package:social/Widgets/post_tile.dart';
import 'package:social/Widgets/progress.dart';
import 'edit_profile.dart';
import 'home.dart';

class Profile extends StatefulWidget {
  final String profileId;

  Profile({this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserId = currentUser?.id;
  String postOrientation = "grid";
  bool isLoading = false;
  bool isFollowing = false;
  int followerCount = 0;
  int followingCount = 0;
  int postCount = 0;
  List<Post> posts = [];

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(currentUserId)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .get();
    setState(() {
      followerCount = snapshot.docs.length;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .doc(widget.profileId)
        .collection('userFollowing')
        .get();
    setState(() {
      followingCount = snapshot.docs.length;
    });
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .doc(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .get();
    setState(() {
      isLoading = false;
      postCount = snapshot.docs.length;
      posts = snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditProfile(currentUserId: currentUserId)));
  }

  Container buildButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.35,
          height: 27.0,
          child: Text(
            text,
            style: TextStyle(
              color:
                  // isFollowing ? Colors.black :
                  Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollowing
                ? Theme.of(context).accentColor
                : Theme.of(context).primaryColor,
            // border: Border.all(
            //   color: isFollowing ? Colors.grey : Colors.blue,
            // ),
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
      ),
    );
  }

  profileOwnerItem(IconData icon, String text, Function func) {
    return GestureDetector(
      onTap: func,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        height: 50,
        color: Colors.grey[350],
        child: Row(
          children: [
            Icon(icon),
            SizedBox(width: 20),
            Text(text, style: TextStyle(fontSize: 17)),
            Spacer(),
            Icon(Icons.arrow_forward_ios_outlined),
          ],
        ),
      ),
    );
  }

  profileOwnerIconItem(IconData icon, Function func) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[350],
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 30,
        ),
        onPressed: func,
      ),
    );
  }

  buildProfileButton() {
    // viewing your own profile - should show edit profile button
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return Container(
        width: MediaQuery.of(context).size.width * 0.9,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            profileOwnerIconItem(Icons.message, () {
              // Navigator.of(context)
              //     .push(MaterialPageRoute(builder: (ctx) => ChatScreen()));
            }),
            profileOwnerIconItem(Icons.account_balance_wallet, () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (ctx) => PaymentScreen()));
            }),
            // profileOwnerIconItem(Icons.add_a_photo_rounded, () {
            //   Navigator.of(context).push(
            //     MaterialPageRoute(
            //       builder: (ctx) => Upload(
            //         currentUser: currentUser,
            //       ),
            //     ),
            //   );
            // }),
            profileOwnerIconItem(Icons.edit, editProfile),
            profileOwnerIconItem(Icons.exit_to_app, () async {
              await googleSignIn.signOut();
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => Home()));
            }),
          ],
        ),
        // child: Column(
        //   children: [
        //     profileOwnerItem(Icons.message, 'Messages', () {}),
        //     profileOwnerItem(Icons.account_balance_wallet, 'Wallet', () {}),
        //     profileOwnerItem(Icons.edit, 'Edit Profile', editProfile),
        //     profileOwnerItem(Icons.settings, 'Settings', editProfile),
        //   ],
        // ),
      );
    } else if (isFollowing) {
      return Row(
        children: [
          buildButton(
            text: "Unfollow",
            function: handleUnfollowUser,
          ),
          buildButton(
            text: "Message",
            function: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) =>
                      ChatScreen(currentUserId, widget.profileId)));
            },
          ),
        ],
      );
    } else if (!isFollowing) {
      return buildButton(
        text: "Follow",
        function: handleFollowUser,
      );
    }
  }

  handleUnfollowUser() {
    setState(() {
      isFollowing = false;
    });
    // remove follower
    followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // remove following
    followingRef
        .doc(currentUserId)
        .collection('userFollowing')
        .doc(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // delete activity feed item for them
    activityFeedRef
        .doc(widget.profileId)
        .collection('feedItems')
        .doc(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handleFollowUser() {
    setState(() {
      isFollowing = true;
    });
    // Make auth user follower of THAT user (update THEIR followers collection)
    followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(currentUserId)
        .set({});
    // Put THAT user on YOUR following collection (update your following collection)
    followingRef
        .doc(currentUserId)
        .collection('userFollowing')
        .doc(widget.profileId)
        .set({});
    // add activity feed item for that user to notify about new follower (us)
    activityFeedRef
        .doc(widget.profileId)
        .collection('feedItems')
        .doc(currentUserId)
        .set({
      "type": "follow",
      "ownerId": widget.profileId,
      "username": currentUser.username,
      "userId": currentUserId,
      "userProfileImg": currentUser.photoUrl,
      "timestamp": timestamp,
      "mediaUrl": null,
      "commentData": null,
      "postId": null,
    });
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: usersRef.doc(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Row(
              //   children: <Widget>[
              CircleAvatar(
                radius: 40.0,
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
              // Expanded(
              //   flex: 1,
              //   child: Column(
              //     children: <Widget>[
              //       Row(
              //         mainAxisSize: MainAxisSize.max,
              //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              //         children: <Widget>[
              //           buildCountColumn("posts", postCount),
              //           buildCountColumn("followers", followerCount),
              //           buildCountColumn("following", followingCount),
              //         ],
              //       ),
              //       Row(
              //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              //         children: <Widget>[
              //           buildProfileButton(),
              //         ],
              //       ),
              //     ],
              //   ),
              // ),
              //   ],
              // ),
              Container(
                // alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  user.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Container(
                // alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  user.displayName,
                  style: TextStyle(
                      // fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Container(
                // alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 2.0),
                child: Text(
                  user.bio,
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  buildCountColumn("posts", postCount),
                  buildCountColumn("followers", followerCount),
                  buildCountColumn("following", followingCount),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  buildProfileButton(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Container(
        child: Image.asset('assets/images/no_content.jpg'),
        // Column(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: <Widget>[
        //     SvgPicture.asset('assets/images/no_content.jpg', height: 260.0),
        //     Padding(
        //       padding: EdgeInsets.only(top: 20.0),
        //       child: Text(
        //         "No Posts",
        //         style: TextStyle(
        //           color: Colors.redAccent,
        //           fontSize: 40.0,
        //           fontWeight: FontWeight.bold,
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
      );
    } else if (postOrientation == "grid") {
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(child: PostTile(post)));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (postOrientation == "list") {
      return Column(
        children: posts,
      );
    }
  }

  setPostOrientation(String postOrientation) {
    setState(() {
      this.postOrientation = postOrientation;
    });
  }

  // buildTogglePostOrientation() {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //     children: <Widget>[
  //       IconButton(
  //         onPressed: () => setPostOrientation("grid"),
  //         icon: Icon(Icons.grid_on),
  //         color: postOrientation == 'grid'
  //             ? Theme.of(context).primaryColor
  //             : Colors.grey,
  //       ),
  //       IconButton(
  //         onPressed: () => setPostOrientation("list"),
  //         icon: Icon(Icons.list),
  //         color: postOrientation == 'list'
  //             ? Theme.of(context).primaryColor
  //             : Colors.grey,
  //       ),
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        // automaticallyImplyLeading: false,
        //   leading: IconButton(
        //       icon: Icon(
        //         Icons.arrow_back_rounded,
        //         color: Colors.white,
        //       ),
        //       onPressed: () {
        //         Navigator.of(context).pop();
        //       }),
      ),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          // Divider(),
          // buildTogglePostOrientation(),
          // Divider(height: 0.0),
          buildProfilePosts(),
        ],
      ),
    );
  }
}
