import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:itcc/src/data/models/promotion_model.dart';

String? extractYoutubeId(String url) {
  final RegExp regExp = RegExp(
    r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([^&\n?#]+)',
    caseSensitive: false,
  );
  final match = regExp.firstMatch(url);
  return match?.group(1);
}

Widget customVideo(
    {required String videoId,
    required String title,
    required BuildContext context}) {
  final ytController = YoutubePlayerController(
    initialVideoId: videoId,
    flags: const YoutubePlayerFlags(
      disableDragSeek: true,
      autoPlay: false,
      loop: true,
      mute: false,
      controlsVisibleAtStart: true,
      enableCaption: true,
      isLive: false,
    ),
  );

  return Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Container(
      width: MediaQuery.of(context).size.width, 
      height: 200,
      decoration: BoxDecoration(
        color: Colors.transparent, 
      ),
      child: ClipRRect(
        child: YoutubePlayer(
          controller: ytController,
          aspectRatio: 16 / 9,
        ),
      ),
    ),
  );
}
