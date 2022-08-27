import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:songeet/customWidgets/setting_bar.dart';
import 'package:songeet/main.dart';
import 'package:songeet/services/audio_manager.dart';
import 'package:songeet/services/data_manager.dart';
import 'package:songeet/style/appColors.dart';

import 'package:songeet/ui/search.dart';
import 'package:songeet/ui/userlikedsong.dart';
import 'package:songeet/ui/userPlaylistsPage.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Settings",
          style: TextStyle(
            color: accent,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(child: SettingsCards()),
    );
  }
}

class SettingsCards extends StatelessWidget {
  const SettingsCards({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SettingBar(
          "Accent color",
          MdiIcons.shapeOutline,
          () => {
            showModalBottomSheet(
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
                    width: MediaQuery.of(context).copyWith().size.width * 0.90,
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
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
              },
            ),
          },
        ),
        SettingBar(
          "Language",
          MdiIcons.translate,
          () => {
            showModalBottomSheet(
              isDismissible: true,
              backgroundColor: Colors.transparent,
              context: context,
              builder: (BuildContext context) {
                final codes = <String, String>{
                  'English': 'en',
                  'French': 'fr',
                  'Georgian': 'ka',
                  'Chinese': 'zh',
                  'Dutch': 'nl',
                  'German': 'de',
                  'Indonesian': 'id',
                  'Italian': 'it',
                  'Polish': 'pl',
                  'Portuguese': 'pt',
                  'Spanish': 'es',
                  'Turkish': 'tr',
                  'Ukrainian': 'uk',
                };

                final availableLanguages = <String>[
                  'English',
                  'French',
                  'Georgian',
                  'Chinese',
                  'Dutch',
                  'German',
                  'Indonesian',
                  'Italian',
                  'Polish',
                  'Portuguese',
                  'Spanish',
                  'Turkish',
                  'Ukrainian',
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
                    width: MediaQuery.of(context).copyWith().size.width * 0.90,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: availableLanguages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(10),
                          child: Card(
                            color: bgLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2.3,
                            child: ListTile(
                              title: Text(
                                availableLanguages[index],
                                style: TextStyle(color: accent),
                              ),
                              onTap: () {
                                addOrUpdateData(
                                  'settings',
                                  'language',
                                  availableLanguages[index],
                                );

                                Fluttertoast.showToast(
                                  backgroundColor: accent,
                                  textColor: accent != const Color(0xFFFFFFFF)
                                      ? Colors.white
                                      : Colors.black,
                                  msg: "Language has been changed",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  fontSize: 14,
                                );
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          },
        ),
        SettingBar(
          "Clear cache",
          MdiIcons.broom,
          () => {
            clearCache(),
            Fluttertoast.showToast(
              backgroundColor: accent,
              textColor: accent != const Color(0xFFFFFFFF)
                  ? Colors.white
                  : Colors.black,
              msg: 'Cache cleared!',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              fontSize: 14,
            )
          },
        ),
        SettingBar(
          "Clear Search History",
          MdiIcons.history,
          () => {
            searchHistory = [],
            deleteData('user', 'searchHistory'),
            Fluttertoast.showToast(
              backgroundColor: accent,
              textColor: accent != const Color(0xFFFFFFFF)
                  ? Colors.white
                  : Colors.black,
              msg: "Search history cleared!",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              fontSize: 14,
            ),
          },
        ),
        SettingBar(
          "User playlists",
          MdiIcons.account,
          () => {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UserPlaylistsPage(),
              ),
            ),
          },
        ),
        SettingBar(
          "User liked songs",
          MdiIcons.star,
          () => {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserLikedSongs()),
            ),
          },
        ),
        SettingBar(
          "Audio File Extension",
          MdiIcons.file,
          () => {
            showModalBottomSheet(
              isDismissible: true,
              backgroundColor: Colors.transparent,
              context: context,
              builder: (BuildContext context) {
                final availableFileTypes = ['mp3', 'flac', 'm4a'];
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
                    width: MediaQuery.of(context).copyWith().size.width * 0.90,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: availableFileTypes.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(10),
                          child: Card(
                            color: bgLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2.3,
                            child: ListTile(
                              title: Text(
                                availableFileTypes[index],
                                style: TextStyle(color: accent),
                              ),
                              onTap: () {
                                addOrUpdateData(
                                  'settings',
                                  'audioFileType',
                                  availableFileTypes[index],
                                );
                                prefferedFileExtension.value =
                                    availableFileTypes[index];

                                Fluttertoast.showToast(
                                  backgroundColor: accent,
                                  textColor: accent != const Color(0xFFFFFFFF)
                                      ? Colors.white
                                      : Colors.black,
                                  msg: "Audio File Type has been changed",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  fontSize: 14,
                                );
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          },
        ),
      ],
    );
  }
}
