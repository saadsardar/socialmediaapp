import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social/Models/user.dart';
import 'package:social/Pages/activity_feed.dart';
import 'package:social/Widgets/progress.dart';
import 'home.dart';

class Search extends StatelessWidget {
  final query;
  Search(this.query);
  // TextEditingController searchController = TextEditingController();

  // QuerySnapshot searchResultsFuture;

  Future<QuerySnapshot> handleSearch() {
    print('Hello $query');
    final users =
        usersRef.where("displayName", isGreaterThanOrEqualTo: query).get();
    return users;
    // setState(() {
    //   searchResultsFuture = users;
    // });
  }

  // clearSearch() {
  //   searchController.clear();
  // }

  AppBar buildSearchField() {
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        // controller: searchController,
        decoration: InputDecoration(
          hintText: "Search",
          filled: true,
          prefixIcon: Icon(
            Icons.account_box,
            size: 28.0,
          ),
          // suffixIcon: IconButton(
          //   icon: Icon(Icons.clear),
          //   // onPressed: clearSearch,
          // ),
        ),
        onFieldSubmitted: (v) {
          handleSearch();
        },
      ),
    );
  }

  // Container buildNoContent() {
  //   final Orientation orientation = MediaQuery.of(context).orientation;
  //   return Container(
  //     child: Center(
  //       child: ListView(
  //         shrinkWrap: true,
  //         children: <Widget>[
  //           SvgPicture.asset(
  //             'assets/images/search.svg',
  //             height: orientation == Orientation.portrait ? 300.0 : 200.0,
  //           ),
  //           Text(
  //             "Find Users",
  //             textAlign: TextAlign.center,
  //             style: TextStyle(
  //               color: Colors.white,
  //               fontStyle: FontStyle.italic,
  //               fontWeight: FontWeight.w600,
  //               fontSize: 60.0,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  buildSearchResults() {
    return FutureBuilder(
      future: handleSearch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        // final searchResultsFuture = snapshot.data;
        List<UserResult> searchResults = [];
        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocument(doc);
          UserResult searchResult = UserResult(user);
          searchResults.add(searchResult);
        });
        return ListView(
          children: searchResults,
        );
      },
    );
  }

  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: buildSearchResults(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;

  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
              title: Text(
                user.displayName,
                style: TextStyle(
                    color: theme.accentColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                user.username,
                style: TextStyle(color: theme.accentColor, fontSize: 15),
              ),
            ),
          ),
          Divider(
            height: 3,
            color: theme.primaryColor,
          ),
        ],
      ),
    );
  }
}
