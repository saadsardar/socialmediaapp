import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  String message;
  String type;
  String user;
  String image;
  Timestamp timestamp;

  Message.fromJson(Map<String, dynamic> json)
      : this.message = json['message'],
        this.type = json['type'],
        this.user = json['user'],
        this.image = json['image'],
        this.timestamp = json['timestamp'];

  Message({this.message, this.type, this.user, this.image});
}
