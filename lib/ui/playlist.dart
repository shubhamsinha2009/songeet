// import 'dart:math';

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
// import 'package:songeet/API/songeet.dart';
// import 'package:songeet/customWidgets/song_bar.dart';
// import 'package:songeet/customWidgets/spinner.dart';
// import 'package:songeet/style/app_colors.dart';

// class PlaylistPage extends StatefulWidget {
//   const PlaylistPage({super.key, required this.playlist});
//   final dynamic playlist;

//   @override
//   PlaylistPageState createState() => PlaylistPageState();
// }

// class PlaylistPageState extends State<PlaylistPage> {
//   final _songsList = [];

//   bool _isLoading = true;
//   bool _hasMore = true;
//   final _itemsPerPage = 10;
//   var _currentPage = 0;
//   var _currentLastLoadedId = 0;

//   @override
//   void initState() {
//     super.initState();
//     _isLoading = true;
//     _hasMore = true;
//     _loadMore();
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   void _loadMore() {
//     _isLoading = true;
//     fetch().then((List fetchedList) {
//       if (!mounted) return;
//       if (fetchedList.isEmpty) {
//         setState(() {
//           _isLoading = false;
//           _hasMore = false;
//         });
//       } else {
//         setState(() {
//           _isLoading = false;
//           _songsList.addAll(fetchedList);
//         });
//       }
//     });
//   }

//   Future<List> fetch() async {
//     final list = [];
//     final count = widget.playlist['list'].length as int;
//     final n = min(_itemsPerPage, count - _currentPage * _itemsPerPage);
//     await Future.delayed(const Duration(seconds: 1), () {
//       for (var i = 0; i < n; i++) {
//         list.add(widget.playlist['list'][_currentLastLoadedId]);
//         _currentLastLoadedId++;
//       }
//     });
//     _currentPage++;
//     return list;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         centerTitle: true,
//         title: Text(
//           "Playlist",
//           style: TextStyle(
//             color: accent,
//             fontSize: 25,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         leading: IconButton(
//           icon: Icon(
//             Icons.arrow_back,
//             color: accent,
//           ),
//           onPressed: () => Navigator.pop(context, false),
//         ),
//         // elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         child: widget.playlist != null
//             ? Column(
//                 children: [
//                   Container(
//                     margin: const EdgeInsets.only(left: 10, right: 26),
//                     height: 250,
//                     width: 250,
//                     child: Card(
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       color: Colors.transparent,
//                       child: widget.playlist['image'] != ''
//                           ? DecoratedBox(
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(10),
//                                 image: DecorationImage(
//                                   fit: BoxFit.cover,
//                                   image: CachedNetworkImageProvider(
//                                     widget.playlist['image'].toString(),
//                                   ),
//                                 ),
//                               ),
//                             )
//                           : Container(
//                               width: 200,
//                               height: 200,
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(10),
//                                 gradient: const LinearGradient(
//                                   colors: [
//                                     Color.fromARGB(30, 255, 255, 255),
//                                     Color.fromARGB(30, 233, 233, 233),
//                                   ],
//                                 ),
//                               ),
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: <Widget>[
//                                   Icon(
//                                     MdiIcons.musicNoteOutline,
//                                     size: 30,
//                                     color: accent,
//                                   ),
//                                   Text(
//                                     widget.playlist['title'].toString(),
//                                     style: TextStyle(color: accent),
//                                     textAlign: TextAlign.center,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                     ),
//                   ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       const SizedBox(height: 12),
//                       Text(
//                         widget.playlist['title'].toString(),
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: accent,
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         widget.playlist['header_desc'].toString(),
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: accent,
//                           fontSize: 10,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                       ElevatedButton(
//                         onPressed: () => {
//                           setActivePlaylist(widget.playlist['list'] as List, 0),
//                           Fluttertoast.showToast(
//                             msg: "Initialising queue...",
//                             toastLength: Toast.LENGTH_LONG,
//                             gravity: ToastGravity.BOTTOM,
//                             backgroundColor: accent,
//                             textColor: accent != const Color(0xFFFFFFFF)
//                                 ? Colors.white
//                                 : Colors.black,
//                           ),
//                           Navigator.pop(context, false)
//                         },
//                         style: ElevatedButton.styleFrom(
//                           primary: accent,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         child: Text(
//                           "Play all",
//                           style: TextStyle(
//                             color: accent != const Color(0xFFFFFFFF)
//                                 ? Colors.white
//                                 : Colors.black,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 30),
//                   if (_songsList.isNotEmpty)
//                     ListView.builder(
//                       shrinkWrap: true,
//                       physics: const BouncingScrollPhysics(),
//                       addAutomaticKeepAlives:
//                           false, // may be problem with lazyload if it implemented
//                       addRepaintBoundaries: false,
//                       // Need to display a loading tile if more items are coming
//                       itemCount:
//                           _hasMore ? _songsList.length + 1 : _songsList.length,
//                       itemBuilder: (BuildContext context, int index) {
//                         if (index >= _songsList.length) {
//                           if (!_isLoading) {
//                             _loadMore();
//                           }
//                           return const Spinner();
//                         }
//                         return Padding(
//                           padding: const EdgeInsets.only(top: 5, bottom: 5),
//                           child: SongBar(
//                             _songsList,
//                             index,
//                             true,
//                           ),
//                         );
//                       },
//                     )
//                   else
//                     const Spinner()
//                 ],
//               )
//             : SizedBox(
//                 height: MediaQuery.of(context).size.height - 100,
//                 child: const Spinner(),
//               ),
//       ),
//     );
//   }
// }
