import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:simple_connection_checker/simple_connection_checker.dart';
import 'package:songeet/API/songeet.dart';
import 'package:songeet/customWidgets/spinner.dart';

import 'package:songeet/style/app_colors.dart';

import '../services/audio_manager.dart';
import '../services/data_manager.dart';

class PlaylistBar extends StatefulWidget {
  const PlaylistBar(this.list, this.index, this.moveBackAfterPlay, {super.key});

  final dynamic list;

  final int index;
  final bool moveBackAfterPlay;

  @override
  State<PlaylistBar> createState() => _PlaylistBarState();
}

class _PlaylistBarState extends State<PlaylistBar> {
  late final songLikeStatus = ValueNotifier<bool>(
      isSongAlreadyLiked(widget.list[widget.index]['ytid']));
  RewardedInterstitialAd? _rewardedAd;

  @override
  void initState() {
    _createRewardedAd();
    super.initState();
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
        rewardedInterstitialAdLoadCallback:
            RewardedInterstitialAdLoadCallback(onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _rewardedAd = ad);
        }, onAdFailedToLoad: (error) {
          if (!mounted) return;
          setState(() => _rewardedAd = null);
        }));
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.list[widget.index];

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 5, top: 5),
      color: widget.index != id ? bgColor : Colors.red,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (songeetCoins.value > 0) {
            setActivePlaylist(widget.list, widget.index);
            songeetCoins.value = songeetCoins.value - 1;
            Hive.box('user').put('songeetCoins', songeetCoins.value);
            addOrUpdateData('user', 'activePlayList', activePlaylist);
          } else {
            coinBottomSheet(context);
          }

          if (widget.moveBackAfterPlay) {
            Navigator.pop(context);
          }
        },
        splashColor: accent.withOpacity(0.4),
        hoverColor: accent.withOpacity(0.4),
        focusColor: accent.withOpacity(0.4),
        highlightColor: accent.withOpacity(0.4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 100,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                shape: BoxShape.rectangle,
              ),
              child: CachedNetworkImage(
                alignment: Alignment.center,
                width: 100,
                height: 50,
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
                        size: 30,
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
            ),
            Flexible(
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 15),
                height: 50,
                child: Text(
                  // overflow: TextOverflow.ellipsis,
                  (song['title'])
                      .toString()
                      .split('(')[0]
                      .replaceAll('&quot;', '"')
                      .replaceAll('&amp;', '&'),
                  maxLines: 2,

                  style: TextStyle(
                    color: accent,

                    // fontSize: 16,
                    // fontWeight: FontWeight.w700,
                  ),
                ),
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
                  backgroundColor: accent.withOpacity(0.2),
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
