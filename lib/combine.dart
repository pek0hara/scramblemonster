import 'dart:math';

import 'package:flutter/material.dart';
import 'package:scramblemonster/totalScoreHelper.dart';

import 'actionPointsHelper.dart';
import 'main.dart';
import 'monster.dart';

Future<bool> combine() async {
  int currentPoints = await ActionPointsHelper.getActionPoints();
  if (currentPoints <= 0){
    return false;
  }

  for (var monster in combineMonsters) {
    if (!ownMonsters.contains(monster) && !searchedMonsters.contains(monster)) {
      return true; // monsterが存在しない場合、trueを返す
    }
  }

  // 合体後のモンスターを生成
  if (combineMonsters[0] != null && combineMonsters[1] != null) {
    Monster newMonster =
        newCombinedMonster(combineMonsters[0]!, combineMonsters[1]!);

    int index0 = ownMonsters.indexOf(combineMonsters[0]!);
    int index1 = ownMonsters.indexOf(combineMonsters[1]!);

    if (index0 == -1 && index1 == -1){
      searchedMonsters.remove(combineMonsters[0]!);
      searchedMonsters.remove(combineMonsters[1]!);
      searchedMonsters.add(newMonster);
    } else if (index0 == -1) {
      ownMonsters[index1] = newMonster;
      searchedMonsters.remove(combineMonsters[0]!);
    } else if (index1 == -1) {
      ownMonsters[index0] = newMonster;
      searchedMonsters.remove(combineMonsters[1]!);
    } else {
      ownMonsters[index0] = newMonster;
      ownMonsters.removeAt(index1);
    }

    combineMonsters[0] = null;
    combineMonsters[1] = null;

    infoMessage = Text('新しいモンスターが生まれた！');

    int score = newMonster.lv;
    await TotalScoreHelper.addScore(score);
  }

  await saveData(ownMonsters);

  if (0 < currentPoints && currentPoints < 10) {
    await ActionPointsHelper.setActionPoints(0);
    return false;
  } else {
    await ActionPointsHelper.setActionPoints(currentPoints - 10);
    return true;
  }
}

int calculateGrowth(Monster monster1, Monster monster2) {
  int growthRate = 60;

  int value1 = monster1.magic + monster1.will + monster1.intel;
  int value2 = monster2.magic + monster2.will + monster2.intel;
  int sum = (value1 + value2) ~/ 7;

  if (sum % 7 == 0) {
    if (max(monster1.lv,monster2.lv) < 40) {
      growthRate = 90;
    } else if (max(monster1.lv,monster2.lv) < 100) {
      growthRate = 80;
    }
  } else if (sum % 3 == 0) {
    if (max(monster1.lv,monster2.lv) < 40) {
      growthRate = 80;
    } else {
      growthRate = 70;
    }
  } else {
    if (max(monster1.lv, monster2.lv) < 40) {
      growthRate = 70;
    } else {
      growthRate = 60;
    }
  }

  return growthRate;
}

Monster newCombinedMonster(Monster monster1, Monster monster2) {
  // 各属性の成長率を計算する
  int growM = calculateGrowth(monster1, monster2);
  int growW = calculateGrowth(monster1, monster2);
  int growI = calculateGrowth(monster1, monster2);

  // 合体後のモンスターのステータスを計算するロジック
  int newM = (monster1.magic + monster2.magic) * growM ~/ 100;
  int newW = (monster1.will + monster2.will) * growW ~/ 100;
  int newI = (monster1.intel + monster2.intel) * growI ~/ 100;

  // レベルとモンスター番号を計算するロジック
  int total = newM + newW + newI;
  int newLv;

  if (total <= 360) {
    newLv = total ~/ 6;
  } else {
    newLv = 60 + ((total - 360) ~/ 9);
  }
  int newNo = newLv;

  // モンスター番号が特定の範囲を超えないように制限する
  newNo = newNo > 177 ? 177 : newNo;

  return Monster(no: newNo, magic: newM, will: newW, intel: newI, lv: newLv);
}

