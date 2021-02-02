import 'package:flutter/material.dart';

import '../Models/user.dart';

class LiveUsers extends StatefulWidget {
  final User currentUser;

  LiveUsers(this.currentUser);
  @override
  _LiveUsersState createState() => _LiveUsersState();
}

class _LiveUsersState extends State<LiveUsers> {
  @override
  Widget build(BuildContext context) {
    gridViewItem() {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(30)),
          color: Colors.red,
        ),
      );
    }

    return
        // Expanded(
        //   child:
        Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
      child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
              crossAxisSpacing: 15),
          itemCount: 10,
          itemBuilder: (ctx, i) => gridViewItem()),
      // ),
    );
  }
}
