import 'package:shared_preferences/shared_preferences.dart';

class TotalScoreHelper {
  static const String _key = "total_score";

  static Future<void> setScore(int points) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_key, points);
  }

  static Future<int> getScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0; // デフォルト値は0
  }

  static Future<void> addScore(int addPoints) async {
    final prefs = await SharedPreferences.getInstance();
    int currentScore = prefs.getInt(_key) ?? 0; // 現在のスコアを取得
    currentScore += addPoints; // スコアに加算
    await setScore(currentScore); // 新しいスコアを保存
  }
}