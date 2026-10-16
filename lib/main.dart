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
  bool isListening = false;
  bool isRecordingCustom = false;
  bool isCustomMode = false;
  String triggerWord = "next";
  TextEditingController wordController = TextEditingController(text: "next");
  TextEditingController codeController = TextEditingController();
  double customDb = -30;
  double currentDb = -100;
  String lastStatus = "Siap";
  bool hasCustomSound = false;
  bool plusActive = false;

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
    setState(() { isRecordingCustom = true; lastStatus = "Buat suara apapun..."; });
    if (await _recorder.hasPermission()) {
      await _recorder.start(RecordConfig(encoder: AudioEncoder.wav), path: '');
      double maxDb = -100;
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 50)).listen((amp) {
        if (amp.current > maxDb) maxDb = amp.current;
        setState(() => currentDb = amp.current);
      });
      await Future.delayed(Duration(seconds: 2));
      await _recorder.stop();
      setState(() { customDb = maxDb; isRecordingCustom = false; hasCustomSound = true; lastStatus = "Suara custom tersimpan! dB: ${maxDb.toStringAsFixed(1)}"; });
    }
  }

  void start() async {
    if (isCustomMode && !plusActive) { showPlusDialog(); return; }
    setState(() { isListening = true; lastStatus = isCustomMode ? "Dengerin suara custom..." : "Dengerin kata: $triggerWord"; });
    if (isCustomMode) {
      await _recorder.start(RecordConfig(encoder: AudioEncoder.wav), path: '');
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((amp) {
        setState(() => currentDb = amp.current);
        if (amp.current > (customDb - 8) && amp.current > -25) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("SCROLL TERDETEKSI!"), backgroundColor: Colors.green));
        }
      });
    } else {
      _speech.listen(onResult: (res) {
        setState(() => lastStatus = res.recognizedWords);
        if (res.recognizedWords.toLowerCase().contains(triggerWord.toLowerCase())) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("SCROLL: $triggerWord"), backgroundColor: Colors.green));
        }
      }, listenFor: Duration(minutes: 10));
    }
  }

  void stop() async {
    await _speech.stop();
    if (await _recorder.isRecording()) await _recorder.stop();
    setState(() { isListening = false; lastStatus = "Berhenti"; });
  }

  void showPlusDialog() {
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: Color(0xFF2A2A2A),
      title: Text("EyeBreak Plus 5K", style: TextStyle(color: Colors.white)),
      content: TextField(controller: codeController, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: "Kode: EBPLUS5K-XXXX", labelStyle: TextStyle(color: Colors.white54), border: OutlineInputBorder())),
      actions: [
        ElevatedButton(onPressed: () async {
          bool ok = await PlusManager.activate(codeController.text);
          Navigator.pop(c);
          if (ok) setState(() { plusActive = true; });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? "Plus Aktif!" : "Kode Salah")));
        }, child: Text("AKTIFKAN"), style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan)),
      ],
    ));
  }

  void showAdminGenerate() {
    String newCode = PlusManager.generateCode();
    showDialog(context: context, builder: (c) => AlertDialog(
      title: Text("ADMIN GENERATE"),
      content: SelectableText(newCode, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: Text("OK"))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Text("EyeBreak ${plusActive ? 'PLUS' : 'FREE'}", style: TextStyle(color: plusActive ? Colors.cyan : Colors.white)), actions: [IconButton(onPressed: showAdminGenerate, icon: Icon(Icons.admin_panel_settings, color: Colors.white54))]),
      body: Padding(padding: EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)), child: Text(lastStatus, style: TextStyle(color: Colors.white54))),
        SizedBox(height: 20),
        Row(children: [
          Expanded(child: InkWell(onTap: ()=>setState(()=>isCustomMode=false), child: Container(padding: EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: !isCustomMode ? Colors.cyan : Colors.white10, borderRadius: BorderRadius.circular(8)), child: Center(child: Text("KATA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))))),
          SizedBox(width: 10),
          Expanded(child: InkWell(onTap: ()=>setState(()=>isCustomMode=true), child: Container(padding: EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: isCustomMode ? Colors.cyan : Colors.white10, borderRadius: BorderRadius.circular(8)), child: Center(child: Text("SUARA BEBAS ${plusActive ? '' : '🔒'}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))))),
        ]),
        SizedBox(height: 20),
        if (!isCustomMode) TextField(controller: wordController, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: "Kata Trigger", labelStyle: TextStyle(color: Colors.white54), border: OutlineInputBorder()), onChanged: (v)=>triggerWord=v),
        SizedBox(height: 20),
        ElevatedButton(onPressed: isListening ? stop : (isCustomMode ? recordCustom : start), style: ElevatedButton.styleFrom(backgroundColor: isListening ? Colors.red : Colors.cyan, padding: EdgeInsets.symmetric(vertical: 16)), child: Text(isListening ? "STOP" : isCustomMode ? (isRecordingCustom ? "MEREKAM..." : "REKAM SUARA CUSTOM 2 DETIK") : "MULAI LISTENING", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        SizedBox(height: 20),
        Text("dB Saat Ini: ${currentDb.toStringAsFixed(1)} | Custom: ${customDb.toStringAsFixed(1)}", style: TextStyle(color: Colors.white30), textAlign: TextAlign.center),
      ])),
    );
  }
}
