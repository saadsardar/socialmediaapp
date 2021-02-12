import 'package:social/Pages/timeline.dart';

import '../Models/user.dart';
import 'package:flutter/material.dart';

import 'bar.dart';

class FrontPage extends StatefulWidget {
  final User currentUser;

  FrontPage(this.currentUser);
  @override
  _FrontPageState createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> with TickerProviderStateMixin {
  TabController _tabcontroller;

  @override
  void initState() {
    _tabcontroller = TabController(vsync: this, length: 2);
    super.initState();
  }

  @override
  void dispose() {
    _tabcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
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
                    'Follow',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                Tab(
                  child: Text(
                    'Popular',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 800,
            child: TabBarView(
              controller: _tabcontroller,
              children: <Widget>[
                Timeline(currentUser: widget.currentUser),
                Bar(currentUser: widget.currentUser),
                // LiveUsers(widget.currentUser),
              ],
            ),
          ),
        ],
        // ),
      ),
    );
  }
}
