import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:songeet/API/songeet.dart';
import 'package:simple_connection_checker/simple_connection_checker.dart';
import 'package:songeet/customWidgets/song_bar.dart';
import 'package:songeet/customWidgets/spinner.dart';
import 'package:songeet/style/app_colors.dart';

import 'package:songeet/ui/settings.dart';
import 'package:songeet/ui/voice_search.dart';

import '../main.dart';
import '../model/play.dart';
import '../services/audio_manager.dart';
import '../services/data_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final scrollController = ScrollController(
      initialScrollOffset: Hive.box('user').get('scroll', defaultValue: 0.0));
  late StreamSubscription _intentDataStreamSubscription;
  int selectedIndex =
      Hive.box('settings').get('selectedIndex', defaultValue: 2) as int;
  RewardedInterstitialAd? _rewardedAd;
  StreamSubscription? subscription;
  final SimpleConnectionChecker _simpleConnectionChecker =
      SimpleConnectionChecker();

  Future<dynamic> getPlay() {
    if (chipsList.elementAt(selectedIndex).label.compareTo('Recents') == 0) {
      return getHistoryMusic();
    } else if (chipsList.elementAt(selectedIndex).label.compareTo('Liked') ==
        0) {
      return getFavMusic();
    } else {
      return getSongsFromPlaylist(chipsList[selectedIndex].playlistID);
    }
    // return _chipsList.elementAt(selectedIndex).label.compareTo('Recents') == 0
    //     ? getHistoryMusic()
    //     : get20Music(_chipsList[selectedIndex].playlistID);
  }

  List chipsList =
      Hive.box('settings').get('chipsList', defaultValue: playlistChips);
  @override
  void initState() {
    if (chipsList.length < playlistChips.length) {
      chipsList.addAll(playlistChips.sublist(chipsList.length));
      addOrUpdateData('settings', 'chipsList', chipsList);
    }

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
      //  print(value);
      if (value.contains("https://youtu.be/")) {
        value = value.replaceAll("https://youtu.be/", "");
        getSongDetails(1, value).then((value) {
          if (songeetCoins.value > 0) {
            songeetCoins.value = songeetCoins.value - 1;
            Hive.box('user').put('songeetCoins', songeetCoins.value);
            playSong(value);
          } else {
            coinBottomSheet(context);
          }
        });
      } else if (value.contains("https://youtube.com/playlist?list=")) {
        value = value.replaceAll("https://youtube.com/playlist?list=", "");
        yt.playlists.get(value).then((value) {
          setState(() {
            chipsList.insert(
              3,
              Tech(value.title.trim().split(' ').sublist(0, 2).join(' '),
                  value.id.toString()),
            );

            selectedIndex = 3;
            scrollController.jumpTo(
              0.0,
            );
          });
          addOrUpdateData('settings', 'chipsList', chipsList);
          addOrUpdateData('settings', 'selectedIndex', selectedIndex);
          Hive.box('user').put('scroll', scrollController.offset);
        });
      }
    }, onError: (err) {
      //print("getLinkStream error: $err");
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String? value) {
      if (value != null) {
        // print(value);
        if (value.contains("https://youtu.be/")) {
          value = value.replaceAll("https://youtu.be/", "");
          getSongDetails(1, value).then((value) {
            if (songeetCoins.value > 0) {
              songeetCoins.value = songeetCoins.value - 1;
              Hive.box('user').put('songeetCoins', songeetCoins.value);
              playSong(value);
            } else {
              coinBottomSheet(context);
            }
          });
        } else if (value.contains("https://youtube.com/playlist?list=")) {
          value = value.replaceAll("https://youtube.com/playlist?list=", "");
          setState(() {
            yt.playlists.get(value).then((value) {
              chipsList.insert(
                3,
                Tech(value.title.trim().split(' ').sublist(0, 2).join(' '),
                    value.id.toString()),
              );

              selectedIndex = chipsList.length - 1;
              scrollController.jumpTo(
                0.0,
              );
            });
            addOrUpdateData('settings', 'chipsList', chipsList);
            addOrUpdateData('settings', 'selectedIndex', selectedIndex);
            Hive.box('user').put('scroll', scrollController.offset);
          });
        }
      }
    });

    _createRewardedAd();
    subscription =
        _simpleConnectionChecker.onConnectionChange.listen((connected) {
      if (!connected) {
        Fluttertoast.showToast(
          backgroundColor: accent,
          textColor: Colors.black,
          msg: "No Internet",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          fontSize: 14,
        );
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();

    subscription?.cancel();
    super.dispose();
  }

  void _showRewardedAd() {
    if (songeetCoins.value < 40) {
      if (_rewardedAd != null) {
        _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _createRewardedAd();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _createRewardedAd();
          },
        );
        _rewardedAd!.show(
          onUserEarnedReward: (ad, reward) {
            setState(() {
              songeetCoins.value = songeetCoins.value + reward.amount as int;
              Hive.box('user').put('songeetCoins', songeetCoins.value);
            });
          },
        );
        _rewardedAd = null;
      } else {
        if (songeetCoins.value < 5) {
          setState(() {
            songeetCoins.value = songeetCoins.value + 5;
            Hive.box('user').put('songeetCoins', songeetCoins.value);
          });
        }
      }
    }
  }

  void _createRewardedAd() {
    RewardedInterstitialAd.load(
        adUnitId: "ca-app-pub-7429449747123334/1952744609",
        request: const AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          onAdLoaded: (ad) => setState(() => _rewardedAd = ad),
          onAdFailedToLoad: (error) => setState(() => _rewardedAd = null),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgColor,
        //centerTitle: true,
        // leading: Image.asset("assets/splash.png"),
        // leadingWidth: 30,
        title: Text(
          'Songeet',
          style: TextStyle(
            color: accent,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        // elevation: 0,
        actions: [
          IconButton(
              alignment: Alignment.center,
              color: accent,
              icon: const Icon(
                MdiIcons.shapeOutline,
              ),
              onPressed: () => showModalBottomSheet(
                  isDismissible: true,
                  backgroundColor: Colors.transparent,
                  context: context,
                  builder: (BuildContext context) {
                    final colors = <int>[
                      0xFFFFFFFF,
                      0xFFFFCDD2,
                      0xFFF8BBD0,
                      0xFFE1BEE7,
                      0xFFD1C4E9,
                      0xFFC5CAE9,
                      0xFF8C9EFF,
                      0xFFBBDEFB,
                      0xFF82B1FF,
                      0xFFB3E5FC,
                      0xFF80D8FF,
                      0xFFB2EBF2,
                      0xFF84FFFF,
                      0xFFB2DFDB,
                      0xFFA7FFEB,
                      0xFFC8E6C9,
                      0xFFACE1AF,
                      0xFFB9F6CA,
                      0xFFDCEDC8,
                      0xFFCCFF90,
                      0xFFF0F4C3,
                      0xFFF4FF81,
                      0xFFFFF9C4,
                      0xFFFFFF8D,
                      0xFFFFECB3,
                      0xFFFFE57F,
                      0xFFFFE0B2,
                      0xFFFFD180,
                      0xFFFFCCBC,
                      0xFFFF9E80,
                      0xFFFD5C63,
                    ];
                    return Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          border: Border.all(
                            color: accent,
                          ),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(20),
                          ),
                        ),
                        width:
                            MediaQuery.of(context).copyWith().size.width * 0.90,
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                          ),
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: colors.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                top: 15,
                                bottom: 15,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (colors.length > index)
                                    GestureDetector(
                                      onTap: () {
                                        addOrUpdateData(
                                          'settings',
                                          'accentColor',
                                          colors[index],
                                        );
                                        MyApp.setAccentColor(
                                          context,
                                          Color(colors[index]),
                                        );
                                        Fluttertoast.showToast(
                                          backgroundColor: accent,
                                          textColor:
                                              accent != const Color(0xFFFFFFFF)
                                                  ? Colors.white
                                                  : Colors.black,
                                          msg: "Accent color has been changed",
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.BOTTOM,
                                          fontSize: 14,
                                        );
                                        Navigator.pop(context);
                                      },
                                      child: Material(
                                        elevation: 4,
                                        shape: const CircleBorder(),
                                        child: CircleAvatar(
                                          radius: 25,
                                          backgroundColor: Color(
                                            colors[index],
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink()
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  })),
          // IconButton(
          //   alignment: Alignment.center,
          //   color: accent,
          //   icon: const Icon(MdiIcons.magnify),
          //   onPressed: () =>
          //       showSearch(context: context, delegate: MySearchDelegate()),
          // ),

          IconButton(
            alignment: Alignment.center,
            color: accent,
            icon: const Icon(MdiIcons.cog),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                )),
          ),
          ActionChip(
            backgroundColor: accent.withOpacity(0.1),
            onPressed: () => coinBottomSheet(context),
            // padding: const EdgeInsets.only(right: 5),

            label: ValueListenableBuilder(
                valueListenable: songeetCoins,
                builder: (context, value, child) {
                  return Text(
                    '${songeetCoins.value}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: accent,
                    ),
                  );
                }),
            avatar: Icon(MdiIcons.alphaSCircle, color: accent),
            // labelPadding: const EdgeInsets.only(
            //   left: 5,
            // ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accent,

        label: Text(
          "Search",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: bgLight,
          ),
        ),
        //foregroundColor: accent.withOpacity(0.3),
        onPressed: () =>
            showSearch(context: context, delegate: MySearchDelegate()),
        icon: Icon(
          MdiIcons.magnify,
          color: bgLight,
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ReorderableListView.builder(
              scrollController: scrollController,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex = newIndex - 1;
                  }

                  final element = chipsList.removeAt(oldIndex);
                  chipsList.insert(newIndex, element);
                });
                addOrUpdateData('settings', 'chipsList', chipsList);
              },
              itemCount: chipsList.length,
              itemBuilder: (context, index) {
                return Padding(
                  key: ValueKey(index),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    visualDensity: VisualDensity.adaptivePlatformDensity,
                    label: Text(
                      chipsList[index].label,
                      style: TextStyle(
                        color: selectedIndex == index ? bgLight : accent,
                        fontSize: 13,
                        // fontWeight: FontWeight.w700,
                      ),
                    ),
                    selected: selectedIndex == index,
                    selectedColor: accent,
                    backgroundColor: Colors.white12,
                    onSelected: (bool value) {
                      setState(() {
                        selectedIndex = index;
                      });
                      addOrUpdateData('settings', 'selectedIndex', index);
                      Hive.box('user').put('scroll', scrollController.offset);
                    },
                  ),
                );
              },
              padding: const EdgeInsets.symmetric(horizontal: 7),
              // shrinkWrap: true,
              scrollDirection: Axis.horizontal,
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: getPlay(),
              builder: (context, data) {
                if (data.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(35),
                      child: Spinner(),
                    ),
                  );
                }
                if (data.hasError) {
                  // print(data.error);
                  return Center(
                    child: Text(
                      'Error!',
                      style: TextStyle(color: accent, fontSize: 18),
                    ),
                  );
                }
                if (!data.hasData) {
                  return Center(
                    child: Text(
                      'Nothing Found!',
                      style: TextStyle(color: accent, fontSize: 18),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  shrinkWrap: true,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                  physics: const BouncingScrollPhysics(),
                  itemCount: (data as dynamic).data.length as int,
                  itemBuilder: (context, index) {
                    return SongBar(
                      (data as dynamic).data,
                      index,
                      false,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<dynamic> coinBottomSheet(BuildContext context) {
    return showModalBottomSheet(
      isDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.all(
                Radius.circular(20),
              ),
            ),
            height: MediaQuery.of(context).copyWith().size.height * 0.80,
            width: MediaQuery.of(context).copyWith().size.width * 0.90,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Songeet Coins',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Chip(
                  backgroundColor: accent.withOpacity(0.1),
                  label: ValueListenableBuilder(
                      valueListenable: songeetCoins,
                      builder: (context, value, child) {
                        return Text(
                          '$value',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: accent,
                            fontSize: 30,
                          ),
                        );
                      }),
                  avatar: Icon(
                    MdiIcons.alphaSCircle,
                    color: accent,
                    size: 33,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  'Number of Songeet Coins\n = \nNumber of Songs you can play',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: accent,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  'Not have enough coins to play songs?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: accent,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: () {
                    SimpleConnectionChecker.isConnectedToInternet()
                        .then((isConnected) {
                      if (isConnected) {
                        _showRewardedAd();
                      } else {
                        Fluttertoast.showToast(
                          backgroundColor: accent,
                          textColor: Colors.black,
                          msg: "No Internet",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          fontSize: 14,
                        );
                      }
                      Navigator.pop(context, false);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    primary: accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Watch Rewarded Ads to get more coins",
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ));
      },
    );
  }
}

// TODO: Error
class MySearchDelegate extends SearchDelegate {
  List searchHistory = Hive.box('user').get('searchHistory', defaultValue: []);
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      query.isEmpty
          ? IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VoiceSearchPage(),
                  ),
                ).then((value) {
                  if (value != null && value.isNotEmpty) {
                    query = value;
                    showResults(context);
                  }
                });
              },
              alignment: Alignment.center,
              color: accent,
              icon: const Icon(MdiIcons.microphone),
            )
          : IconButton(
              onPressed: () {
                if (query.isEmpty) {
                  close(context, null);
                } else {
                  query = '';
                }
              },
              alignment: Alignment.center,
              color: accent,
              icon: const Icon(MdiIcons.close),
            ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      alignment: Alignment.center,
      color: accent,
      icon: const Icon(MdiIcons.keyboardBackspace),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isNotEmpty) {
      searchHistory.remove(query);
      searchHistory.insert(0, query);
      addOrUpdateData('user', 'searchHistory', searchHistory);
    }
    return FutureBuilder(
      future: fetchSongsList(query),
      builder: (context, data) {
        return (data as dynamic).data != null
            ? ListView.builder(
                shrinkWrap: true,
                itemCount: (data as dynamic).data.length,
                itemBuilder: (BuildContext ctxt, int index) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 5),
                    child: SongBar(
                      (data as dynamic).data,
                      index,
                      true,
                    ),
                  );
                },
              )
            : const Spinner();
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List suggestions = searchHistory;

    suggestions = searchHistory.where((searchResults) {
      final result = searchResults.toString().toLowerCase();
      final input = query.toLowerCase();
      return result.contains(input);
    }).toList();
    return ListView.builder(
      shrinkWrap: true,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: suggestions.length,
      itemBuilder: (BuildContext ctxt, int index) {
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Card(
            color: bgLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2.3,
            child: ListTile(
              leading: Icon(MdiIcons.magnify, color: accent),
              title: Text(
                suggestions[index],
                style: TextStyle(color: accent),
              ),
              onTap: () {
                query = suggestions[index];
                showResults(context);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
        backgroundColor: bgColor,
        hintColor: accent,
        textTheme: TextTheme(headline6: TextStyle(color: accent)));
  }
}

// class CubeContainer extends StatelessWidget {
//   const CubeContainer({
//     Key? key,
//     required this.id,
//     required this.image,
//   }) : super(key: key);
//   final String id;
//   final String image;

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     return DelayedDisplay(
//       delay: const Duration(milliseconds: 200),
//       fadingDuration: const Duration(milliseconds: 400),
//       child: GestureDetector(
//         onTap: () {
//           getPlaylistInfoForWidget(id).then(
//             (value) => {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => PlaylistPage(playlist: value),
//                 ),
//               )
//             },
//           );
//         },
//         child: Column(
//           children: [
//             SizedBox(
//               height: size.height / 4.15,
//               width: size.width / 1.9,
//               child: Card(
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 color: Colors.transparent,
//                 child: CachedNetworkImage(
//                   imageUrl: image,
//                   imageBuilder: (context, imageProvider) => DecoratedBox(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(10),
//                       image: DecorationImage(
//                         image: imageProvider,
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                   ),
//                   errorWidget: (context, url, error) => DecoratedBox(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(10),
//                       gradient: const LinearGradient(
//                         colors: [
//                           Color.fromARGB(30, 255, 255, 255),
//                           Color.fromARGB(30, 233, 233, 233),
//                         ],
//                       ),
//                     ),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: <Widget>[
//                         Icon(
//                           MdiIcons.musicNoteOutline,
//                           size: 30,
//                           color: accent,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

final playlistChips = [
  Tech('Recents', ''),
  Tech('Liked', ''),
  Tech('Trending India', 'PL_yIBWagYVjwNqH1Ay2cnHBgfh2Lu35nd'),
  Tech('Top Global', 'PL4fGSI1pDJn5kI81J1fYWK5eZRl1zJ5kM'),
  Tech('90s', 'RDCLAK5uy_kiDNaS5nAXxdzsqFElFKKKs0GUEFJE26w'),
  Tech('Bhakti', 'PL4A029DE14CB39A57'),
  Tech('Iconic', 'RDCLAK5uy_ne9LK1yhdHJsvZNIsmDirK1WT-sl7q8sQ'),
  Tech('Ghazal', 'RDCLAK5uy_nusa99pjb23HT86uCZf-JW2rjJIGnpp_g'),
  Tech('Praveen', 'PL8A8KVPHHokwbOL5LrW2Nqx0n8_dlDlgt'),
  Tech('Bauaa', 'PL8A8KVPHHokwY3cli7nFIpLlw5I9eUU5U'),
  Tech('Naved', 'PL6nrcSSxq4K9ykGn_rvvgagy4mhL3gRJG'),
];
