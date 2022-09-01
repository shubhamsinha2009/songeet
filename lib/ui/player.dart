import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:just_audio/just_audio.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:songeet/API/songeet.dart';
import 'package:songeet/customWidgets/spinner.dart';

import 'package:songeet/services/audio_manager.dart';

import 'package:songeet/style/app_colors.dart';
import 'package:on_audio_query/on_audio_query.dart';

String status = 'hidden';

typedef OnError = void Function(Exception exception);

StreamSubscription? positionSubscription;
StreamSubscription? durationSubscription;

Duration? duration;
Duration? position;

enum MPlayerState { stopped, playing, paused, loading }

class AudioApp extends StatefulWidget {
  const AudioApp({Key? key}) : super(key: key);

  @override
  AudioAppState createState() => AudioAppState();
}

@override
class AudioAppState extends State<AudioApp> {
  @override
  void initState() {
    super.initState();

    positionSubscription = audioPlayer.positionStream
        .listen((p) => {if (mounted) setState(() => position = p)});
    durationSubscription = audioPlayer.durationStream.listen(
      (d) => {
        if (mounted) {setState(() => duration = d)}
      },
    );
  }

  @override
  void dispose() {
    positionSubscription!.cancel();
    durationSubscription!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        // elevation: 0,
        centerTitle: true,
        title: Text(
          "Now playing",
          style: TextStyle(
            color: accent,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: 32,
              color: accent,
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: size.height * 0.012),
          child: StreamBuilder<SequenceState?>(
            stream: audioPlayer.sequenceStateStream,
            builder: (context, snapshot) {
              final state = snapshot.data;
              if (state?.sequence.isEmpty ?? true) {
                return const SizedBox();
              }
              final metadata = state!.currentSource!.tag;
              final songLikeStatus = ValueNotifier<bool>(
                isSongAlreadyLiked(metadata.extras['ytid']),
              );
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (metadata.extras['localSongId'] is int)
                    QueryArtworkWidget(
                      id: metadata.extras['localSongId'] as int,
                      type: ArtworkType.AUDIO,
                      artworkBorder: BorderRadius.circular(8),
                      artworkQuality: FilterQuality.high,
                      quality: 100,
                      artworkWidth: size.width / 1.2,
                      artworkHeight: size.width / 1.2,
                      nullArtworkWidget: SizedBox(
                        width: size.width / 1.2,
                        height: size.width / 1.2,
                        child: CachedNetworkImage(
                          imageUrl: metadata.artUri.toString(),
                          imageBuilder: (context, imageProvider) =>
                              DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                          placeholder: (context, url) => const Spinner(),
                          errorWidget: (context, url, error) => Container(
                            width: size.width / 1.2,
                            height: size.width / 1.2,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [
                                  Color.fromARGB(30, 255, 255, 255),
                                  Color.fromARGB(30, 233, 233, 233),
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  MdiIcons.musicNoteOutline,
                                  size: size.width / 8,
                                  color: accent,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      keepOldArtwork: true,
                    )
                  else
                    SizedBox(
                      width: size.width / 1.2,
                      height: size.width / 1.2,
                      child: CachedNetworkImage(
                        imageUrl: metadata.artUri.toString(),
                        imageBuilder: (context, imageProvider) => DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                        placeholder: (context, url) => const Spinner(),
                        errorWidget: (context, url, error) => Container(
                          width: size.width / 1.2,
                          height: size.width / 1.2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [
                                Color.fromARGB(30, 255, 255, 255),
                                Color.fromARGB(30, 233, 233, 233),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                MdiIcons.musicNoteOutline,
                                size: size.width / 8,
                                color: accent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: size.height * 0.04,
                      bottom: size.height * 0.01,
                    ),
                    child: Column(
                      children: <Widget>[
                        Text(
                          metadata!.title
                              .toString()
                              .split(' (')[0]
                              .split('|')[0]
                              .trim(),
                          textScaleFactor: 2.5,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${metadata!.artist}',
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: accentLight,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    child: _buildPlayer(
                      size,
                      songLikeStatus,
                      metadata.extras['ytid'],
                      metadata,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer(
    Size size,
    ValueNotifier<bool> songLikeStatus,
    dynamic ytid,
    dynamic metadata,
  ) =>
      Container(
        padding: EdgeInsets.only(
          top: size.height * 0.01,
          left: 16,
          right: 16,
          bottom: size.height * 0.03,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (duration != null)
              Slider(
                activeColor: accent,
                inactiveColor: Colors.green[50],
                value: position?.inMilliseconds.toDouble() ?? 0.0,
                onChanged: (double? value) {
                  setState(() {
                    audioPlayer.seek(
                      Duration(
                        milliseconds: value!.round(),
                      ),
                    );
                    value = value;
                  });
                },
                max: duration!.inMilliseconds.toDouble(),
              ),
            if (position != null) _buildProgressView(),
            Padding(
              padding: EdgeInsets.only(top: size.height * 0.03),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        // if (metadata.extras['ytid'].toString().isNotEmpty)
                        //   Column(
                        //     children: [
                        // IconButton(
                        //   padding: EdgeInsets.zero,
                        //   icon: const Icon(
                        //     MdiIcons.download,
                        //     color: Colors.white,
                        //   ),
                        //   iconSize: size.width * 0.056,
                        //   splashColor: Colors.transparent,
                        //   onPressed: () {
                        //     downloadSong(
                        //       mediaItemToMap(metadata as MediaItem),
                        //     );
                        //   },
                        // ),
                        // IconButton(
                        //   padding: EdgeInsets.zero,
                        //   icon: Icon(
                        //     sponsorBlockSupport.value
                        //         ? MdiIcons.playCircle
                        //         : MdiIcons.playCircleOutline,
                        //     color: Colors.white,
                        //   ),
                        //   iconSize: size.width * 0.056,
                        //   splashColor: Colors.transparent,
                        //   onPressed: () =>
                        //       setState(changeSponsorBlockStatus),
                        // ),
                        //   ],
                        // ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            MdiIcons.shuffle,
                            color:
                                shuffleNotifier.value ? accent : Colors.white,
                          ),
                          iconSize: size.width * 0.056,
                          onPressed: changeShuffleStatus,
                          splashColor: Colors.transparent,
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.skip_previous,
                            color: hasPrevious ? Colors.white : Colors.grey,
                            size: size.width * 0.1,
                          ),
                          iconSize: size.width * 0.056,
                          onPressed: playPrevious,
                          splashColor: Colors.transparent,
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: ValueListenableBuilder<PlayerState>(
                            valueListenable: playerState,
                            builder: (_, value, __) {
                              if (value.processingState ==
                                      ProcessingState.loading ||
                                  value.processingState ==
                                      ProcessingState.buffering) {
                                return Container(
                                  margin: const EdgeInsets.all(8),
                                  width: size.width * 0.08,
                                  height: size.width * 0.08,
                                  child: const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromARGB(255, 0, 0, 0),
                                    ),
                                  ),
                                );
                              } else if (value.playing != true) {
                                return IconButton(
                                  icon: const Icon(MdiIcons.play),
                                  iconSize: size.width * 0.1,
                                  onPressed: play,
                                  splashColor: Colors.transparent,
                                );
                              } else if (value.processingState !=
                                  ProcessingState.completed) {
                                return IconButton(
                                  icon: const Icon(MdiIcons.pause),
                                  iconSize: size.width * 0.1,
                                  onPressed: pause,
                                  splashColor: Colors.transparent,
                                );
                              } else {
                                return IconButton(
                                  icon: const Icon(MdiIcons.replay),
                                  iconSize: size.width * 0.056,
                                  onPressed: () => audioPlayer.seek(
                                    Duration.zero,
                                    index: audioPlayer.effectiveIndices!.first,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.skip_next,
                            color: hasNext ? Colors.white : Colors.grey,
                            size: size.width * 0.1,
                          ),
                          iconSize: size.width * 0.08,
                          onPressed: playNext,
                          splashColor: Colors.transparent,
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            MdiIcons.repeat,
                            color: repeatNotifier.value ? accent : Colors.white,
                          ),
                          iconSize: size.width * 0.056,
                          onPressed: changeLoopStatus,
                          splashColor: Colors.transparent,
                        ),
                        // if (metadata.extras['ytid'].toString().isNotEmpty)
                        //   Column(
                        //     children: [
                        //       ValueListenableBuilder<bool>(
                        //         valueListenable: songLikeStatus,
                        //         builder: (_, value, __) {
                        //           if (value == true) {
                        //             return IconButton(
                        //               color: accent,
                        //               icon: const Icon(MdiIcons.star),
                        //               iconSize: size.width * 0.056,
                        //               splashColor: Colors.transparent,
                        //               onPressed: () => {
                        //                 removeUserLikedSong(ytid),
                        //                 songLikeStatus.value = false
                        //               },
                        //             );
                        //           } else {
                        //             return IconButton(
                        //               color: Colors.white,
                        //               icon: const Icon(MdiIcons.starOutline),
                        //               iconSize: size.width * 0.056,
                        //               splashColor: Colors.transparent,
                        //               onPressed: () => {
                        //                 addUserLikedSong(ytid),
                        //                 songLikeStatus.value = true
                        //               },
                        //             );
                        //           }
                        //         },
                        //       ),
                        //       ValueListenableBuilder<bool>(
                        //         valueListenable: playNextSongAutomatically,
                        //         builder: (_, value, __) {
                        //           return IconButton(
                        //             padding: EdgeInsets.zero,
                        //             icon: Icon(
                        //               value
                        //                   ? MdiIcons.skipNextCircle
                        //                   : MdiIcons.skipNextCircleOutline,
                        //               color: value ? accent : Colors.white,
                        //             ),
                        //             iconSize: size.width * 0.056,
                        //             splashColor: Colors.transparent,
                        //             onPressed: changeAutoPlayNextStatus,
                        //           );
                        //         },
                        //       ),
                        //     ],
                        //   ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (metadata.extras['ytid'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: songLikeStatus,
                      builder: (_, value, __) {
                        if (value == true) {
                          return IconButton(
                            color: accent,
                            icon: const Icon(MdiIcons.star),
                            iconSize: size.width * 0.056,
                            splashColor: Colors.transparent,
                            onPressed: () => {
                              removeUserLikedSong(ytid),
                              songLikeStatus.value = false
                            },
                          );
                        } else {
                          return IconButton(
                            color: Colors.white,
                            icon: const Icon(MdiIcons.starOutline),
                            iconSize: size.width * 0.056,
                            splashColor: Colors.transparent,
                            onPressed: () => {
                              addUserLikedSong(ytid),
                              songLikeStatus.value = true
                            },
                          );
                        }
                      },
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: playNextSongAutomatically,
                      builder: (_, value, __) {
                        return IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            value
                                ? MdiIcons.skipNextCircle
                                : MdiIcons.skipNextCircleOutline,
                            color: value ? accent : Colors.white,
                          ),
                          iconSize: size.width * 0.056,
                          splashColor: Colors.transparent,
                          onPressed: changeAutoPlayNextStatus,
                        );
                      },
                    ),

                    // IconButton(
                    //   padding: EdgeInsets.zero,
                    //   icon: const Icon(
                    //     MdiIcons.download,
                    //     color: Colors.white,
                    //   ),
                    //   iconSize: size.width * 0.056,
                    //   splashColor: Colors.transparent,
                    //   onPressed: () {
                    //     downloadSong(
                    //       mediaItemToMap(metadata as MediaItem),
                    //     );
                    //   },
                    // ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        sponsorBlockSupport.value
                            ? MdiIcons.playCircle
                            : MdiIcons.playCircleOutline,
                        color: Colors.white,
                      ),
                      iconSize: size.width * 0.056,
                      splashColor: Colors.transparent,
                      onPressed: () => setState(changeSponsorBlockStatus),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );

  Row _buildProgressView() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            position != null
                ? '$positionText '.replaceFirst('0:0', '0')
                : duration != null
                    ? durationText
                    : '',
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          const Spacer(),
          Text(
            position != null
                ? durationText.replaceAll('0:', '')
                : duration != null
                    ? durationText
                    : '',
            style: const TextStyle(fontSize: 18, color: Colors.white),
          )
        ],
      );
}
