import 'dart:convert';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:songeet/helper/formatter.dart';
import 'package:songeet/helper/mediaitem.dart';
import 'package:songeet/services/audio_handler.dart';
import 'package:songeet/services/audio_manager.dart';
import 'package:songeet/services/data_manager.dart';

import 'package:on_audio_query/on_audio_query.dart';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final yt = YoutubeExplode();
//final OnAudioQuery _audioQuery = OnAudioQuery();

final random = Random();

List ytplaylists = [];
List playlists = [];
List userPlaylists = Hive.box('user').get('playlists', defaultValue: []);
List userLikedSongsList = Hive.box('user').get('likedSongs', defaultValue: []);
List suggestedPlaylists = [];
List activePlaylist = [];
List<SongModel> localSongs = [];

int id = 0;

Future<List> fetchSongsList(String searchQuery) async {
  final List list = await yt.search.search(searchQuery);
  final searchedList = [
    for (final s in list)
      returnSongLayout(
        0,
        s.id.toString(),
        formatSongTitle(
          s.title.split('-')[s.title.split('-').length - 1].toString(),
        ),
        s.thumbnails.standardResUrl.toString(),
        s.thumbnails.lowResUrl.toString(),
        s.thumbnails.maxResUrl.toString(),
        s.title.split('-')[0].toString(),
        printDuration(s.duration),
      )
  ];

  return searchedList;
}

Future get20Music(dynamic playlistid) async {
  final List playlistSongs = [];
  //   await getData('cache', 'playlist10Songs$playlistid') ?? [];
  if (playlistSongs.isEmpty) {
    var index = 0;
    await for (final song in yt.playlists.getVideos(playlistid).take(20)) {
      playlistSongs.add(
        returnSongLayout(
          index,
          song.id.toString(),
          formatSongTitle(
            song.title.split('-')[song.title.split('-').length - 1],
          ),
          song.thumbnails.standardResUrl,
          song.thumbnails.lowResUrl,
          song.thumbnails.maxResUrl,
          song.author,
          printDuration(song.duration),
        ),
      );
      index += 1;
    }

    //  addOrUpdateData('cache', 'playlist10Songs$playlistid', playlistSongs);
  }

  return playlistSongs;
}

Future getHistoryMusic() async {
  final List playlistSongs = await getData('user', 'songHistory') ?? [];
  // if (playlistSongs.isEmpty) {
  //   var index = 0;
  //   await for (final song in yt.playlists.getVideos(playlistid).take(20)) {
  //     playlistSongs.add(
  //       returnSongLayout(
  //         index,
  //         song.id.toString(),
  //         formatSongTitle(
  //           song.title.split('-')[song.title.split('-').length - 1],
  //         ),
  //         song.thumbnails.standardResUrl,
  //         song.thumbnails.lowResUrl,
  //         song.thumbnails.maxResUrl,
  //         song.author,
  //         printDuration(song.duration),
  //       ),
  //     );
  //     index += 1;
  //   }

  //   addOrUpdateData('cache', 'playlist10Songs$playlistid', playlistSongs);
  // }

  return playlistSongs;
}

String printDuration(Duration? duration) {
  if (duration != null) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    return "${duration.inHours != 0 ? '${twoDigits(duration.inHours)}:' : ''} $twoDigitMinutes:$twoDigitSeconds";
  } else {
    return "";
  }
}

Future<List<dynamic>> getUserPlaylists() async {
  final playlistsByUser = [];
  for (final playlistID in userPlaylists) {
    final plist = await yt.playlists.get(playlistID);
    playlistsByUser.add({
      'ytid': plist.id,
      'title': plist.title,
      'subtitle': 'Just Updated',
      'header_desc': plist.description.length < 120
          ? plist.description
          : plist.description.substring(0, 120),
      'type': 'playlist',
      'image': '',
      'list': []
    });
  }
  return playlistsByUser;
}

void addUserPlaylist(String playlistId) {
  userPlaylists.add(playlistId);
  addOrUpdateData('user', 'playlists', userPlaylists);
}

void removeUserPlaylist(String playlistId) {
  userPlaylists.remove(playlistId);
  addOrUpdateData('user', 'playlists', userPlaylists);
}

Future<void> addUserLikedSong(dynamic songId) async {
  userLikedSongsList
      .add(await getSongDetails(userLikedSongsList.length, songId));
  addOrUpdateData('user', 'likedSongs', userLikedSongsList);
}

void removeUserLikedSong(dynamic songId) {
  userLikedSongsList.removeWhere((song) => song['ytid'] == songId);
  addOrUpdateData('user', 'likedSongs', userLikedSongsList);
}

bool isSongAlreadyLiked(dynamic songId) {
  return userLikedSongsList.where((song) => song['ytid'] == songId).isNotEmpty;
}

