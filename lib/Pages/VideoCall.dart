import 'dart:async';
import 'dart:math';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social/Models/message.dart';
import 'package:social/Models/user.dart';
import 'package:social/Widgets/HearAnim.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../utils/settings.dart';

class VideoCall extends StatefulWidget {
  /// non-modifiable channel name of the page
  final String channelName;
  final User currentUser;

  /// non-modifiable client role of the page
  final ClientRole role;

  /// Creates a call page with given channel name.
  const VideoCall({Key key, this.channelName, this.role, this.currentUser})
      : super(key: key);

  @override
  _VideoCallState createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  final _users = <int>[];
  bool muted = false;
  RtcEngine _engine;
  List<Message> _infoStrings2 = [];

  @override
  void dispose() {
    _users.clear();
    _engine.leaveChannel();
    _engine.destroy();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    if (APP_ID.isEmpty) {
      setState(() {
        _log(
            info: 'APP_ID missing, please provide your APP_ID in settings.dart',
            type: 'notif',
            user: 'System');

        _log(
            info: 'Agora Engine is not starting',
            type: 'notif',
            user: 'System');
      });
      return;
    }

    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    await _engine.enableWebSdkInteroperability(true);
    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    configuration.dimensions = VideoDimensions(1920, 1080);
    await _engine.setVideoEncoderConfiguration(configuration);
    String token;
    if (widget.role == ClientRole.Broadcaster) {
      HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
          'onNewToken',
          options: HttpsCallableOptions(timeout: Duration(seconds: 10)));
      try {
        final HttpsCallableResult result = await callable.call(
          <String, dynamic>{
            'channelName': widget.channelName,
          },
        );
        token = result.data['token'];
      } on FirebaseFunctionsException catch (e) {
        print('caught firebase functions exception');
        print(e.code);
        print(e.message);
        print(e.details);
      } catch (e) {
        print('caught generic exception');
        print(e);
      }
    } else {
      try {
        final videoCallSnapshot = await FirebaseFirestore.instance
            .collection('videoCall')
            .doc(widget.channelName)
            .get();
        final videoCallData = videoCallSnapshot.data();
        token = videoCallData['token'];
      } catch (e) {
        final info = 'onError: $e';
        _log(info: info, type: 'notif', user: 'System');
      }
    }
    if (widget.role == ClientRole.Broadcaster) {
      await FirebaseFirestore.instance
          .collection('videoCall')
          .doc(widget.channelName)
          .set({
        'channelName': widget.channelName,
        'token': token,
        'hostName': widget.currentUser.displayName,
        'picture': widget.currentUser.photoUrl,
        'status': 'pending'
      });
    }
    await _engine.joinChannel(token, widget.channelName, null, 0);
  }

  /// Create agora sdk instance and initialize
  Future<void> _initAgoraRtcEngine() async {
    print('In initAgora');
    _engine = await RtcEngine.create(APP_ID);
    // print('Created');
    await _engine.enableVideo();
    // print('video enabled');
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    // print('channel profile');
    await _engine.setClientRole(widget.role);
    // print('set client role');
  }

  /// Add agora event handlers
  void _addAgoraEventHandlers() {
    _engine.setEventHandler(RtcEngineEventHandler(error: (code) {
      setState(() {
        print('Error');
        final info = 'onError: $code';
        _log(info: info, type: 'notif', user: 'System');
      });
    }, joinChannelSuccess: (channel, uid, elapsed) {
      setState(() {
        final info = 'onJoinChannel: $channel, uid: $uid';
        _log(info: info, type: 'notif', user: 'System');
      });
    }, leaveChannel: (stats) {
      setState(() {
        _log(info: 'onLeaveChannel', type: 'notif', user: 'System');
        _users.clear();
      });
    }, userJoined: (uid, elapsed) {
      setState(() async {
        final info = 'userJoined: $uid';
        _log(info: info, type: 'notif', user: 'System');
        _users.add(uid);

        await FirebaseFirestore.instance
            .collection('videoCall')
            .doc(widget.channelName)
            .update({'status': 'inCall'});
      });
    }, userOffline: (uid, elapsed) {
      setState(() {
        final info = 'userOffline: $uid';
        _log(info: info, type: 'notif', user: 'System');
        _users.remove(uid);
      });
    }, firstRemoteVideoFrame: (uid, width, height, elapsed) {
      setState(() {
        final info = 'firstRemoteVideo: $uid ${width}x $height';
        _log(info: info, type: 'notif', user: 'System');
      });
    }));
  }

  /// Helper function to get list of native views
  List<Widget> _getRenderViews() {
    final List<StatefulWidget> list = [];
    if (widget.role == ClientRole.Broadcaster) {
      list.add(RtcLocalView.SurfaceView());
    }
    _users.forEach((int uid) => list.add(RtcRemoteView.SurfaceView(uid: uid)));
    return list;
  }

  /// Video view wrapper
  Widget _videoView(view) {
    return Expanded(child: Container(child: view));
  }

  /// Video view row wrapper
  Widget _expandedVideoRow(List<Widget> views) {
    final wrappedViews = views.map<Widget>(_videoView).toList();
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  /// Video layout wrapper
  Widget _viewRows() {
    final views = _getRenderViews();
    switch (views.length) {
      case 1:
        return Container(
            child: Column(
          children: <Widget>[_videoView(views[0])],
        ));
      case 2:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow([views[0]]),
            _expandedVideoRow([views[1]])
          ],
        ));
      case 3:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow(views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 3))
          ],
        ));
      case 4:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow(views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 4))
          ],
        ));
      default:
    }
    return Container();
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }

  //new UI
  var tryingToEnd = false;
  bool personBool = false;

  Widget _endCall() {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  tryingToEnd = true;
                });
              },
              child: Text(
                'END',
                style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget endLive() {
    // print('ENd Tapped');
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Text(
                'Are you sure you want to end your live call?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 8.0, right: 4.0, top: 8.0, bottom: 8.0),
                    child: RaisedButton(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Text(
                          'End Call',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      elevation: 2.0,
                      color: Theme.of(context).primaryColor,
                      onPressed: () async {
                        if (widget.channelName
                            .contains(widget.currentUser.id)) {
                          await FirebaseFirestore.instance
                              .collection('videoCall')
                              .doc(widget.channelName)
                              .delete();
                          print('Deleted From Firebase');
                        }

                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 4.0, right: 8.0, top: 8.0, bottom: 8.0),
                    child: RaisedButton(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      elevation: 2.0,
                      color: Colors.grey,
                      onPressed: () {
                        setState(() {
                          tryingToEnd = false;
                        });
                      },
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget heartPop() {
    final size = MediaQuery.of(context).size;
    final confetti = <Widget>[];
    for (var i = 0; i < 5; i++) {
      final height = Random().nextInt(size.height.floor());
      final width = 20;
      confetti.add(HeartAnim(
        height % 200.0,
        width.toDouble(),
        0.5,
      ));
    }
    return Container(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Container(
            height: 400,
            width: 200,
            child: Stack(
              children: confetti,
            ),
          ),
        ),
      ),
    );
  }

  // Widget messageList() {
  //   return Container(
  //     padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
  //     alignment: Alignment.bottomCenter,
  //     child: FractionallySizedBox(
  //       heightFactor: 0.5,
  //       child: StreamBuilder(
  //         stream: FirebaseFirestore.instance
  //             .collection('videoCall')
  //             .doc(widget.channelName)
  //             .collection('comments')
  //             .snapshots(),
  //         builder: (ctx, snap) {
  //           if (snap.connectionState == ConnectionState.waiting) {
  //             return Center(
  //               child: CircularProgressIndicator(),
  //             );
  //           } else {
  //             List<Message> messages = [];
  //             final chatSnapshot = snap.data;
  //             if (chatSnapshot == null) {
  //               return Container();
  //               // Center(child: Text('Start A Conversation'));
  //             }
  //             chatSnapshot.documents.forEach(
  //               (e) {
  //                 var map = e.data();
  //                 // map['chatId'] = e.id;
  //                 messages.add(Message.fromJson(map));
  //               },
  //             );
  //             messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  //             return Container(
  //               padding: const EdgeInsets.symmetric(vertical: 48),
  //               child: ListView.builder(
  //                 reverse: true,
  //                 itemCount: messages.length,
  //                 itemBuilder: (BuildContext context, int index) {
  //                   if (messages.isEmpty) {
  //                     return null;
  //                   }
  //                   return Container(
  //                     color: Colors.black12,
  //                     margin: const EdgeInsets.symmetric(vertical: 2),
  //                     padding: const EdgeInsets.symmetric(
  //                         vertical: 3, horizontal: 10),
  //                     child: (messages[index].type == 'join')
  //                         ? Padding(
  //                             padding: const EdgeInsets.only(bottom: 10),
  //                             child: Row(
  //                               mainAxisSize: MainAxisSize.max,
  //                               mainAxisAlignment: MainAxisAlignment.start,
  //                               children: <Widget>[
  //                                 Padding(
  //                                   padding: const EdgeInsets.symmetric(
  //                                     horizontal: 8,
  //                                   ),
  //                                   child: Text(
  //                                     'New User joined',
  //                                     style: TextStyle(
  //                                       color: Colors.white,
  //                                       fontSize: 14,
  //                                     ),
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                           )
  //                         : (messages[index].type == 'message')
  //                             ? Padding(
  //                                 padding: const EdgeInsets.only(bottom: 10),
  //                                 child: Row(
  //                                   mainAxisSize: MainAxisSize.max,
  //                                   mainAxisAlignment: MainAxisAlignment.start,
  //                                   children: <Widget>[
  //                                     CachedNetworkImage(
  //                                       imageUrl: messages[index].image,
  //                                       imageBuilder:
  //                                           (context, imageProvider) =>
  //                                               Container(
  //                                         width: 32.0,
  //                                         height: 32.0,
  //                                         decoration: BoxDecoration(
  //                                           shape: BoxShape.circle,
  //                                           image: DecorationImage(
  //                                               image: imageProvider,
  //                                               fit: BoxFit.cover),
  //                                         ),
  //                                       ),
  //                                     ),
  //                                     Column(
  //                                       crossAxisAlignment:
  //                                           CrossAxisAlignment.start,
  //                                       children: <Widget>[
  //                                         Padding(
  //                                           padding: const EdgeInsets.symmetric(
  //                                             horizontal: 8,
  //                                           ),
  //                                           child: Text(
  //                                             messages[index].user,
  //                                             style: TextStyle(
  //                                                 color: Colors.white,
  //                                                 fontSize: 14,
  //                                                 fontWeight: FontWeight.bold),
  //                                           ),
  //                                         ),
  //                                         SizedBox(
  //                                           height: 5,
  //                                         ),
  //                                         Padding(
  //                                           padding: const EdgeInsets.symmetric(
  //                                             horizontal: 8,
  //                                           ),
  //                                           child: Text(
  //                                             messages[index].message,
  //                                             style: TextStyle(
  //                                                 color: Colors.white,
  //                                                 fontSize: 14),
  //                                           ),
  //                                         ),
  //                                       ],
  //                                     )
  //                                   ],
  //                                 ),
  //                               )
  //                             : (messages[index].type == 'notif')
  //                                 ? Padding(
  //                                     padding: const EdgeInsets.only(
  //                                         bottom: 10, left: 8, right: 8),
  //                                     child: Text(
  //                                       messages[index].message,
  //                                       maxLines: 3,
  //                                       overflow: TextOverflow.fade,
  //                                       style: TextStyle(
  //                                           color: Colors.white, fontSize: 14),
  //                                     ),
  //                                   )
  //                                 : null,
  //                   );
  //                 },
  //               ),
  //             );
  //           }
  //         },
  //       ),
  //     ),
  //   );
  // }

  // void _sendMessage(text) async {
  //   if (text.isEmpty) {
  //     return;
  //   }
  //   try {
  //     _channelMessageController.clear();
  //     // await _channel.sendMessage(AgoraRtmMessage.fromText(text));
  //     _log(user: widget.currentUser.displayName, info: text, type: 'message');
  //   } catch (errorCode) {
  //     // _log('Send channel message error: ' + errorCode.toString());
  //   }
  // }

  Widget _bottomBar() {
    // if (!_isLogin || !_isInChannel) {
    //   return Container();
    // }
    return Container(
      alignment: Alignment.bottomRight,
      child: Container(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.only(left: 8, top: 5, right: 8, bottom: 5),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
            // new Expanded(
            //     child: Padding(
            //   padding: const EdgeInsets.fromLTRB(0.0, 0, 0, 0),
            //   child: new TextField(
            //       cursorColor: Colors.blue,
            //       textInputAction: TextInputAction.send,
            //       onSubmitted: _sendMessage,
            //       style: TextStyle(color: Colors.white),
            //       controller: _channelMessageController,
            //       textCapitalization: TextCapitalization.sentences,
            //       decoration: InputDecoration(
            //         isDense: true,
            //         hintText: 'Comment',
            //         hintStyle: TextStyle(color: Colors.white),
            //         enabledBorder: OutlineInputBorder(
            //             borderRadius: BorderRadius.circular(50.0),
            //             borderSide: BorderSide(color: Colors.white)),
            //         focusedBorder: OutlineInputBorder(
            //             borderRadius: BorderRadius.circular(50.0),
            //             borderSide: BorderSide(color: Colors.white)),
            //       )),
            // )),
            // Padding(
            //   padding: const EdgeInsets.fromLTRB(4.0, 0, 0, 0),
            //   child: MaterialButton(
            //     minWidth: 0,
            //     onPressed: _toggleSendChannelMessage,
            //     child: Icon(
            //       Icons.send,
            //       color: Colors.white,
            //       size: 20.0,
            //     ),
            //     shape: CircleBorder(),
            //     elevation: 2.0,
            //     color: Theme.of(context).primaryColor,
            //     padding: const EdgeInsets.all(12.0),
            //   ),
            // ),
            // if (accepted == false)
            //   Padding(
            //     padding: const EdgeInsets.fromLTRB(4.0, 0, 0, 0),
            //     child: MaterialButton(
            //       minWidth: 0,
            //       onPressed: () {},
            //       child: Icon(
            //         Icons.person_add,
            //         color: Colors.white,
            //         size: 20.0,
            //       ),
            //       shape: CircleBorder(),
            //       elevation: 2.0,
            //       color: Colors.blue[400],
            //       padding: const EdgeInsets.all(12.0),
            //     ),
            //   ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4.0, 0, 0, 0),
              child: MaterialButton(
                minWidth: 0,
                onPressed: _onSwitchCamera,
                child: Icon(
                  Icons.switch_camera,
                  color: Theme.of(context).primaryColor,
                  size: 20.0,
                ),
                shape: CircleBorder(),
                elevation: 2.0,
                color: Colors.white,
                padding: const EdgeInsets.all(12.0),
              ),
            )
          ]),
        ),
      ),
    );
  }

  // void _toggleSendChannelMessage() async {
  //   String text = _channelMessageController.text;
  //   if (text.isEmpty) {
  //     return;
  //   }
  //   try {
  //     _channelMessageController.clear();
  //     // await _channel.sendMessage(AgoraRtmMessage.fromText(text));
  //     _log(user: widget.currentUser.displayName, info: text, type: 'message');
  //   } catch (errorCode) {
  //     //_log(info: 'Send channel message error: ' + errorCode.toString(), type: 'error');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // appBar: AppBar(
        //     // title: Text('Agora Flutter QuickStart'),
        //     ),
        backgroundColor: Colors.black,
        body: Center(
          child: Stack(
            children: <Widget>[
              // _viewRows(),
              // _panel(),
              // _toolbar(),

              _viewRows(), // Video Widget
              if (tryingToEnd == false) _endCall(),
              // if (tryingToEnd == false) _liveText(),
              // if (heart == true && tryingToEnd == false) heartPop(),
              if (tryingToEnd == false) _bottomBar(), // send message
              // if (tryingToEnd == false) messageList(),
              if (tryingToEnd == true)
                endLive(), // view message // view message
              // if (personBool == true && waiting == false) personList(),
              // if (accepted == true) stopSharing(),
              // if (waiting == true) guestWaiting(),
            ],
          ),
        ),
      ),
    );
  }

  void _log({String info, String type, String user}) {
    if (type == 'message' && info.contains('m1x2y3z4p5t6l7k8')) {
    } else if (type == 'message' && info.contains('k1r2i3s4t5i6e7')) {
      setState(() {
        personBool = false;
        personBool = false;
        // waiting = false;
      });
    } else if (type == 'message' && info.contains('E1m2I3l4i5E6')) {
      // stopFunction();
    } else if (type == 'message' && info.contains('R1e2j3e4c5t6i7o8n9e0d')) {
      setState(() {
        // waiting = false;
      });
      /*FlutterToast.showToast(
          msg: "Guest Declined",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0
      );*/

    } else {
      // var image =
      //     'https://www.teahub.io/photos/full/364-3646192_beautiful-girls-4k-images-dpz-beautiful-pinterest-girls.jpg';
      Message m = new Message(
          message: info,
          type: type,
          user: user,
          image: widget.currentUser.photoUrl);

      // FirebaseFirestore.instance
      //     .collection('videoCall')
      //     .doc(widget.channelName)
      //     .collection('comments')
      //     .add({
      //   'message': info,
      //   'type': type,
      //   'user': user,
      //   'image': widget.currentUser.photoUrl,
      //   'timestamp': Timestamp.now(),
      // });
      setState(() {
        _infoStrings2.insert(0, m);
      });
    }
  }
}
