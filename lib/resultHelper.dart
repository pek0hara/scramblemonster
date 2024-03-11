import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ResultHelper {
  static const String _resultKey = "results";
  static const String _highScoreKey = "high_scores";

  static Future<void> saveResult(Map<String, dynamic> result) async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? results = prefs.getStringList(_resultKey) ?? [];
    if (results.length >= 100) {
      results.removeAt(99); // 最も古い結果を削除
    }
    results.insert(0, jsonEncode(result));
    prefs.setStringList(_resultKey, results);
  }

  static Future<void> saveHighScore(Map<String, dynamic> result) async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? highScores = prefs.getStringList(_highScoreKey) ?? [];

    // 新しいスコアを追加
    highScores.add(jsonEncode(result));

    // JSONをデコードしてmaxMagicPowerでソート
    List<Map<String, dynamic>> decodedHighScores = highScores.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    decodedHighScores.sort((a, b) => b['maxMagicPower'].compareTo(a['maxMagicPower']));

    // 上位5つのスコアだけを保存
    List<String> topHighScores = decodedHighScores.take(5).map((e) => jsonEncode(e)).toList();

    prefs.setStringList(_highScoreKey, topHighScores);
  }

  static Future<List> getResults() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? results = prefs.getStringList(_resultKey) ?? [];
    return results.map((e) => jsonDecode(e)).toList();
  }

  static Future<List> getHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? highScores = prefs.getStringList(_highScoreKey) ?? [];
    return highScores.map((e) => jsonDecode(e)).toList();
  }
}
