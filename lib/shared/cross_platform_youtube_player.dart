import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'
    as mobile_player;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as web_player;
import 'package:url_launcher/url_launcher.dart';

class CrossPlatformYoutubePlayer extends StatefulWidget {
  final String videoId;
  final bool autoPlay;
  final VoidCallback? onLaunchYoutube;
  final VoidCallback? onEnded;

  const CrossPlatformYoutubePlayer({
    super.key,
    required this.videoId,
    this.autoPlay = false,
    this.onLaunchYoutube,
    this.onEnded,
  });

  @override
  State<CrossPlatformYoutubePlayer> createState() =>
      _CrossPlatformYoutubePlayerState();
}

class _CrossPlatformYoutubePlayerState
    extends State<CrossPlatformYoutubePlayer> {
  web_player.YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = web_player.YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: widget.autoPlay,
      params: const web_player.YoutubePlayerParams(
        showFullscreenButton: true,
        mute: false,
      ),
    );
    _controller!.listen((event) {
      if (event.playerState == web_player.PlayerState.ended) {
        widget.onEnded?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerWidget = kIsWeb
        ? web_player.YoutubePlayer(controller: _controller!)
        : mobile_player.YoutubePlayer(controller: _controller!);

    return Stack(
      children: [
        playerWidget,
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.open_in_new,
                color: Colors.white,
                size: 20,
              ),
              tooltip: 'Open in YouTube',
              onPressed: () async {
                if (widget.onLaunchYoutube != null) {
                  widget.onLaunchYoutube!();
                } else {
                  final Uri url = Uri.parse(
                    'https://www.youtube.com/watch?v=${widget.videoId}',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
