import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as mobile_player;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as web_player;

class CrossPlatformYoutubePlayer extends StatefulWidget {
  final String videoId;
  final bool autoPlay;
  final VoidCallback? onLaunchYoutube;

  const CrossPlatformYoutubePlayer({super.key, required this.videoId, this.autoPlay = false, this.onLaunchYoutube});

  @override
  State<CrossPlatformYoutubePlayer> createState() => _CrossPlatformYoutubePlayerState();
}

class _CrossPlatformYoutubePlayerState extends State<CrossPlatformYoutubePlayer> {
  mobile_player.YoutubePlayerController? _mobileController;
  web_player.YoutubePlayerController? _webController;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _webController = web_player.YoutubePlayerController.fromVideoId(
        videoId: widget.videoId,
        autoPlay: widget.autoPlay,
        params: const web_player.YoutubePlayerParams(
          showFullscreenButton: true,
          mute: false,
        ),
      );
    } else {
      _mobileController = mobile_player.YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: mobile_player.YoutubePlayerFlags(
          autoPlay: widget.autoPlay,
        ),
      );
    }
  }

  @override
  void dispose() {
    _mobileController?.dispose();
    _webController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb
        ? web_player.YoutubePlayer(
            controller: _webController!,
          )
        : mobile_player.YoutubePlayer(
            controller: _mobileController!,
            bottomActions: [
              mobile_player.CurrentPosition(),
              mobile_player.ProgressBar(isExpanded: true),
              mobile_player.RemainingDuration(),
              mobile_player.PlaybackSpeedButton(),
              IconButton(
                icon: const Icon(Icons.open_in_new, color: Colors.white),
                onPressed: widget.onLaunchYoutube,
              ),
            ],
          );
  }
}
