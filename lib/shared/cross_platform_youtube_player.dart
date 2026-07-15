import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';

class CrossPlatformYoutubePlayer extends StatefulWidget {
  final String videoId;
  final bool autoPlay;
  final VoidCallback? onLaunchYoutube;
  final VoidCallback? onEnded;
  final double aspectRatio;

  const CrossPlatformYoutubePlayer({
    super.key,
    required this.videoId,
    this.autoPlay = false,
    this.onLaunchYoutube,
    this.onEnded,
    this.aspectRatio = 16 / 9,
  });

  @override
  State<CrossPlatformYoutubePlayer> createState() =>
      _CrossPlatformYoutubePlayerState();
}

class _CrossPlatformYoutubePlayerState
    extends State<CrossPlatformYoutubePlayer> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: widget.autoPlay,
      params: const YoutubePlayerParams(
        mute: false,
        enableCaption: false,
        showFullscreenButton: true,
        enableKeyboard: false,
        showVideoAnnotations: false,
        strictRelatedVideos: true,
      ),
    );
    _controller!.listen((event) {
      if (event.playerState == PlayerState.ended) {
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
    final playerWidget = YoutubePlayer(
      controller: _controller!,
      aspectRatio: widget.aspectRatio,
    );

    return Stack(
      children: [
        playerWidget,
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: Center(
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
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
