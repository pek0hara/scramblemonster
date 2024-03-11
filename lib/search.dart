import 'package:flutter/material.dart';
import 'dart:math';

import 'actionPointsHelper.dart';
import 'main.dart';
import 'monster.dart';

int searchCost = 1;

Future<bool> search(int cost) async {
  // 捜索ボタンが押された時の処理
  int currentPoints = await ActionPointsHelper.getActionPoints();
  if (currentPoints < 1) {
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
  HighestStatus searchStatus = HighestStatus();

  final random = Random();
  int randRetry;
  int count = 0;
  int successRetry = 0;

  do {
    Monster searchedMonster = createNewMonster();

      searchedMonsters.add(searchedMonster);
      infoMessage = Text('モンスターを発見した！');

    randRetry = random.nextInt(searchStatus.will + 1);
    successRetry += 60;
    count++;
  } while (randRetry > successRetry && count < 5);

  await ActionPointsHelper.setActionPoints(currentPoints - cost);

  if (currentPoints <= 0) {
    currentPoints = 0;
    return false;
  }

  return true;
}

Monster createNewMonster() {
  HighestStatus highestStatus = HighestStatus();

  final random = Random();
  int max = 40 + highestStatus.lv ~/ 3;
  // if (highestStatus.lv > 60) {
  //   max = 70 + highestStatus.lv ~/ 4;
  // }
  int newW = random.nextInt(max) + 1;
  int newC = random.nextInt(max - newW + 1) + 1;
  int newI = random.nextInt(max - newW - newC + 2) + 1;

// highestValues.will と 400を比較して小さい方を採用
  int searchWill = highestStatus.will > 400 ? 400 : highestStatus.will;
  int newNo = random.nextInt(searchWill ~/ 4 + 1);

// Charm補正
  newC += random.nextInt(highestStatus.charm ~/ 6 + 1);
  int newM = (newW + newC + newI) ~/ 6;

// Intel補正
  max = highestStatus.intel ~/ 10 + 1;
  newI += random.nextInt(max) + 1;
  newC += random.nextInt(max) + 1;
  newW += random.nextInt(max) + 1;

  return Monster(no: newNo, magic: newW, will: newC, intel: newI, lv: newM);
}