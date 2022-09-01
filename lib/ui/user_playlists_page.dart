// import 'package:flutter/material.dart';
// import 'package:songeet/API/songeet.dart';
// import 'package:songeet/customWidgets/spinner.dart';
// import 'package:songeet/style/app_colors.dart';
// import 'package:songeet/ui/playlists.dart';

// class UserPlaylistsPage extends StatefulWidget {
//   const UserPlaylistsPage({super.key});

//   @override
//   State<UserPlaylistsPage> createState() => _UserPlaylistsPageState();
// }

// class _UserPlaylistsPageState extends State<UserPlaylistsPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         centerTitle: true,
//         title: Text(
//           "User playlists",
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
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           showDialog(
//             context: context,
//             builder: (BuildContext context) {
//               var id = '';
//               return AlertDialog(
//                 backgroundColor: accent,
//                 content: Stack(
//                   children: <Widget>[
//                     TextField(
//                       decoration: const InputDecoration(
//                         hintText: "Youtube playlist ID",
//                       ),
//                       onChanged: (value) {
//                         setState(() {
//                           id = value;
//                         });
//                       },
//                     )
//                   ],
//                 ),
//                 actions: <Widget>[
//                   TextButton(
//                     child: const Text(
//                       "Add",
//                       style: TextStyle(color: Colors.black),
//                     ),
//                     onPressed: () {
//                       addUserPlaylist(id);
//                       setState(() {
//                         Navigator.pop(context);
//                       });
//                     },
//                   ),
//                 ],
//               );
//             },
//           );
//         },
//         backgroundColor: accent,
//         child: Icon(
//           Icons.add,
//           color:
//               accent != const Color(0xFFFFFFFF) ? Colors.white : Colors.black,
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: <Widget>[
//             const Padding(padding: EdgeInsets.only(top: 20)),
//             FutureBuilder(
//               future: getUserPlaylists(),
//               builder: (context, data) {
//                 return (data as dynamic).data != null
//                     ? GridView.builder(
//                         gridDelegate:
//                             const SliverGridDelegateWithMaxCrossAxisExtent(
//                           maxCrossAxisExtent: 200,
//                           crossAxisSpacing: 20,
//                           mainAxisSpacing: 20,
//                         ),
//                         shrinkWrap: true,
//                         physics: const ScrollPhysics(),
//                         itemCount: (data as dynamic).data.length as int,
//                         padding: const EdgeInsets.only(
//                           left: 16,
//                           right: 16,
//                           top: 16,
//                           bottom: 20,
//                         ),
//                         itemBuilder: (BuildContext context, index) {
//                           return Center(
//                             child: GestureDetector(
//                               onLongPress: () {
//                                 removeUserPlaylist(
//                                   (data as dynamic)
//                                       .data[index]['ytid']
//                                       .toString(),
//                                 );
//                                 setState(() {});
//                               },
//                               child: GetPlaylist(
//                                 index: index,
//                                 image: (data as dynamic).data[index]['image'],
//                                 title: (data as dynamic)
//                                     .data[index]['title']
//                                     .toString(),
//                                 id: (data as dynamic).data[index]['ytid'],
//                               ),
//                             ),
//                           );
//                         },
//                       )
//                     : const Spinner();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
