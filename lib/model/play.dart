import 'package:hive/hive.dart';

part 'play.g.dart';

@HiveType(typeId: 0)
class Tech extends HiveObject {
  @HiveField(0)
  String label;

  @HiveField(1)
  String playlistID;

  Tech(this.label, this.playlistID);
}
