import 'package:cloud_firestore/cloud_firestore.dart';

class ChatItem {
  String chatId;
  String from;
  String to;
  String image;
  String message;
  Timestamp timestamp;

  ChatItem.fromJson(Map<String, dynamic> json)
      : this.chatId = json['chatId'],
        this.from = json['from'],
        this.to = json['to'],
        this.image = json['image'],
        this.message = json['message'],
        this.timestamp = json['timestamp'];
}
