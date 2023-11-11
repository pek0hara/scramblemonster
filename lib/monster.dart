import 'dart:math';

import 'package:scramblemonster/search.dart';
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

  static Monster search(SearchStatus highestValue) {

    final random = Random();
    int max = 60 +  highestValue.intel ~/ 4;
    int newW = random.nextInt(max) + 1;
    int newC = random.nextInt(max - newW + 1) + 1;
    int newI = random.nextInt(max - newW - newC + 2) + 1;

    // highestValues.will と 400を比較して小さい方を採用
    int searchWill = highestValue.will > 400 ? 400 : highestValue.will;
    int newNo = random.nextInt(searchWill ~/ 4 + 1);

    newC += random.nextInt(highestValue.charm ~/ 8 + 1);
    int newM = (newW + newC + newI) ~/ 7;

    return Monster(
        no: newNo, magic: newW, will: newC, intel: newI, lv: newM);
  }

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