import 'dart:math';

import 'package:scramblemonster/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


class Monster {
  final int no;
  final int magic;
  final int will;
  final int intel;
  final int lv;

  Monster({
    this.no = 999,
    this.magic = 1,
    this.will = 1,
    this.intel = 1,
    this.lv = 1,
  });

  // JSON形式のMapに変換
  Map<String, dynamic> toJson() {
    return {
      'no': no,
      'will': magic,
      'charm': will,
      'intel': intel,
      'magic': lv,
    };
  }

  Monster.fromJson(Map<String, dynamic> json)
      : no = json['no'],
        magic = json['will'],
        will = json['charm'],
        intel = json['intel'],
        lv = json['magic'];
}

Future<void> saveData(List<Monster> ownMonsters) async {
  final prefs = await SharedPreferences.getInstance();
  List<Map<String, dynamic>> jsonMonsters = ownMonsters.map((monster) => monster.toJson()).toList();
  prefs.setString('monsters', jsonEncode(jsonMonsters));
}

Future<List<Monster>> loadData() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString('monsters');

  if (jsonString != null) {
    List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((jsonItem) => Monster.fromJson(jsonItem)).toList();
  } else {
    return [];
  }
}

class HighestStatus {
  int lv = -1;
  int will = -1;
  int charm = -1;
  int intel = -1;

  HighestStatus() {
    lv = ownMonsters[0].lv;
    will = ownMonsters[0].magic;
    charm = ownMonsters[0].will;
    intel = ownMonsters[0].intel;

    for (Monster monster in ownMonsters) {
      if (monster.lv > lv) {
        lv = monster.lv;
      }
      if (monster.magic > will) {
        will = monster.magic;
      }
      if (monster.will > charm) {
        charm = monster.will;
      }
      if (monster.intel > intel) {
        intel = monster.intel;
      }
    }
  }
}