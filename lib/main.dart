import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const EyeBreakApp());
}

class EyeBreakApp extends StatelessWidget {
  const EyeBreakApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EyeBreak',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  Timer? _timer;
  int _workSeconds = 20 * 60;
  int _remaining = 20 * 60;
  bool _isRunning = false;
  bool _isBreak = false;
  int _breakSeconds = 20;
  int _breakRemaining = 20;
  int _completedSessions = 0;
  int _totalFocusMinutes = 0;
  List<Map<String, dynamic>> _history = [];
  int _selectedWorkMinutes = 20;
  List<int> _workOptions = [1, 20, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _completedSessions = prefs.getInt('sessions')?? 0;
      _totalFocusMinutes = prefs.getInt('focusMinutes')?? 0;
      _selectedWorkMinutes = prefs.getInt('workMinutes')?? 20;
      _workSeconds = _selectedWorkMinutes * 60;
      _remaining = _workSeconds;
      final hist = prefs.getString('history');
      if (hist!= null) {
        _history = List<Map<String, dynamic>>.from(jsonDecode(hist));
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sessions', _completedSessions);
    await prefs.setInt('focusMinutes', _totalFocusMinutes);
    await prefs.setInt('workMinutes', _selectedWorkMinutes);
    await prefs.setString('history', jsonEncode(_history));
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (!_isBreak) {
          if (_remaining > 0) {
            _remaining--;
          } else {
            _isBreak = true;
            _breakRemaining = _breakSeconds;
            _showBreakDialog();
          }
        } else {
          if (_breakRemaining > 0) {
            _breakRemaining--;
          } else {
            _completeSession();
          }
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isBreak = false;
      _remaining = _workSeconds;
      _breakRemaining = _breakSeconds;
    });
  }

