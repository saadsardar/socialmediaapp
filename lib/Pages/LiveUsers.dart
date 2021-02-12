import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:social/Models/Streams.dart';
import 'package:social/Pages/call.dart';
import 'package:social/Pages/search.dart';
import '../Models/user.dart';

const List<String> countries = [
  'Malaysia',
  'Indonesia',
  'Thailand',
  'Vietnam',
  'Phillipine'
];

class LiveUsers extends StatefulWidget {
  final User currentUser;

  LiveUsers(this.currentUser);
  @override
  _LiveUsersState createState() => _LiveUsersState();
}

class _LiveUsersState extends State<LiveUsers> {
  TextEditingController searchController = TextEditingController();
  List<String> selectedCountries = [];

  clearSearch() {
    searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    Future<void> _handleCameraAndMic(Permission permission) async {
      final status = await permission.request();
      print(status);
    }

    selectCountryWidget(String country) {
      return GestureDetector(
        onTap: () {
          if (!selectedCountries.contains(country)) {
            selectedCountries.add(country);
          } else {
            selectedCountries.remove(country);
          }
          setState(
            () {},
          );
        },
        child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              color: selectedCountries.contains(country)
                  ? Theme.of(context).accentColor
                  : Theme.of(context).primaryColor,
            ),
            // height: 20,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                country,
                style: TextStyle(color: Colors.white),
              ),
            )),
      );
    }

    gridViewItem(LiveStream liveStream) {
      // print(liveStream);
      return Container(
        margin: const EdgeInsets.all(10),
        height: size.height * 0.3,
        width: size.width * 0.45,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(30)),
          color: Colors.red,
        ),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () async {
                await _handleCameraAndMic(Permission.camera);
                await _handleCameraAndMic(Permission.microphone);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => CallPage(
                    channelName: liveStream.channelName,
                    role: ClientRole.Audience,
                    currentUser: widget.currentUser,
                  ),
                ));
              },
              child: Container(
                // margin: const EdgeInsets.all(10),
                // height: size.height * 0.3,
                width: size.width * 0.45,
                // decoration: BoxDecoration(
                //   borderRadius: BorderRadius.all(Radius.circular(30)),
                //   color: Colors.red,
                // ),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  child: Image.network(liveStream.picture,
                      // 'https://i.pinimg.com/originals/6c/09/0f/6c090f6bdb01fa8e15a6fcd3cd2f6043.jpg',
                      fit: BoxFit.cover),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                // margin: const EdgeInsets.all(10),
                width: size.width * 0.435,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  color: Theme.of(context).primaryColor.withOpacity(0.7),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        liveStream.hostName,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Text(
                        liveStream.location,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
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
                  width: size.width * 0.5,
                  child: TextFormField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
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
                Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: IconButton(
                      icon: Icon(
                        Icons.video_call,
                        size: 40,
                        color: Theme.of(context).accentColor,
                      ),
                      onPressed: () async {
                        await _handleCameraAndMic(Permission.camera);
                        await _handleCameraAndMic(Permission.microphone);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => CallPage(
                            channelName: widget.currentUser.id,
                            role: ClientRole.Broadcaster,
                            currentUser: widget.currentUser,
                          ),
                        ));
                      }),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Live',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 20,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var item in countries) selectCountryWidget(item),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('livestream')
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else {
                  List<LiveStream> liveStreams = [];
                  final chatSnapshot = snap.data as QuerySnapshot;
                  print(chatSnapshot);
                  if (chatSnapshot == null || chatSnapshot.docs.length == 0) {
                    return Center(child: Text('No Live Streams'));
                  }

                  chatSnapshot.docs.forEach(
                    (e) {
                      print(e);
                      var map = e.data();
                      liveStreams.add(LiveStream.fromJson(map));
                    },
                  );

                  List<LiveStream> selectedLiveStreams = [];
                  if (selectedCountries.isEmpty) {
                    selectedLiveStreams = liveStreams;
                  } else {
                    liveStreams.forEach((e) {
                      if (selectedCountries.contains(e.location)) {
                        selectedLiveStreams.add(e);
                      }
                    });
                  }

                  return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          // childAspectRatio: 0.8,
                          crossAxisSpacing: 15),
                      itemCount: selectedLiveStreams.length,
                      itemBuilder: (ctx, i) =>
                          gridViewItem(selectedLiveStreams[i]));
                }
              },
            ),
            // ),
            // ),
          ),
        ],
      ),
    );
  }
}
