import 'package:flutter/material.dart';
import 'package:songeet/style/app_colors.dart';

class SettingBar extends StatelessWidget {
  const SettingBar(this.tileName, this.tileIcon, this.onTap, {Key? key})
      : super(key: key);

  final Function() onTap;
  final String tileName;
  final IconData tileIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 6),
      child: Card(
        color: bgLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2.3,
        child: ListTile(
          leading: Icon(tileIcon, color: accent),
          title: Text(
            tileName,
            style: TextStyle(color: accent),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
