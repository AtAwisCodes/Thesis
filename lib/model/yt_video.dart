class YtVideo {
  final String videoId;
  final String videoTitle;
  final String thumbnailUrl;
  final String viewsCount;
  final String channelName;
  final String? channelAvatarUrl;

  YtVideo({
    required this.videoId,
    required this.videoTitle,
    required this.thumbnailUrl,
    required this.viewsCount,
    required this.channelName,
    this.channelAvatarUrl,
  });
}
