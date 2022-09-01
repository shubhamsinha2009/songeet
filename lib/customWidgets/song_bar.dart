import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:songeet/API/songeet.dart';
import 'package:songeet/customWidgets/spinner.dart';
import 'package:songeet/services/audio_manager.dart';

import 'package:songeet/style/app_colors.dart';

class SongBar extends StatelessWidget {
  SongBar(this.song, this.moveBackAfterPlay, {super.key});

  late final dynamic song;
  late final bool moveBackAfterPlay;
  late final songLikeStatus =
      ValueNotifier<bool>(isSongAlreadyLiked(song['ytid']));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 15),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          playSong(song);
          if (activePlaylist.isNotEmpty) {
            activePlaylist = [];
            id = 0;
          }
          if (moveBackAfterPlay) {
            Navigator.pop(context);
          }
        },
        onLongPress: () {
          playSong(song);
          if (activePlaylist.isNotEmpty) {
            activePlaylist = [];
            id = 0;
          }
          if (moveBackAfterPlay) {
            Navigator.pop(context);
          }
        },
        onDoubleTap: () {
          if (songLikeStatus.value == true) {
            removeUserLikedSong(song['ytid']);
            songLikeStatus.value = false;
          } else {
            addUserLikedSong(song['ytid']);
            songLikeStatus.value = true;
          }
        },
        splashColor: accent.withOpacity(0.4),
        hoverColor: accent.withOpacity(0.4),
        focusColor: accent.withOpacity(0.4),
        highlightColor: accent.withOpacity(0.4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              width: 180,
              height: 101,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                shape: BoxShape.rectangle,
              ),
              child: Stack(children: [
                CachedNetworkImage(
                  width: 180,
                  height: 101,
                  imageUrl: song['image'].toString(),
                  placeholder: (context, url) => const Spinner(),
                  errorWidget: (context, url, error) => Container(
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
                          size: 50,
                          color: accent,
                        ),
                      ],
                    ),
                  ),
                  imageBuilder: (context, imageProvider) => DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    margin: const EdgeInsets.all(4.0),
                    padding: const EdgeInsets.all(4.0),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    child: Text(
                      song['duration'],
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Align(
                //   alignment: Alignment.bottomLeft,
                //   child: Container(
                //     alignment: Alignment.center,
                //     height: 20,
                //     width: 20,
                //     margin: const EdgeInsets.all(4.0),
                //     // padding: const EdgeInsets.all(4.0),
                //     decoration: const BoxDecoration(
                //       color: Colors.black,
                //       borderRadius: BorderRadius.all(
                //         Radius.circular(10),
                //       ),
                //     ),
                //     child: IconButton(
                //         alignment: Alignment.center,
                //         color: accent,
                //         icon: const Icon(MdiIcons.download),
                //         iconSize: 10,
                //         splashColor: Colors.transparent,
                //         onPressed: () => null // downloadSong(song),
                //         ),
                //   ),
                // ),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    alignment: Alignment.center,
                    height: 30,
                    width: 30,
                    margin: const EdgeInsets.all(4.0),
                    // padding: const EdgeInsets.all(4.0),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: songLikeStatus,
                      builder: (_, value, __) {
                        if (value == true) {
                          return IconButton(
                            alignment: Alignment.center,
                            color: accent,
                            icon: const Icon(MdiIcons.heart),
                            iconSize: 15,
                            splashColor: Colors.transparent,
                            onPressed: () => {
                              removeUserLikedSong(song['ytid']),
                              songLikeStatus.value = false
                            },
                          );
                        } else {
                          return IconButton(
                            alignment: Alignment.center,
                            color: accent,
                            icon: const Icon(MdiIcons.heartOutline),
                            iconSize: 15,
                            splashColor: Colors.transparent,
                            onPressed: () => {
                              addUserLikedSong(song['ytid']),
                              songLikeStatus.value = true
                            },
                          );
                        }
                      },
                    ),
                  ),
                ),
              ]),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 15),
                    child: Text(
                      // overflow: TextOverflow.ellipsis,
                      (song['title'])
                          .toString()
                          .split('(')[0]
                          .replaceAll('&quot;', '"')
                          .replaceAll('&amp;', '&'),
                      style: TextStyle(
                        color: accent,
                        // fontSize: 16,
                        // fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 15),
                    child: Text(
                      //  overflow: TextOverflow.ellipsis,
                      song['more_info']['singers'].toString(),
                      style: const TextStyle(
                        color: Colors.white70,
                        // fontWeight: FontWeight.w400,
                        // fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Row(
            //   mainAxisSize: MainAxisSize.min,
            //   children: [
            //     ValueListenableBuilder<bool>(
            //       valueListenable: songLikeStatus,
            //       builder: (_, value, __) {
            //         if (value == true) {
            //           return IconButton(
            //             color: accent,
            //             icon: const Icon(MdiIcons.star),
            //             onPressed: () => {
            //               removeUserLikedSong(song['ytid']),
            //               songLikeStatus.value = false
            //             },
            //           );
            //         } else {
            //           return IconButton(
            //             color: accent,
            //             icon: const Icon(MdiIcons.starOutline),
            //             onPressed: () => {
            //               addUserLikedSong(song['ytid']),
            //               songLikeStatus.value = true
            //             },
            //           );
            //         }
            //       },
            //     ),
            // IconButton(
            //   color: accent,
            //   icon: const Icon(MdiIcons.downloadOutline),
            //   onPressed: () => downloadSong(song),
            // ),
            //],
            //),
          ],
        ),
      ),
    );
  }
}
