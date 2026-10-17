import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(
    const EyeBreakApp(),
  );
}

class EyeBreakApp extends StatelessWidget {
  const EyeBreakApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EyeBreak',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(
          0xFFF5F3FF,
        ),
      ),
      home: const EyeBreakHome(),
    );
  }
}

class EyeBreakHome extends StatefulWidget {
  const EyeBreakHome({
    super.key,
  });

  @override
  State<EyeBreakHome> createState() => _EyeBreakHomeState();
}

class _EyeBreakHomeState extends State<EyeBreakHome> {
  int currentIndex = 0;
  Timer? workTimer;
  int workSeconds = 20 * 60;
  int totalSeconds = 20 * 60;
  bool isWorking = false;
  bool isBreakTime = false;
  int breakSeconds = 20;
  int streak = 0;
  int totalSessions = 0;
  List<int> weeklyData = [
    2,
    3,
    5,
    4,
    6,
    3,
    5,
  ];
  List<String> todayHistory = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(
      () {
        streak = prefs.getInt(
              'streak',
            ) ??
            0;
        totalSessions = prefs.getInt(
              'total',
            ) ??
            0;
        todayHistory = prefs.getStringList(
              'history',
            ) ??
            [];
      },
    );
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'streak',
      streak,
    );
    await prefs.setInt(
      'total',
      totalSessions,
    );
    await prefs.setStringList(
      'history',
      todayHistory,
    );
  }

  void startWork() {
    setState(
      () {
        isWorking = true;
        isBreakTime = false;
      },
    );
    workTimer?.cancel();
    workTimer = Timer.periodic(
      const Duration(
        seconds: 1,
      ),
      (t) {
        if (workSeconds > 0) {
          setState(
            () => workSeconds--,
          );
        } else {
          t.cancel();
          startBreak();
        }
      },
    );
  }

  void startBreak() {
    final now = DateFormat(
      'HH:mm',
    ).format(
      DateTime.now(),
    );
    setState(
      () {
        isBreakTime = true;
        breakSeconds = 20;
        totalSessions++;
        streak++;
        todayHistory.insert(
          0,
          'Sesi selesai jam $now',
        );
        if (todayHistory.length > 10) {
          todayHistory.removeLast();
        }
      },
    );
    saveData();
    workTimer = Timer.periodic(
      const Duration(
        seconds: 1,
      ),
      (t) {
        if (breakSeconds > 0) {
          setState(
            () => breakSeconds--,
          );
        } else {
          t.cancel();
          setState(
            () {
              isWorking = false;
              isBreakTime = false;
              workSeconds = 20 * 60;
            },
          );
        }
      },
    );
  }

  void pauseTimer() {
    workTimer?.cancel();
    setState(
      () => isWorking = false,
    );
  }

  void resetTimer() {
    workTimer?.cancel();
    setState(
      () {
        workSeconds = 20 * 60;
        isWorking = false;
        isBreakTime = false;
      },
    );
  }

  String formatTime(
    int s,
  ) {
    int m = s ~/ 60;
    int sec = s % 60;
    return '${m.toString().padLeft(
      2,
      '0',
    )}:${sec.toString().padLeft(
      2,
      '0',
    )}';
  }

  @override
  void dispose() {
    workTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F3FF,
      ),
      appBar: AppBar(
        title: Text(
          'EyeBreak',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: currentIndex == 0
          ? buildTimerPage()
          : currentIndex == 1
              ? buildStatsPage()
              : buildExtraInfo(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(
          () => currentIndex = i,
        ),
        selectedItemColor: Colors.deepPurple,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.timer,
            ),
            label: 'Timer',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.bar_chart,
            ),
            label: 'Statistik',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.lightbulb,
            ),
            label: 'Tips',
          ),
        ],
      ),
    );
  }

  Widget buildTimerPage() {
    double progress = 1 - (workSeconds / totalSeconds);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(
          20,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  20,
                ),
              ),
              child: Text(
                DateFormat(
                  'EEEE, dd MMM yyyy',
                ).format(
                  DateTime.now(),
                ),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 260,
                  height: 260,
                  child: CircularProgressIndicator(
                    value: isWorking ? progress : 0,
                    strokeWidth: 14,
                    backgroundColor: Colors.deepPurple.withOpacity(
                      0.08,
                    ),
                    valueColor: const AlwaysStoppedAnimation(
                      Colors.deepPurple,
                    ),
                  ),
                ),
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(
                          0.1,
                        ),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isBreakTime
                            ? Icons.visibility
                            : Icons.timer_outlined,
                        size: 56,
                        color: isBreakTime
                            ? Colors.orange
                            : Colors.deepPurple,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Text(
                        isBreakTime
                            ? 'ISTIRAHAT!'
                            : formatTime(
                                workSeconds,
                              ),
                        style: GoogleFonts.poppins(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: isBreakTime
                              ? Colors.orange
                              : Colors.deepPurple,
                        ),
                      ),
                      Text(
                        isBreakTime
                            ? '${breakSeconds}s lihat jauh'
                            : 'Fokus 20 menit',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 30,
            ),
            Container(
              padding: const EdgeInsets.all(
                14,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(
                    'Streak',
                    '$streak hari',
                    Icons.local_fire_department,
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey.shade200,
                  ),
                  _statItem(
                    'Total',
                    '$totalSessions sesi',
                    Icons.check_circle,
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey.shade200,
                  ),
                  _statItem(
                    'Hari ini',
                    '${weeklyData.last} sesi',
                    Icons.today,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isWorking
                        ? pauseTimer
                        : startWork,
                    icon: Icon(
                      isWorking
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    label: Text(
                      isWorking
                          ? 'Pause'
                          : 'Mulai Fokus',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                ElevatedButton(
                  onPressed: resetTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 22,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                  child: const Icon(
                    Icons.refresh,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.deepPurple,
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.deepPurple,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget buildStatsPage() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(
          20,
        ),
        children: [
          const Text(
            'Statistik Mingguan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Container(
            height: 240,
            padding: const EdgeInsets.all(
              16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                20,
              ),
            ),
            child: BarChart(
              BarChartData(
                barGroups: List.generate(
                  7,
                  (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: weeklyData[i].toDouble(),
                          color: Colors.deepPurple,
                          width: 18,
                          borderRadius: BorderRadius.circular(
                            6,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                gridData: const FlGridData(
                  show: false,
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (
                        v,
                        m,
                      ) {
                        const days = [
                          'Sen',
                          'Sel',
                          'Rab',
                          'Kam',
                          'Jum',
                          'Sab',
                          'Min',
                        ];
                        return Text(
                          days[v.toInt()],
                          style: const TextStyle(
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildExtraInfo() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(
          20,
        ),
        children: [
          const Text(
            'Tips Kesehatan Mata',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          _tipCard(
            Icons.water_drop,
            'Minum Air',
            '8 gelas sehari',
          ),
          _tipCard(
            Icons.light_mode,
            'Pencahayaan',
            'Jangan gelap',
          ),
          _tipCard(
            Icons.distance,
            'Jarak 50cm',
            '40-60cm ideal',
          ),
          _tipCard(
            Icons.blur_on,
            'Kedip',
            'Tiap 5 detik',
          ),
          _tipCard(
            Icons.nightlight,
            'Mode Malam',
            'Blue light filter',
          ),
          _tipCard(
            Icons.sports_gymnastics,
            'Senam Mata',
            'Putar bola mata',
          ),
          _tipCard(
            Icons.timer_off,
            '20-20-20',
            '20 menit lihat jauh',
          ),
          _tipCard(
            Icons.visibility_off,
            'Tutup Mata',
            '5 menit tiap 2 jam',
          ),
          _tipCard(
            Icons.phone_android,
            'Kecerahan',
            '60-70% cukup',
          ),
          _tipCard(
            Icons.healing,
            'Kompres',
            '1 menit hangat',
          ),
        ],
      ),
    );
  }

  Widget _tipCard(
    IconData icon,
    String title,
    String desc,
  ) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          14,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.deepPurple,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          desc,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
