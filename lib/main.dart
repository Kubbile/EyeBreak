import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'plus_manager.dart';

void main() => runApp(MaterialApp(home: EyeBreakPlus(), debugShowCheckedModeBanner: false));

class EyeBreakPlus extends StatefulWidget {
  @override
  State<EyeBreakPlus> createState() => _EyeBreakPlusState();
}

class _EyeBreakPlusState extends State<EyeBreakPlus> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final AudioRecorder _recorder = AudioRecorder();
  bool isListening = false, isRecordingCustom = false, isCustomMode = false;
  String triggerWord = "next";
  TextEditingController wordController = TextEditingController(text: "next");
  TextEditingController codeController = TextEditingController();
  double customDb = -30, currentDb = -100;
  String lastStatus = "Siap";
  StreamSubscription<Amplitude>? ampSub;
  bool hasCustomSound = false, plusActive = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  _init() async {
    await Permission.microphone.request();
    await _speech.initialize();
    bool p = await PlusManager.isPlus();
    setState(() => plusActive = p);
  }

  Future<void> recordCustom() async {
    if (!plusActive) { showPlusDialog(); return; }
    setState(() { isRecordingCustom = true; lastStatus = "Buat suara apapun... 2 detik"; });
    if (await _recorder.hasPermission()) {
      await _recorder.start(RecordConfig(encoder: AudioEncoder.wav), path: '');
      double maxDb = -100;
      ampSub = _recorder.onAmplitudeChanged(Duration(milliseconds: 50)).listen((amp) {
        if (amp.current > maxDb) maxDb = amp.current;
        setState(() => currentDb = amp.current);
      });
      await Future.delayed(Duration(seconds: 2));
      await _recorder.stop(); await ampSub?.cancel();
      setState(() { customDb = maxDb; isRecordingCustom = false; hasCustomSound = true; lastStatus = "Suara custom tersimpan! ${customDb.toStringAsFixed(1)} dB"; });
    }
  }

  void start() async {
    if (isCustomMode && !plusActive) { showPlusDialog(); return; }
    if (isCustomMode && !hasCustomSound) { setState(() => lastStatus = "Rekam suara bebas dulu!"); return; }
    setState(() { isListening = true; });
    if (isCustomMode) {
      await _recorder.start(RecordConfig(encoder: AudioEncoder.wav), path: '');
      ampSub = _recorder.onAmplitudeChanged(Duration(milliseconds: 100)).listen((amp) {
        setState(() => currentDb = amp.current);
        if (amp.current > (customDb - 8) && amp.current > -25) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ SUARA CUSTOM -> SCROLL"), backgroundColor: Colors.green));
        }
      });
    } else {
      _speech.listen(onResult: (res) {
        setState(() => lastStatus = res.recognizedWords);
        if (res.recognizedWords.toLowerCase().contains(triggerWord.toLowerCase())) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ $triggerWord -> SCROLL"), backgroundColor: Colors.green));
        }
      }, listenFor: Duration(minutes: 10));
    }
  }

  void stop() async {
    await _speech.stop();
    if (await _recorder.isRecording()) await _recorder.stop();
    await ampSub?.cancel();
    setState(() { isListening = false; });
  }

  void showPlusDialog() {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: Text("EyeBreak Plus - Rp 5.000/bulan"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text("Fitur Rekam Suara Bebas terkunci. Bayar 5k untuk buka siulan, ketukan, jentikan, tepukan, suara apapun."),
        SizedBox(height: 12),
        TextField(controller: codeController, decoration: InputDecoration(labelText: "Masukkan kode aktivasi", hintText: "PLUS-XXXX-XXXX", border: OutlineInputBorder())),
        SizedBox(height: 8),
        Text("Kode umum: EBPLUS5K\nKode admin lu: PLUS-MAKASSAR", style: TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text("Nanti")),
        ElevatedButton(onPressed: () async {
          bool ok = await PlusManager.activate(codeController.text);
          Navigator.pop(c);
          if (ok) { setState(() => plusActive = true); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PLUS AKTIF 30 HARI!"), backgroundColor: Colors.green)); }
          else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Kode salah"), backgroundColor: Colors.red)); }
        }, child: Text("AKTIFKAN")),
      ],
    ));
  }

  void showAdminGenerate() {
    String newCode = PlusManager.generateCode();
    showDialog(context: context, builder: (c) => AlertDialog(
      title: Text("ADMIN - Generate Kode"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text("Kode baru untuk pembeli:"),
        SizedBox(height: 10),
        SelectableText(newCode, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
        SizedBox(height: 10),
        Text("Copy dan kirim ke WA pembeli setelah dia bayar 5k ke DANA lu."),
      ]),
      actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: Text("OK"))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, actions: [
        if (plusActive) Padding(padding: EdgeInsets.all(12), child: Chip(label: Text("PLUS AKTIF", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.amber)),
        IconButton(onPressed: showAdminGenerate, icon: Icon(Icons.admin_panel_settings, color: Colors.white24)),
      ]),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(children: [
          Icon(isCustomMode ? Icons.graphic_eq : Icons.mic, size: 70, color: isListening ? Colors.greenAccent : Colors.white24),
          SizedBox(height: 8),
          Text(lastStatus, style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
          SizedBox(height: 20),
          Container(decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)), child: Row(children: [
            Expanded(child: InkWell(onTap: ()=>setState(()=>isCustomMode=false), child: Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: !isCustomMode ? Colors.cyan : Colors.transparent, borderRadius: BorderRadius.circular(12)), child: Center(child: Text("KATA")))))),
            Expanded(child: InkWell(onTap: ()=>setState(()=>isCustomMode=true), child: Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: isCustomMode ? Colors.cyan : Colors.transparent, borderRadius: BorderRadius.circular(12)), child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("SUARA BEBAS"), if (!plusActive) Icon(Icons.lock, size: 14)]))))),
          ])),
          SizedBox(height: 20),
          if (!isCustomMode) TextField(controller: wordController, style: TextStyle(color: Colors.white), onChanged: (v)=>triggerWord=v, decoration: InputDecoration(labelText: "Kata custom bebas", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          if (isCustomMode) ...[
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: recordCustom, icon: Icon(Icons.record_voice_over), label: Text(hasCustomSound ? "REKAM ULANG" : "REKAM SUARA APAPUN"), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: EdgeInsets.all(16)))),
            SizedBox(height: 10),
            Text("BEBAS: siul, tok meja, jentik, tepuk, 'ck', 'up' - apapun!", textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
            if (hasCustomSound) Text("Level: ${customDb.toStringAsFixed(1)} dB | Sekarang: ${currentDb.toStringAsFixed(1)} dB", style: TextStyle(color: Colors.white70)),
          ],
          Spacer(),
          if (!plusActive) SizedBox(width: double.infinity, child: OutlinedButton(onPressed: showPlusDialog, child: Text("BUKA PLUS - 5K/BULAN 🔓"))),
          SizedBox(height: 8),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: isListening ? stop : start, style: ElevatedButton.styleFrom(backgroundColor: isListening ? Colors.red : Colors.cyan, padding: EdgeInsets.symmetric(vertical: 18)), child: Text(isListening ? "STOP" : "MULAI", style: TextStyle(fontWeight: FontWeight.bold)))),
        ]),
      ),
    );
  }
}
