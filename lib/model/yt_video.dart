class YtVideo {
  final String videoId;
  final String videoTitle;
  final String thumbnailUrl;
  final String viewsCount;
  final String channelName;

  YtVideo({
    required this.videoId,
    required this.videoTitle,
    required this.thumbnailUrl,
    required this.viewsCount,
    required this.channelName,
  });

  get channelAvatarUrl => null;
}
