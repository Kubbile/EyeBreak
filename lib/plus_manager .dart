import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class PlusManager {
  static Future<bool> isPlus() async {
    final prefs = await SharedPreferences.getInstance();
    bool isPlus = prefs.getBool('isPlus') ?? false;
    int expiry = prefs.getInt('plusExpiry') ?? 0;
    if (!isPlus) return false;
    if (DateTime.now().millisecondsSinceEpoch > expiry) {
      await prefs.setBool('isPlus', false);
      return false;
    }
    return true;
  }

  static Future<bool> activate(String code) async {
    String c = code.toUpperCase().trim();
    // Kode valid: EBPLUS5K, PLUS-MAKASSAR, atau apapun yg depannya PLUS-
    if (c == "EBPLUS5K" || c == "PLUS-MAKASSAR" || c.startsWith("PLUS-")) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isPlus', true);
      int expiry = DateTime.now().add(Duration(days: 30)).millisecondsSinceEpoch;
      await prefs.setInt('plusExpiry', expiry);
      return true;
    }
    return false;
  }

  static String generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    Random rnd = Random();
    String gen(int n) => String.fromCharCodes(Iterable.generate(n, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    return "PLUS-${gen(4)}-${gen(4)}";
  }

  static Future<int> getDaysLeft() async {
    final prefs = await SharedPreferences.getInstance();
    int expiry = prefs.getInt('plusExpiry') ?? 0;
    int diff = expiry - DateTime.now().millisecondsSinceEpoch;
    return (diff / (1000 * 60 * 60 * 24)).ceil();
  }
}
