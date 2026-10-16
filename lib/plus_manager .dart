import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class PlusManager {
  static String generateCode() {
    var r = Random();
    return 'EBPLUS5K-${r.nextInt(9000) + 1000}';
  }

  static Future<bool> isPlus() async {
    var p = await SharedPreferences.getInstance();
    return p.getBool('isPlus') ?? false;
  }

  static Future<bool> activate(String code) async {
    if (!code.contains('EBPLUS5K')) return false;
    var p = await SharedPreferences.getInstance();
    await p.setBool('isPlus', true);
    return true;
  }
}
