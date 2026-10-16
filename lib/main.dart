import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const TokoKuApp());
}

class TokoKuApp extends StatelessWidget {
  const TokoKuApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Toko Ku',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final List<Map<String, dynamic>> _products = [];
  final List<Map<String, dynamic>> _cart = [];
  final List<Map<String, dynamic>> _transactions = [];
  final List<String> _categories = ['Makanan', 'Minuman', 'Snack', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final prodString = prefs.getString('products');
    final transString = prefs.getString('transactions');
    if (prodString!= null) {
      setState(() {
        _products.addAll(List<Map<String, dynamic>>.from(jsonDecode(prodString)));
      });
    } else {
      setState(() {
        _products.addAll([
          {'id': '1', 'name': 'Indomie Goreng', 'price': 3500, 'stock': 50, 'category': 'Makanan'},
          {'id': '2', 'name': 'Aqua 600ml', 'price': 3000, 'stock': 100, 'category': 'Minuman'},
          {'id': '3', 'name': 'Chitato', 'price': 10000, 'stock': 30, 'category': 'Snack'},
          {'id': '4', 'name': 'Beras 5kg', 'price': 65000, 'stock': 20, 'category': 'Makanan'},
          {'id': '5', 'name': 'Minyak Goreng', 'price': 18000, 'stock': 15, 'category': 'Lainnya'},
        ]);
      });
    }
    if (transString!= null) {
      setState(() {
        _transactions.addAll(List<Map<String, dynamic>>.from(jsonDecode(transString)));
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('products', jsonEncode(_products));
    await prefs.setString('transactions', jsonEncode(_transactions));
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final index = _cart.indexWhere((e) => e['id'] == product['id']);
      if (index >= 0) {
        _cart[index]['qty']++;
      } else {
        _cart.add({...product, 'qty': 1});
      }
    });
  }

  void _checkout() {
    if (_cart.isEmpty) return;
    double total = 0;
    for (var item in _cart) {
      total += (item['price'] * item['qty']);
    }
    final now = DateTime.now();
    setState(() {
      _transactions.add({
        'id': now.millisecondsSinceEpoch.toString(),
        'date': now.toIso8601String(),
        'total': total,
        'items': List.from(_cart),
      });
      for (var cartItem in _cart) {
        final prodIndex = _products.indexWhere((p) => p['id'] == cartItem['id']);
        if (prodIndex >= 0) {
          _products[prodIndex]['stock'] -= cartItem['qty'];
        }
      }
      _cart.clear();
    });
    _saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaksi berhasil! Total: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(total)}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(['Kasir', 'Stok', 'Laporan'][_currentIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: [
        _buildKasirPage(),
        _buildStokPage(),
        _buildLaporanPage(),
      ][_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Colors.blue,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Kasir'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stok'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Laporan'),
        ],
      ),
    );
  }

  Widget _buildKasirPage() {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.5, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: _products.length,
            itemBuilder: (ctx, i) {
              final p = _products[i];
              return InkWell(
                onTap: () => _addToCart(p),
                child: Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(p['category'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const Spacer(),
                        Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(p['price']), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        Text('Stok: ${p['stock']}', style: TextStyle(fontSize: 11, color: p['stock'] < 10? Colors.red : Colors.green)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_cart.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)], borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Keranjang (${_cart.length})', style: const TextStyle(fontWeight: FontWeight.bold)), TextButton(onPressed: () => setState(() => _cart.clear()), child: const Text('Kosongkan'))]),
               ..._cart.map((e) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${e['name']} x${e['qty']}'), Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(e['price'] * e['qty']))])),
                const Divider(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(_cart.fold(0.0, (sum, item) => sum + (item['price'] * item['qty']))), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue))]),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _checkout, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('BAYAR', style: TextStyle(fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStokPage() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _products.length,
      itemBuilder: (ctx, i) {
        final p = _products[i];
        return Card(
          child: ListTile(
            title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${p['category']} - ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(p['price'])}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.remove), onPressed: () { setState(() { if (p['stock'] > 0) p['stock']--; }); _saveData(); }),
              Text('${p['stock']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add), onPressed: () { setState(() { p['stock']++; }); _saveData(); }),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildLaporanPage() {
    double totalOmzet = _transactions.fold(0.0, (sum, t) => sum + t['total']);
    Map<String, double> daily = {};
    for (var t in _transactions) {
      final date = DateFormat('dd/MM').format(DateTime.parse(t['date']));
      daily[date] = (daily[date]?? 0) + t['total'];
    }
    final spots = daily.entries.toList().asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['total'] / 1000)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(color: Colors.blue, child: Padding(padding: const EdgeInsets.all(20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Total Omzet', style: TextStyle(color: Colors.white70)), SizedBox(height: 5)]), Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(totalOmzet), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))]))),
          const SizedBox(height: 20),
          const Text('Grafik Penjualan (dalam ribu)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: daily.isEmpty? const Center(child: Text('Belum ada transaksi')) : LineChart(LineChartData(lineBarsData: [LineChartBarData(spots: spots.isEmpty? [const FlSpot(0, 0)] : spots, isCurved: true, color: Colors.blue, barWidth: 3, dotData: const FlDotData(show: true))], titlesData: const FlTitlesData(show: true), gridData: const FlGridData(show: true), borderData: FlBorderData(show: true))),
          ),
          const SizedBox(height: 20),
          const Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
         ..._transactions.reversed.map((t) => Card(child: ListTile(title: Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(t['total']), style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(DateTime.parse(t['date']))), trailing: Text('${(t['items'] as List).length} item')))),
        ],
      ),
    );
  }
}
