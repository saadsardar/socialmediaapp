import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social/Pages/home.dart';

import 'ChatScreen.dart';

class ChatPeople {
  String name;
  String id;
  String picture;

  ChatPeople.fromJson(Map<String, dynamic> json)
      : this.name = json['name'],
        this.picture = json['picture'],
        this.id = json['id'];
}

class AllChatsScreen extends StatelessWidget {
  final String currentUserId;
  AllChatsScreen({this.currentUserId});

  @override
  Widget build(BuildContext context) {
    Widget chatPerson(ChatPeople chatpersonItem) {
      return ListTile(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (ctx) => ChatScreen(currentUser.id, chatpersonItem.id)));
        },
        leading: CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(chatpersonItem.picture),
        ),
        title: Text(
          chatpersonItem.name,
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
      ),
      body:
          // FutureBuilder(
          //   future: setUser(),
          //   builder: (ctx, snap) {
          //     if (snap.connectionState == ConnectionState.waiting) {
          //       return Center(
          //         child: CircularProgressIndicator(),
          //       );
          //     } else {

          //       return
          SingleChildScrollView(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .doc(currentUser.id)
              .collection('chats')
              .snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(
                child: Center(child: CircularProgressIndicator()),
              );
            } else {
              List<ChatPeople> chatWithPeople = [];
              final chatSnapshot = snap.data as QuerySnapshot;
              if (chatSnapshot == null || chatSnapshot.docs.length == 0) {
                Center(child: Text('Start A Conversation'));
              }
              print(chatSnapshot);
              chatSnapshot.docs.forEach(
                (e) {
                  var map = e.data();
                  print(map);
                  // map['chatId'] = e.id;
                  chatWithPeople.add(ChatPeople.fromJson(map));
                },
              );
              print(chatWithPeople);
              // chat.sort((a, b) => a.timestamp.compareTo(b.timestamp));
              return Column(
                children: [
                  for (var item in chatWithPeople) chatPerson(item),
                ],
              );
            }
          },
        ),
      ),
      //         }
      //       },
      //     ),
    );
  }
}
