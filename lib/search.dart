import 'package:flutter/material.dart';
import 'dart:math';

import 'actionPointsHelper.dart';
import 'main.dart';
import 'monster.dart';

Future<bool> search(int cost) async {
  // 捜索ボタンが押された時の処理
  int currentPoints = await ActionPointsHelper.getActionPoints();
  if (currentPoints < cost) {
    // 行動力が足りない場合は処理を中断
    return false;
  }

  for (int i = 0; i < combineMonsters.length; i++) {
    if (searchedMonsters.contains(combineMonsters[i])) {
      combineMonsters[i] = null;
    }
  }

  // ここで捜索結果を表示するウィジェットを構築
  searchedMonsters.clear();
  SearchStatus searchStatus = SearchStatus();

  final random = Random();
  int randRetry;
  int count = 0;
  int successRetry = 0;

  do {
    Monster searchedMonster = Monster.search(searchStatus);

    // if (ownMonsters.length < 5) {
    //   ownMonsters.add(searchedMonster);
    //   await saveData(ownMonsters);
    //
    //   infoMessage = Text('モンスターが仲間に加わった！');
    // } else {
      searchedMonsters.add(searchedMonster);
      infoMessage = Text('モンスターを発見した！');
    // }

    randRetry = random.nextInt(searchStatus.will + 1);
    successRetry += 50;
    count++;
  } while (randRetry > successRetry && count < 5);

  await ActionPointsHelper.setActionPoints(currentPoints - cost);

  if (currentPoints <= 0) {
    return false;
  }

  return true;
}

class SearchStatus {
  int will = -1;
  int charm = -1;
  int intel = -1;

  SearchStatus() {
    will = ownMonsters[0].magic;
    charm = ownMonsters[0].will;
    intel = ownMonsters[0].intel;

    for (Monster monster in ownMonsters) {
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