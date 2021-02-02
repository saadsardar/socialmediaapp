import '../Models/user.dart';
import 'package:flutter/material.dart';

import 'LiveUsers.dart';
import 'search.dart';

class FrontPage extends StatefulWidget {
  final User currentUser;

  FrontPage(this.currentUser);
  @override
  _FrontPageState createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> with TickerProviderStateMixin {
  TabController _tabcontroller;
  TextEditingController searchController = TextEditingController();

  clearSearch() {
    searchController.clear();
  }

  @override
  void initState() {
    _tabcontroller = TabController(vsync: this, length: 2);
    super.initState();
  }

  @override
  void dispose() {
    _tabcontroller.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          SizedBox(
            height: 40,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.currentUser.photoUrl),
                  radius: 25,
                ),
                SizedBox(
                  width: 20,
                ),
                Container(
                  width: size.width * 0.6,
                  child: TextFormField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    // decoration: InputDecoration(
                    //   border: OutlineInputBorder(
                    //       borderRadius: BorderRadius.all(Radius.circular(20))),
                    //   hintText: "Search",
                    //   // filled: true,

                    //   suffixIcon: IconButton(
                    //     icon: Icon(Icons.clear),
                    //     onPressed: clearSearch,
                    //   ),
                    // ),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        borderSide: BorderSide(
                          color: Colors.white,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white,
                        ),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      hintText: "Search",
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.blueGrey[300],
                      ),
                      hintStyle: TextStyle(
                        fontSize: 15.0,
                        color: Colors.blueGrey[300],
                      ),
                    ),
                    onFieldSubmitted: (v) {
                      print(v);
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (ctx) => Search(v)));
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            child: Container(
              child: TabBar(
                controller: _tabcontroller,
                indicatorColor: Theme.of(context).primaryColor,
                indicatorSize: TabBarIndicatorSize.label,
                unselectedLabelColor: Theme.of(context).accentColor,
                labelColor: Theme.of(context).primaryColor,
                indicatorWeight: 5,
                tabs: [
                  Tab(
                    child: Text(
                      'Live',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  Tab(
                    child: Text(
                      'Chats',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 800,
            child: TabBarView(
              controller: _tabcontroller,
              children: <Widget>[
                LiveUsers(widget.currentUser),
                LiveUsers(widget.currentUser),
                // CampaignsFrontPage(),
              ],
            ),
          ),
        ],
        // ),
      ),
    );
  }
}