  void _completeSession() {
    _timer?.cancel();
    final now = DateTime.now();
    setState(() {
      _isRunning = false;
      _isBreak = false;
      _remaining = _workSeconds;
      _completedSessions++;
      _totalFocusMinutes += _selectedWorkMinutes;
      _history.add({
        'date': now.toIso8601String(),
        'duration': _selectedWorkMinutes,
        'type': 'focus',
      });
      if (_history.length > 50) _history.removeAt(0);
    });
    _saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Great! Sesi selesai, mata kamu aman! 👁️'), backgroundColor: Colors.green),
    );
  }

  void _showBreakDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('WAKTUNYA BREAK! 👀'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 16),
            Text('Lihat objek sejauh 20 kaki (6 meter) selama $_breakSeconds detik', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Text('$_breakRemaining', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 10),
            const Text('Jangan lihat HP!', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
    Future.delayed(Duration(seconds: _breakSeconds), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        _buildHome(),
        _buildStats(),
        _buildSettings(),
      ][_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: Colors.deepPurple,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Timer'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistik'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
        ],
      ),
    );
  }

  Widget _buildHome() {
    double progress = _isBreak? (_breakRemaining / _breakSeconds) : (_remaining / _workSeconds);
    int displaySeconds = _isBreak? _breakRemaining : _remaining;
    String statusText = _isBreak? 'BREAK TIME' : (_isRunning? 'FOCUS TIME' : 'READY');
    Color statusColor = _isBreak? Colors.green : Colors.deepPurple;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text('EYEBREAK', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 3, color: Colors.deepPurple)),
            Text('20-20-20 Rule', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 40),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(statusColor),
                  ),
                ),
                Column(
                  children: [
                    Text(statusText, style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 2)),
                    const SizedBox(height: 8),
                    Text('${(displaySeconds ~/ 60).toString().padLeft(2, '0')}:${(displaySeconds % 60).toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold)),
                    Text(_isBreak? 'Lihat jauh!' : 'Jangan lihat dekat terus', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
                        const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRunning)
                  ElevatedButton.icon(
                    onPressed: _startTimer,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('MULAI'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  ),
                if (_isRunning)
                  ElevatedButton.icon(
                    onPressed: _pauseTimer,
                    icon: const Icon(Icons.pause),
                    label: const Text('PAUSE'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh),
                  label: const Text('RESET'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                ),
              ],
            ),
            const Spacer(),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(children: [const Icon(Icons.check_circle, color: Colors.green), Text('$_completedSessions', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)), const Text('Sesi')]),
                    Column(children: [const Icon(Icons.timer_outlined, color: Colors.blue), Text('$_totalFocusMinutes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)), const Text('Menit')]),
                    Column(children: [const Icon(Icons.favorite, color: Colors.red), const Text('Sehat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)), const Text('Mata')]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    Map<String, int> dailyCount = {};
    for (var h in _history) {
      final date = DateFormat('dd/MM').format(DateTime.parse(h['date']));
      dailyCount[date] = (dailyCount[date]?? 0) + 1;
    }
    final spots = dailyCount.entries.toList().asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value.toDouble())).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            const Text('Statistik Mata Kamu', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Card(color: Colors.deepPurple, child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Total Sesi', style: TextStyle(color: Colors.white70)), Text('$_completedSessions', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))])))),
                const SizedBox(width: 12),
                Expanded(child: Card(color: Colors.green, child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Total Fokus', style: TextStyle(color: Colors.white70)), Text('${_totalFocusMinutes}m', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))])))),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Grafik 7 Hari Terakhir', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: dailyCount.isEmpty? const Center(child: Text('Belum ada data')) : LineChart(LineChartData(lineBarsData: [LineChartBarData(spots: spots.isEmpty? [const FlSpot(0, 0)] : spots, isCurved: true, color: Colors.deepPurple, barWidth: 4, dotData: const FlDotData(show: true))], titlesData: const FlTitlesData(show: true), gridData: const FlGridData(show: true), borderData: FlBorderData(show: true))),
            ),
            const SizedBox(height: 20),
            const Text('Riwayat', style: TextStyle(fontWeight: FontWeight.bold)),
           ..._history.reversed.take(20).map((h) => Card(child: ListTile(leading: const Icon(Icons.visibility, color: Colors.deepPurple), title: Text('${h['duration']} menit fokus'), subtitle: Text(DateFormat('dd MMM HH:mm').format(DateTime.parse(h['date']))), trailing: const Icon(Icons.check, color: Colors.green)))),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text('Pengaturan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('Durasi Fokus (menit)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: _workOptions.map((m) => ChoiceChip(label: Text('$m menit'), selected: _selectedWorkMinutes == m, onSelected: (v) { if (v) { setState(() { _selectedWorkMinutes = m; _workSeconds = m * 60; _remaining = _workSeconds; }); _saveData(); _resetTimer(); }})).toList(),
            ),
            const SizedBox(height: 30),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                                          const Row(children: [Icon(Icons.info, color: Colors.deepPurple), SizedBox(width: 8), Text('Apa itu 20-20-20?', style: TextStyle(fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 10),
                    const Text('Setiap 20 menit melihat layar, istirahatkan mata selama 20 detik dengan melihat objek sejauh 20 kaki (6 meter).'),
                    const SizedBox(height: 10),
                    const Text('Mencegah lelah dan kering'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
            _tipCard(Icons.water_drop, 'Minum Air Putih', 'Dehidrasi bikin mata kering. Minum 8 gelas sehari.'),
          _tipCard(Icons.light_mode, 'Pencahayaan Cukup', 'Jangan main HP di gelap. Lampu harus terang.'),
          _tipCard(Icons.distance, 'Jarak Ideal', 'Jarak HP 40-60cm dari mata.'),
          _tipCard(Icons.blur_on, 'Kedipkan Mata', 'Sengaja kedip tiap 5 detik.'),
          _tipCard(Icons.nightlight, 'Mode Malam', 'Aktifkan blue light filter jam 7 malam.'),
          _tipCard(Icons.sports_gymnastics, 'Senam Mata', 'Putar bola mata 10x searah jarum jam.'),
          _tipCard(Icons.timer_off, 'Aturan 20-20-20', '20 menit layar, 20 detik lihat jauh.'),
          _tipCard(Icons.visibility_off, 'Istirahat Total', 'Setiap 2 jam, tutup mata 5 menit.'),
          _tipCard(Icons.phone_android, 'Atur Kecerahan', 'Jangan 100%, 60-70% cukup.'),
          _tipCard(Icons.healing, 'Kompres Hangat', 'Kalau lelah, kompres hangat 1 menit.'),
        ],
      ),
    );
  }

  Widget _tipCard(IconData icon, String title, String desc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _exerciseItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }
}