Future<List> getPlaylists([int? playlistsNum]) async {
  if (playlists.isEmpty) {
    final localplaylists =
        json.decode(await rootBundle.loadString('assets/db/playlists.db.json'))
            as List;
    playlists = localplaylists;
  }

  if (playlistsNum != null) {
    if (suggestedPlaylists.isEmpty) {
      suggestedPlaylists =
          (playlists.toList()..shuffle()).take(playlistsNum).toList();
    }
    return suggestedPlaylists;
  } else {
    return playlists;
  }
}

Future<List> searchPlaylist(String query) async {
  if (playlists.isEmpty) {
    final localplaylists =
        json.decode(await rootBundle.loadString('assets/db/playlists.db.json'))
            as List;
    playlists = localplaylists;
  }

  return playlists
      .where(
        (playlist) =>
            playlist['title'].toLowerCase().contains(query.toLowerCase()),
      )
      .toList();
}

Future<Map> getRandomSong() async {
  const playlistId = 'PLFgquLnL59alwzM3kQ6cWhwwZXa4TCjN4';
  final List playlistSongs = await getSongsFromPlaylist(playlistId);

  return playlistSongs[random.nextInt(playlistSongs.length)];
}

Future getSongsFromPlaylist(dynamic playlistid) async {
  final List playlistSongs = [];
  //   await getData('cache', 'playlistSongs$playlistid') ?? [];
  if (playlistSongs.isEmpty) {
    var index = 0;
    await for (final song in yt.playlists.getVideos(playlistid)) {
      playlistSongs.add(
        returnSongLayout(
          index,
          song.id.toString(),
          formatSongTitle(
            song.title.split('-')[song.title.split('-').length - 1],
          ),
          song.thumbnails.standardResUrl,
          song.thumbnails.lowResUrl,
          song.thumbnails.maxResUrl,
          song.title.split('-')[0],
          printDuration(song.duration),
        ),
      );
      index += 1;
    }
    // addOrUpdateData('cache', 'playlistSongs$playlistid', playlistSongs);
  }

  return playlistSongs;
}

Future<void> setActivePlaylist(List plist) async {
  if (plist is List<SongModel>) {
    activePlaylist = [];
    id = 0;
    final activeTempPlaylist = <MediaItem>[
      for (final song in plist) songModelToMediaItem(song, song.data)
    ];

    await MyAudioHandler().addQueueItems(activeTempPlaylist);

    play();
  } else {
    activePlaylist = plist;
    id = 0;
    await playSong(activePlaylist[id]);
  }
}

Future getPlaylistInfoForWidget(dynamic id) async {
  var searchPlaylist = playlists.where((list) => list['ytid'] == id).toList();

  if (searchPlaylist.isEmpty) {
    final usPlaylists = await getUserPlaylists();
    searchPlaylist = usPlaylists.where((list) => list['ytid'] == id).toList();
  }

  final playlist = searchPlaylist[0];

  if (playlist['list'].length == 0) {
    searchPlaylist[searchPlaylist.indexOf(playlist)]['list'] =
        await getSongsFromPlaylist(playlist['ytid']);
    playlists[playlists.indexOf(playlist)]['list'] =
        searchPlaylist[searchPlaylist.indexOf(playlist)]['list'];
  }

  return playlist;
}

Future<dynamic> getSong(dynamic songId, bool geturl) async {
  final manifest = await yt.videos.streamsClient.getManifest(songId);
  if (geturl) {
    return manifest.audioOnly.withHighestBitrate().url.toString();
  } else {
    return manifest.audioOnly.withHighestBitrate();
  }
}

Future getSongDetails(dynamic songIndex, dynamic songId) async {
  final song = await yt.videos.get(songId);
  return returnSongLayout(
    songIndex,
    song.id.toString(),
    formatSongTitle(song.title.split('-')[song.title.split('-').length - 1]),
    song.thumbnails.standardResUrl,
    song.thumbnails.lowResUrl,
    song.thumbnails.maxResUrl,
    song.title.split('-')[0],
    printDuration(song.duration),
  );
}

Future<List<Map<String, int>>> getSkipSegments(String id) async {
  try {
    final res = await http.get(
      Uri(
        scheme: 'https',
        host: 'sponsor.ajay.app',
        path: '/api/skipSegments',
        queryParameters: {
          'videoID': id,
          'category': [
            'sponsor',
            'selfpromo',
            'interaction',
            'intro',
            'outro',
            'music_offtopic'
          ],
          'actionType': 'skip'
        },
      ),
    );
    if (res.body != 'Not Found') {
      final data = jsonDecode(res.body);
      final segments = data.map((obj) {
        return Map.castFrom<String, dynamic, String, int>({
          'start': obj['segment'].first.toInt(),
          'end': obj['segment'].last.toInt(),
        });
      }).toList();
      return List.castFrom<dynamic, Map<String, int>>(segments);
    } else {
      return [];
    }
  } catch (e, stack) {
    debugPrint('$e $stack');
    return [];
  }
}
