import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social/Widgets/header.dart';

final usersRef = FirebaseFirestore.instance.collection('users');
class Timeline extends StatefulWidget {
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  @override
  void initState() {
    //getUsers();
    super.initState();
  }


  // getUserById() async {
  //   final String id = "VJFNihBKjMEYT0p7wmnQ";
  //   final DocumentSnapshot doc = await usersRef.doc(id).get();
  //   print(doc.data);
  //   print(doc.id);
  //   print(doc.exists);
  // }

  // getUsers() async {
  //   final QuerySnapshot snapshot = await usersRef.get();
  //   setState(() {
  //     users = snapshot.docs;
  //   });
    // var abc = snapshot.docs;
    // abc.forEach((DocumentSnapshot doc) {
    //   print(doc.data);
    //   print(doc.id);
    //   print(doc.exists);
    // });
  //}
      // Container(
      //   child: ListView(
      //     children: users.map((users) => Text(users['username'])).toList(),
      //   ),
      // ),
  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.snapshots(),
        builder: (context,snapshot){
          if(!snapshot.hasData)
          {
            return CircularProgressIndicator();
          }
          final List<Text> users = snapshot.data.docs.map((e) => Text(e['username'])).toList();
          return Container(child: ListView(children: users,),);
        },
      )
    );
  }
}
