import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(EyeBreakApp());

class EyeBreakApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EyeBreak',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Color(0xFF0F172A)),
      home: EyeBreakHome(),
    );
  }
}

class EyeBreakHome extends StatefulWidget {
  @override
  _EyeBreakHomeState createState() => _EyeBreakHomeState();
}

class _EyeBreakHomeState extends State<EyeBreakHome> {
  int seconds = 19 * 60;
  Timer? timer;
  bool running = false;

  void start() {
    setState(() => running = true);
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (seconds > 0) {
        setState(() => seconds--);
      } else {
        t.cancel();
        setState(() => running = false);
        showDialog(context: context, builder: (_) => AlertDialog(
          title: Text("Time to rest! 👀"),
          content: Text("Look 20 feet away for 20 seconds"),
          actions: [TextButton(onPressed: (){Navigator.pop(context); setState((){seconds=19*60;});}, child: Text("OK"))],
        ));
      }
    });
  }

  void stop() {
    timer?.cancel();
    setState(() { running = false; seconds = 19*60; });
  }

  @override
  Widget build(BuildContext context) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.remove_red_eye, size: 80, color: Colors.cyanAccent),
            SizedBox(height: 20),
            Text("EyeBreak", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}", style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
            SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black, padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
              onPressed: running? stop : start,
              child: Text(running? "RESET" : "START 19-MIN TIMER", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 20),
            Text("Use while scrolling TikTok, IG & YouTube", style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
