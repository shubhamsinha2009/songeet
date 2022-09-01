import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:just_audio/just_audio.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:on_audio_query/on_audio_query.dart';

import 'package:songeet/services/audio_manager.dart';
import 'package:songeet/style/app_colors.dart';
import 'package:songeet/ui/home.dart';
import 'package:songeet/ui/player.dart';

import '../services/new_version.dart';

class Songeet extends StatefulWidget {
  const Songeet({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return AppState();
  }
}

// ValueNotifier<int> activeTab = ValueNotifier<int>(0);

class AppState extends State<Songeet> {
  StreamSubscription? autoStartSubscription;
  bool isSongChanged = false;

  @override
  void initState() {
    super.initState();

    autoStartSubscription = audioPlayer.playerStateStream.listen((event) {
      if (event.processingState == ProcessingState.ready &&
          !(event.playing) &&
          isSongChanged == true) {
        play();
        isSongChanged = false;
      }
    });
    try {
      final newVersion = NewVersionPlus(androidId: "com.sks.songeet");

      newVersion.getVersionStatus().then(
        (status) {
          if (status != null && (status.localVersion != status.storeVersion)) {
            newVersion.showUpdateDialog(
              context: context,
              versionStatus: status,
              dialogTitle: 'Update Available',
              dialogText:
                  "What's New!\n${status.releaseNotes}\nYou can now update this app from ${status.localVersion} to ${status.storeVersion}",
            );
          }
        },
      );
    } catch (e) {
      // Fluttertoast.showToast(
      //   backgroundColor: accent,
      //   textColor: accent != const Color(0xFFFFFFFF)
      //       ? Colors.white
      //       : Colors.black,
      //   msg: "Unable to open App!",
      //   toastLength: Toast.LENGTH_SHORT,
      //   gravity: ToastGravity.BOTTOM,
      //   fontSize: 14,
      // );
    }
  }

  @override
  void dispose() {
    autoStartSubscription!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final pages = [
    //   const HomePage(),
    //   PlaylistsPage(),
    //   const SettingsPage(),
    // ];
    return Scaffold(
      bottomNavigationBar: getFooter(),
      body: const HomePage(),
      // ValueListenableBuilder<int>(
      //   valueListenable: activeTab,
      //   builder: (_, value, __) {
      //     return pages[value];
      //   },
      // ),
    );
  }

  Widget getFooter() {
    //   final items = <BottomNavBarItem>[
    //     BottomNavBarItem(
    //       icon: const Icon(MdiIcons.homeOutline),
    //       activeIcon: const Icon(MdiIcons.home),
    //       title: const Text('Home'),
    //       activeColor: accent,
    //       inactiveColor: Colors.white,
    //     ),
    //     // BottomNavBarItem(
    //     //   icon: const Icon(MdiIcons.magnifyMinusOutline),
    //     //   activeIcon: const Icon(MdiIcons.magnify),
    //     //   title: const Text('Search'),
    //     //   activeColor: accent,
    //     //   inactiveColor: Colors.white,
    //     // ),
    //     BottomNavBarItem(
    //       icon: const Icon(MdiIcons.bookOutline),
    //       activeIcon: const Icon(MdiIcons.book),
    //       title: const Text('Playlists'),
    //       activeColor: accent,
    //       inactiveColor: Colors.white,
    //     ),
    //     BottomNavBarItem(
    //       icon: const Icon(MdiIcons.cogOutline),
    //       activeIcon: const Icon(MdiIcons.cog),
    //       title: const Text('Settings'),
    //       activeColor: accent,
    //       inactiveColor: Colors.white,
    //     )
    //   ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<SequenceState?>(
          stream: audioPlayer.sequenceStateStream,
          builder: (context, snapshot) {
            final state = snapshot.data;
            if (state?.sequence.isEmpty ?? true) {
              return const SizedBox();
            }
            final metadata = state!.currentSource!.tag;
            isSongChanged = true;
            return Container(
              height: 75,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
                color: bgLight,
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 2),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AudioApp(),
                      ),
                    );
                  },
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(
                          MdiIcons.appleKeyboardControl,
                          size: 22,
                        ),
                        onPressed: null,
                        disabledColor: accent,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 7,
                          bottom: 7,
                          right: 15,
                        ),
                        child: metadata.extras['localSongId'] is int
                            ? QueryArtworkWidget(
                                id: metadata.extras['localSongId'] as int,
                                type: ArtworkType.AUDIO,
                                artworkBorder: BorderRadius.circular(8),
                                nullArtworkWidget: Icon(
                                  MdiIcons.musicNoteOutline,
                                  size: 30,
                                  color: accent,
                                ),
                                keepOldArtwork: true,
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: metadata.artUri.toString(),
                                  fit: BoxFit.fill,
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    width: 50,
                                    height: 50,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Icon(
                                          MdiIcons.musicNoteOutline,
                                          size: 30,
                                          color: accent,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      Padding(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              metadata!.title.toString().length > 15
                                  ? '${metadata!.title.toString().substring(0, 15)}...'
                                  : metadata!.title.toString(),
                              style: TextStyle(
                                color: accent,
                                // fontSize: 17,
                                // fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              metadata!.artist.toString().length > 15
                                  ? '${metadata!.artist.toString().substring(0, 15)}...'
                                  : metadata!.artist.toString(),
                              style: TextStyle(
                                color: accent,
                                // fontSize: 15,
                              ),
                            )
                          ],
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ValueListenableBuilder<PlayerState>(
                          valueListenable: playerState,
                          builder: (_, value, __) {
                            if (value.processingState ==
                                    ProcessingState.loading ||
                                value.processingState ==
                                    ProcessingState.buffering) {
                              return Container(
                                margin: const EdgeInsets.all(8),
                                width: MediaQuery.of(context).size.width * 0.08,
                                height:
                                    MediaQuery.of(context).size.width * 0.08,
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(accent),
                                ),
                              );
                            } else if (value.playing != true) {
                              return IconButton(
                                icon: Icon(MdiIcons.play, color: accent),
                                iconSize: 45,
                                onPressed: play,
                                splashColor: Colors.transparent,
                              );
                            } else if (value.processingState !=
                                ProcessingState.completed) {
                              return IconButton(
                                icon: Icon(MdiIcons.pause, color: accent),
                                iconSize: 45,
                                onPressed: pause,
                                splashColor: Colors.transparent,
                              );
                            } else {
                              return IconButton(
                                icon: Icon(MdiIcons.replay, color: accent),
                                iconSize: 45,
                                onPressed: () => audioPlayer.seek(
                                  Duration.zero,
                                  index: audioPlayer.effectiveIndices!.first,
                                ),
                                splashColor: Colors.transparent,
                              );
                            }
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // _buildBottomBar(items),
      ],
    );
  }

  // Widget _buildBottomBar(List<BottomNavBarItem> items) {
  //   return AnimatedContainer(
  //     duration: const Duration(milliseconds: 100),
  //     height: 65,
  //     child: CustomAnimatedBottomBar(
  //       backgroundColor: bgLight,
  //       onTap: (index) => activeTab.value = index,
  //       items: items,
  //       margin: const EdgeInsets.only(left: 8, right: 8),
  //     ),
  //   );
  // }
}
