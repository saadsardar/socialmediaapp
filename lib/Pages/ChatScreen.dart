import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:social/Models/Chat.dart';
import 'package:social/Models/user.dart';
import 'package:social/Pages/VideoCall.dart';
import 'package:social/Pages/home.dart';

class ChatScreen extends StatefulWidget {
  final String self1;
  final String friend2;
  ChatScreen(this.self1, this.friend2);
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  User userSelf, userFriend;
  String chatId;
  bool isLoading = true;
  TextEditingController _messageControl;
  @override
  void initState() {
    _messageControl = TextEditingController();
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    // if (isInit == false) {
    var doc = await usersRef.doc(widget.self1).get();
    var doc2 = await usersRef.doc(widget.friend2).get();
    setState(() {
      userSelf = User.fromDocument(doc);
      userFriend = User.fromDocument(doc2);
      chatId = getChatId();
      print('Data gathered');
      isLoading = false;
    });
    // isInit = true;
    // }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _messageControl.dispose();
    super.dispose();
  }

  String getChatId() {
    int i = userSelf.id.compareTo(userFriend.id);
    if (i == 1) {
      return userSelf.id + userFriend.id;
    } else {
      return userFriend.id + userSelf.id;
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
            color: isSelf ? Theme.of(context).primaryColor : Colors.grey[300],
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
      child: chat.from == userSelf.id
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
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(userSelf.id)
          .collection(userFriend.id)
          .add({
        'chatId': chatId,
        'to': userFriend.id,
        'from': userSelf.id,
        'image': currentUser.photoUrl,
        'message': message,
        'timestamp': Timestamp.now(),
      });
      _messageControl.clear();
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(userFriend.id)
          .collection(userSelf.id)
          .add({
        'chatId': chatId,
        'to': userFriend.id,
        'from': userSelf.id,
        'image': currentUser.photoUrl,
        'message': message,
        'timestamp': Timestamp.now(),
      });
    }
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(userSelf.id)
        .collection('chats')
        .doc(userFriend.id)
        .set({
      'id': userFriend.id,
      'name': userFriend.displayName,
      'picture': userFriend.photoUrl,
    });
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(userFriend.id)
        .collection('chats')
        .doc(userSelf.id)
        .set({
      'id': userSelf.id,
      'name': userSelf.displayName,
      'picture': userSelf.photoUrl,
    });
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

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              icon: Icon(Icons.video_call),
              onPressed: () async {
                await _handleCameraAndMic(Permission.camera);
                await _handleCameraAndMic(Permission.microphone);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => VideoCall(
                    channelName: chatId,
                    role: ClientRole.Broadcaster,
                    currentUser: userSelf,
                  ),
                ));
              }),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child: Container(
                    child: StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('chats')
                          .doc(userSelf.id)
                          .collection(userFriend.id)
                          // .doc(chatId)
                          // .where('chatId', isEqualTo: chatId)
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
                          chat.sort(
                              (a, b) => a.timestamp.compareTo(b.timestamp));
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                for (var item in chat) chatWidget(item),
                              ],
                            ),
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
