import 'package:shared_preferences/shared_preferences.dart';

class ActionPointsHelper {
  static const String _key = "action_points";

  static Future<void> setActionPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_key, points);
  }

  static Future<int> getActionPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 1000; // デフォルト値は1000
  }
}