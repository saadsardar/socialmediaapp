class LiveStream {
  String token;
  String channelName;
  String hostName;
  String picture;
  int liveUsersCount;
  String location;

  LiveStream.fromJson(Map<String, dynamic> json)
      : this.token = json['token'],
        this.channelName = json['channelName'],
        this.hostName = json['hostName'],
        this.picture = json['picture'],
        this.liveUsersCount = json['liveUsersCount'],
        this.location = json['location'];
}
