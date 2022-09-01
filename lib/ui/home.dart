import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:songeet/API/songeet.dart';
import 'package:songeet/customWidgets/delayed_display.dart';
import 'package:songeet/customWidgets/song_bar.dart';
import 'package:songeet/customWidgets/spinner.dart';
import 'package:songeet/style/app_colors.dart';
import 'package:songeet/ui/playlist.dart';
import 'package:songeet/ui/settings.dart';
import 'package:songeet/ui/voice_search.dart';

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
      print(value);
      if (value.contains("https://youtu.be/")) {
        value = value.replaceAll("https://youtu.be/", "");
        getSongDetails(1, value).then((value) {
          playSong(value);
        });
      } else if (value.contains("https://youtube.com/playlist?list=")) {
        // value = value.replaceAll("https://youtube.com/playlist?list=", "");
        // yt.playlists.get(value).then((value) {
        //   chipsList.add(
        //     Tech(value.title, value.id.toString()),
        //   );
        //   addOrUpdateData('settings', 'chipsList', chipsList);

        // });
        // chipsList.add(value);
      }
    }, onError: (err) {
      //print("getLinkStream error: $err");
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String? value) {
      if (value != null) {
        print(value);
        if (value.contains("https://youtu.be/")) {
          value = value.replaceAll("https://youtu.be/", "");
          getSongDetails(1, value).then((value) {
            playSong(value);
          });
        } else if (value.contains("https://youtube.com/playlist?list=")) {
          //value = value.replaceAll("https://youtube.com/playlist?list=", "");
          // yt.playlists.get(value).then((value) {
          //   chipsList.add(
          //     Tech(value.title, value.id.toString()),
          //   );
          //   setState(() {
          //     selectedIndex = chipsList.length - 1;
          //   });
          //   addOrUpdateData('settings', 'chipsList', chipsList);
          //   addOrUpdateData('settings', 'selectedIndex', selectedIndex);

          // });
        }
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgColor,
        //centerTitle: true,
        leading: Image.asset("assets/splash.png"),
        leadingWidth: 35,
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
            icon: const Icon(MdiIcons.magnify),
            onPressed: () =>
                showSearch(context: context, delegate: MySearchDelegate()),
          ),
          IconButton(
            alignment: Alignment.center,
            color: accent,
            icon: const Icon(MdiIcons.cog),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                )),
          )
        ],
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
                      (data as dynamic).data[index],
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
                      (data as dynamic).data[index],
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
              leading: Icon(Icons.search, color: accent),
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

class CubeContainer extends StatelessWidget {
  const CubeContainer({
    Key? key,
    required this.id,
    required this.image,
  }) : super(key: key);
  final String id;
  final String image;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return DelayedDisplay(
      delay: const Duration(milliseconds: 200),
      fadingDuration: const Duration(milliseconds: 400),
      child: GestureDetector(
        onTap: () {
          getPlaylistInfoForWidget(id).then(
            (value) => {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaylistPage(playlist: value),
                ),
              )
            },
          );
        },
        child: Column(
          children: [
            SizedBox(
              height: size.height / 4.15,
              width: size.width / 1.9,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                color: Colors.transparent,
                child: CachedNetworkImage(
                  imageUrl: image,
                  imageBuilder: (context, imageProvider) => DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => DecoratedBox(
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
                          size: 30,
                          color: accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final playlistChips = [
  Tech('Recents', ''),
  Tech('Liked', ''),
  Tech('Trending India', 'PL_yIBWagYVjwNqH1Ay2cnHBgfh2Lu35nd'),
  Tech('Top Global', 'PL4fGSI1pDJn5kI81J1fYWK5eZRl1zJ5kM'),
  Tech('90s', 'RDCLAK5uy_kiDNaS5nAXxdzsqFElFKKKs0GUEFJE26w'),
  Tech('Pop', 'RDCLAK5uy_nmS3YoxSwVVQk9lEQJ0UX4ZCjXsW_psU8'),
  Tech('Bhakti', 'PL4A029DE14CB39A57'),
  Tech('Iconic', 'RDCLAK5uy_ne9LK1yhdHJsvZNIsmDirK1WT-sl7q8sQ'),
  Tech('Ghazal', 'RDCLAK5uy_nusa99pjb23HT86uCZf-JW2rjJIGnpp_g'),
  Tech('Hip Hop', 'RDCLAK5uy_kw2wIlEv9llILhO0qoMTLsBBhmjzuibAc'),
];
