import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:social/Models/Chat.dart';
import 'package:social/Pages/home.dart';

class ChatScreen extends StatefulWidget {
  final selfUid1;
  final friendUid2;
  ChatScreen(this.selfUid1, this.friendUid2);
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String chatId;
  // ThemeData theme;
  TextEditingController _messageControl;
  @override
  void initState() {
    // theme = Theme.of(context);
    _messageControl = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _messageControl.dispose();
    super.dispose();
  }

  String getChatId() {
    int i = widget.selfUid1.compareTo(widget.friendUid2);
    if (i == 1) {
      return widget.selfUid1 + widget.friendUid2;
    } else {
      return widget.friendUid2 + widget.selfUid1;
    }
  }

  Widget textWidget(bool isSelf, String message, Timestamp date) {
    return Column(
      crossAxisAlignment:
          isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          // height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          constraints: BoxConstraints(
              // minWidth: 100,
              maxWidth: MediaQuery.of(context).size.width * 0.5),
          // width: ,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: isSelf ? Radius.circular(0) : Radius.circular(20),
              bottomLeft: isSelf ? Radius.circular(20) : Radius.circular(0),
            ),
            color: isSelf ? Theme.of(context).primaryColor : Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15),
            child: Text(
              message,
              textAlign: isSelf ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                color: isSelf ? Colors.white : Colors.black,
                fontSize: 15,
              ),
            ),
          ),
        ),
        Text(
          '${DateFormat.yMMMd().format(date.toDate())}',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget imageWidget(String url) {
    return CircleAvatar(
      radius: 15,
      backgroundImage: NetworkImage(url),
    );
  }

  Widget chatWidget(ChatItem chat) {
    return Container(
      padding: const EdgeInsets.all(10),
      // margin: const EdgeInsets.all(10),
      child: chat.from == widget.selfUid1
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                textWidget(true, chat.message, chat.timestamp),
                imageWidget(chat.image),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                imageWidget(chat.image),
                textWidget(false, chat.message, chat.timestamp),
              ],
            ),
    );
    // ListTile(
    //   leading: CircleAvatar(
    //     radius: 30,
    //     backgroundImage: NetworkImage(chat.image),
    //   ),
    //   title: Container(
    //     width: MediaQuery.of(context).size.width * 0.8,
    //     decoration: BoxDecoration(
    //         border: Border.all(
    //           color: Colors.grey[350],
    //         ),
    //         borderRadius: BorderRadius.all(Radius.circular(10))),
    //     padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 3),
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         // Text(
    //         //   '${chat.userName}',
    //         //   style: TextStyle(
    //         //       color: theme.primaryColor,
    //         //       fontSize: 15,
    //         //       fontWeight: FontWeight.bold),
    //         // ),
    //         Text(
    //           '${chat.message}',
    //           style: TextStyle(color: theme.primaryColor, fontSize: 16),
    //         ),
    //       ],
    //     ),
    //   ),
    //   subtitle: Text(
    //     '${DateFormat.yMMMd().format(chat.timestamp.toDate())}',
    //     style: TextStyle(fontSize: 11),
    //   ),
    // );
  }

  _submit() async {
    final message = _messageControl.text;
    FocusScope.of(context).unfocus();
    // print(comment);
    // FocusScope.of(context).unfocus();
    if (message.length != 0) {
      await FirebaseFirestore.instance.collection('chats').add({
        'chatId': chatId,
        'to': widget.friendUid2,
        'from': widget.selfUid1,
        'image': currentUser.photoUrl,
        'message': message,
        'timestamp': Timestamp.now(),
      });
    }
    _messageControl.clear();
  }

  Widget newMessage(String url) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 10),
      leading: CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(url),
      ),
      title: Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[350], width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.6,
                child: TextField(
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  controller: _messageControl,
                  style: TextStyle(
                    fontSize: 15.0,
                    // color: Theme.of(context).primaryColor,
                  ),
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(10.0),
                    hintText: "Type A Message",
                    hintStyle: TextStyle(
                      fontSize: 15.0,
                      color: Colors.blueGrey[500],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              color: Theme.of(context).primaryColor,
              icon: Icon(Icons.send),
              onPressed: () => _submit(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    chatId = getChatId();
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Expanded(
            child: Container(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    // .doc(chatId)
                    .where('chatId', isEqualTo: chatId)
                    .snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    List<ChatItem> chat = [];
                    final chatSnapshot = snap.data;
                    if (chatSnapshot == null) {
                      Center(child: Text('Start A Conversation'));
                    }
                    chatSnapshot.documents.forEach(
                      (e) {
                        var map = e.data();
                        // map['chatId'] = e.id;
                        chat.add(ChatItem.fromJson(map));
                      },
                    );
                    chat.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                    return Column(
                      children: [
                        for (var item in chat) chatWidget(item),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
          Container(
              margin: const EdgeInsets.all(10),
              child: newMessage(currentUser.photoUrl)),
        ],
      ),
    );
  }
}
