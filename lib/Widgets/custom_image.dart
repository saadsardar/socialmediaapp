import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

Widget cachedNetworkImage(String mediaUrl) {
  return Container(
    alignment: Alignment.centerLeft,
    height: 250,
    // width: 300,
    width: double.infinity,
    padding: EdgeInsets.only(left: 15),
    child: CachedNetworkImage(
      imageUrl: mediaUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => Padding(
        child: CircularProgressIndicator(),
        padding: EdgeInsets.all(20.0),
      ),
      errorWidget: (context, url, error) => Icon(Icons.error),
    ),
  );
}
