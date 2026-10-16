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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("SCROLL TERDE
