import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Alamat website. Semua data aplikasi diambil dari sini.
const String kBaseUrl = 'https://safarimaulid.web.id';

/// Penyimpan data global: diambil dari api.php, disimpan juga di HP
/// supaya aplikasi tetap bisa dibuka saat tidak ada sinyal.
class Data extends ChangeNotifier {
  Data._();
  static final Data i = Data._();

  Map<String, dynamic> semua = {};
  Map<String, dynamic> kitab = {};
  bool memuat = false;
  bool offline = false;
  String? error;

  Map<String, dynamic> get pengaturan => _map(semua['pengaturan']);
  Map<String, dynamic> get beranda => _map(semua['beranda']);
  List<dynamic> get slider => _list(beranda['slider']);
  List<dynamic> get jadwal => _list(_map(semua['jadwal'])['semua']);
  List<dynamic> get jadwalHariIni => _list(_map(semua['jadwal'])['hari_ini']);
  Map<String, dynamic> get sejarah => _map(semua['sejarah']);
  List<dynamic> get pengurus => _list(semua['pengurus']);
  List<dynamic> get legalitas => _list(semua['legalitas']);
  List<dynamic> get panduan => _list(semua['panduan']);
  List<dynamic> get galeri => _list(semua['galeri']);

  String set(String k) => (pengaturan[k] ?? '').toString();

  bool get kosong => semua.isEmpty;

  static Map<String, dynamic> _map(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  static List<dynamic> _list(dynamic v) => v is List ? v : const [];

  Future<void> muatAwal() async {
    final prefs = await SharedPreferences.getInstance();
    final a = prefs.getString('cache_semua');
    final b = prefs.getString('cache_kitab');
    if (a != null) semua = _map(jsonDecode(a));
    if (b != null) kitab = _map(jsonDecode(b));
    notifyListeners();
    await segarkan();
  }

  Future<void> segarkan() async {
    if (memuat) return;
    memuat = true;
    error = null;
    notifyListeners();
    try {
      final hasil = await Future.wait([_ambil('semua'), _ambil('kitab')]);
      semua = hasil[0];
      kitab = hasil[1];
      offline = false;
    } catch (e) {
      offline = true;
      error = semua.isEmpty
          ? 'Tidak dapat terhubung ke server. Periksa koneksi internet lalu tarik ke bawah untuk memuat ulang.'
          : null;
    }
    memuat = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> _ambil(String r) async {
    final res = await http
        .get(Uri.parse('$kBaseUrl/api.php?r=$r'), headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final teks = utf8.decode(res.bodyBytes);
    final j = jsonDecode(teks);
    if (j is! Map || j['ok'] != true) throw Exception('Data tidak valid');
    final data = _map(j['data']);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cache_$r', jsonEncode(data));
    return data;
  }
}
