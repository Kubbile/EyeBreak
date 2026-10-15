import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() => runApp(EyeBreakApp());

class EyeBreakApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(home: VoiceScrollPage(), debugShowCheckedModeBanner: false);
}

class VoiceScrollPage extends StatefulWidget {
  @override
  _VoiceScrollPageState createState() => _VoiceScrollPageState();
}

class _VoiceScrollPageState extends State<VoiceScrollPage> {
  stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;
  String triggerWord = "next";
  List<String> triggerOptions = ["next", "scroll", "up", "ok", "ganti"];
  String lastHeard = "";

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  void initSpeech() async {
    await speech.initialize();
  }

  void startListening() async {
    setState(() => isListening = true);
    speech.listen(
      onResult: (result) {
        setState(() => lastHeard = result.recognizedWords.toLowerCase());
        if (lastHeard.contains(triggerWord)) {
          doAutoScroll();
        }
      },
      listenFor: Duration(seconds: 30),
      listenMode: stt.ListenMode.dictation,
    );
  }

  void doAutoScroll() {
    // Ini akan trigger accessibility service buat swipe
    print("VOICE TRIGGER: $triggerWord -> SCROLL 1 VIDEO");
    // Untuk demo, kita kasih feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("🔊 Terdengar '$triggerWord' -> Auto scroll 1 video!"), backgroundColor: Colors.green)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic, size: 80, color: isListening ? Colors.red : Colors.grey),
            SizedBox(height: 20),
            Text("VOICE SCROLL PLUS", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Taruh HP jauh, bilang kata kunci buat scroll", style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
            SizedBox(height: 30),
            Text("Pilih kata pemicu:", style: TextStyle(color: Colors.white)),
            DropdownButton<String>(
              value: triggerWord,
              dropdownColor: Colors.black87,
              style: TextStyle(color: Colors.white),
              items: triggerOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => triggerWord = v!),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: isListening ? () { speech.stop(); setState(() => isListening = false); } : startListening,
              style: ElevatedButton.styleFrom(backgroundColor: isListening ? Colors.red : Colors.cyan, padding: EdgeInsets.symmetric(horizontal: 40, vertical: 18)),
              child: Text(isListening ? "STOP LISTENING" : "MULAI DENGERIN SUARA"),
            ),
            SizedBox(height: 20),
            Text("Terakhir didengar: $lastHeard", style: TextStyle(color: Colors.white38)),
            SizedBox(height: 40),
            Container(padding: EdgeInsets.all(12), color: Colors.white10, child: Text("Mode Plus: Setelah bilang '$triggerWord', aplikasi akan auto swipe 1 video. Lu bisa atur jarak HP sesuka hati, gak perlu pegang HP. Cocok buat jaga jarak mata!", style: TextStyle(color: Colors.white70))),
          ],
        ),
      ),
    );
  }
}
