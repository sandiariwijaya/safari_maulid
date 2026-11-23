import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Alamat website. Semua isi diambil dari website ini (online),
/// dan tersimpan otomatis di HP untuk dibuka saat offline.
const String kWeb = 'https://safarimaulid.web.id/';
const String kUa = 'SafariMaulidApp/1.4';
const List<String> kHostSendiri = ['safarimaulid.web.id', 'www.safarimaulid.web.id'];
const String kYoutube = 'https://www.youtube.com/@AlHidayahMedia-85';
const String kInstagram = 'https://www.instagram.com/safari_maulid/';

const Color kMaroon = Color(0xFF6B1010);
const Color kMaroon2 = Color(0xFF8B2323);
const Color kMaroonDeep = Color(0xFF3A0707);
const Color kGold = Color(0xFFE3C77D);
const Color kGold2 = Color(0xFFC9A24A);
const Color kCream = Color(0xFFFBF7EF);
const Color kInk = Color(0xFF2B2118);
const Color kMuted = Color(0xFF85745F);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Atur.i.muat();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: kMaroonDeep,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const SafariMaulidApp());
}

class SafariMaulidApp extends StatelessWidget {
  const SafariMaulidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Atur.i,
      builder: (context, _) {
        final t = Atur.i.tema;
        return MaterialApp(
          title: 'Safari Maulid',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: t.utama, primary: t.utama),
            scaffoldBackgroundColor: kCream,
            appBarTheme: AppBarTheme(
              backgroundColor: t.utama,
              foregroundColor: Colors.white,
              titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          home: const HalamanUtama(),
        );
      },
    );
  }
}

// =====================================================================
// PENGATURAN (tersimpan di HP masing-masing)
// =====================================================================
class Tema {
  final String nama;
  final Color utama, terang, gelap, aksen;
  const Tema(this.nama, this.utama, this.terang, this.gelap, this.aksen);
}

const List<Tema> kTema = [
  Tema('Merah marun', kMaroon, kMaroon2, kMaroonDeep, kGold),
  Tema('Hijau', Color(0xFF0F5C3A), Color(0xFF1B7A50), Color(0xFF07331F), kGold),
  Tema('Biru', Color(0xFF123F75), Color(0xFF1E5CA3), Color(0xFF0A2445), kGold),
  Tema('Coklat', Color(0xFF5B3A1E), Color(0xFF7A5230), Color(0xFF33200F), kGold),
  Tema('Hitam', Color(0xFF222222), Color(0xFF3A3A3A), Color(0xFF0E0E0E), kGold),
];

/// Bagian-bagian halaman depan (kode, nama).
const List<(String, String)> kBagian = [
  ('jam', 'Jam & tanggal'),
  ('jalan', 'Tulisan berjalan jadwal hari ini'),
  ('menu', 'Menu utama'),
  ('kitab', 'Pilihan kitab'),
  ('ikuti', 'Ikuti kami (YouTube, Instagram, Website)'),
];

class Atur extends ChangeNotifier {
  Atur._();
  static final Atur i = Atur._();
  SharedPreferences? _p;

  // halaman depan
  List<String> urutanBagian = [for (final b in kBagian) b.$1];
  Set<String> bagianSembunyi = {};
  List<String> urutanMenu = [for (final m in kMenu) m.judul];
  Set<String> menuSembunyi = {};
  int kolom = 3;
  // warna & ukuran
  int temaKe = 0;
  double skalaHuruf = 1.0;
  double skalaIkon = 1.0;
  double kecepatanJalan = 1.0;
  // halaman web
  int webZoom = 100;
  bool webTerjemah = true;
  int webHurufArab = 30;
  int webGulir = 50;
  bool webTasbih = true;
  int cap = 0; // berubah setiap pengaturan web disimpan

  Tema get tema => kTema[temaKe.clamp(0, kTema.length - 1)];

  List<String> _rapikan(List<String>? simpan, List<String> semua) {
    final hasil = <String>[for (final x in simpan ?? const <String>[]) if (semua.contains(x)) x];
    for (final x in semua) {
      if (!hasil.contains(x)) hasil.add(x);
    }
    return hasil;
  }

  Future<void> muat() async {
    try {
      final p = _p = await SharedPreferences.getInstance();
      urutanBagian = _rapikan(p.getStringList('urutanBagian'), [for (final b in kBagian) b.$1]);
      bagianSembunyi = (p.getStringList('bagianSembunyi') ?? const <String>[]).toSet();
      urutanMenu = _rapikan(p.getStringList('urutanMenu'), [for (final m in kMenu) m.judul]);
      menuSembunyi = (p.getStringList('menuSembunyi') ?? const <String>[]).toSet();
      kolom = p.getInt('kolom') ?? 3;
      temaKe = p.getInt('tema') ?? 0;
      skalaHuruf = p.getDouble('skalaHuruf') ?? 1.0;
      skalaIkon = p.getDouble('skalaIkon') ?? 1.0;
      kecepatanJalan = p.getDouble('kecepatanJalan') ?? 1.0;
      webZoom = p.getInt('webZoom') ?? 100;
      webTerjemah = p.getBool('webTerjemah') ?? true;
      webHurufArab = p.getInt('webHurufArab') ?? 30;
      webGulir = p.getInt('webGulir') ?? 50;
      webTasbih = p.getBool('webTasbih') ?? true;
      cap = p.getInt('cap') ?? 0;
    } catch (_) {}
  }

  /// Ubah pengaturan, simpan ke HP, lalu tampilan diperbarui.
  void ubah(void Function(Atur a) f, {bool web = false}) {
    f(this);
    if (web) cap = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
    _simpan();
  }

  Future<void> _simpan() async {
    final p = _p;
    if (p == null) return;
    await p.setStringList('urutanBagian', urutanBagian);
    await p.setStringList('bagianSembunyi', bagianSembunyi.toList());
    await p.setStringList('urutanMenu', urutanMenu);
    await p.setStringList('menuSembunyi', menuSembunyi.toList());
    await p.setInt('kolom', kolom);
    await p.setInt('tema', temaKe);
    await p.setDouble('skalaHuruf', skalaHuruf);
    await p.setDouble('skalaIkon', skalaIkon);
    await p.setDouble('kecepatanJalan', kecepatanJalan);
    await p.setInt('webZoom', webZoom);
    await p.setBool('webTerjemah', webTerjemah);
    await p.setInt('webHurufArab', webHurufArab);
    await p.setInt('webGulir', webGulir);
    await p.setBool('webTasbih', webTasbih);
    await p.setInt('cap', cap);
  }

  void kembalikanAwal() {
    urutanBagian = [for (final b in kBagian) b.$1];
    bagianSembunyi = {};
    urutanMenu = [for (final m in kMenu) m.judul];
    menuSembunyi = {};
    kolom = 3;
    temaKe = 0;
    skalaHuruf = 1.0;
    skalaIkon = 1.0;
    kecepatanJalan = 1.0;
    webZoom = 100;
    webTerjemah = true;
    webHurufArab = 30;
    webGulir = 50;
    webTasbih = true;
    cap = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
    _simpan();
  }

  List<Menu> get menuTampil => [
        for (final j in urutanMenu)
          if (!menuSembunyi.contains(j)) ...kMenu.where((m) => m.judul == j),
      ];

  /// Skrip yang dipasang di halaman web: menerapkan pilihan kitab (terjemah, ukuran huruf Arab,
  /// kecepatan gulir) sekali setiap pengaturan diubah, dan menyembunyikan penghitung tasbih.
  String get skripWeb => """
(function () {
  try {
    if (localStorage.getItem('sm_app_set') !== '$cap') {
      localStorage.setItem('sm_tr', '${webTerjemah ? 1 : 0}');
      localStorage.setItem('sm_fs', '$webHurufArab');
      localStorage.setItem('sm_gulir', '$webGulir');
      localStorage.setItem('sm_app_set', '$cap');
    }
  } catch (e) {}
  ${webTasbih ? '' : "document.addEventListener('DOMContentLoaded', function () { var s = document.createElement('style'); s.textContent = '.tasbih{display:none!important}'; document.head.appendChild(s); });"}
})();
""";
}

// =====================================================================
// HALAMAN UTAMA (menu-menu utama di depan)
// =====================================================================
class Menu {
  final IconData ikon;
  final String judul;
  final String alamat;
  const Menu(this.ikon, this.judul, this.alamat);
}

const List<Menu> kMenu = [
  Menu(Icons.event_note_rounded, 'Jadwal', 'jadwal.php'),
  Menu(Icons.menu_book_rounded, 'Kitab', 'kitab.php'),
  Menu(Icons.photo_library_rounded, 'Galeri', 'gallery.php'),
  Menu(Icons.history_edu_rounded, 'Sejarah', 'sejarah.php'),
  Menu(Icons.groups_rounded, 'Pengurus', 'struktur.php'),
  Menu(Icons.verified_rounded, 'Legalitas', 'legalitas.php'),
  Menu(Icons.auto_stories_rounded, 'Panduan', 'panduan.php'),
];

const List<(String, String, String)> kKitab = [
  ('ratib', 'Rotib Al-Haddad', 'الرَّاتِبُ الْحَدَّادْ'),
  ('simtud', 'Maulid Simtudduror', 'سِمْطُ الدُّرَرْ'),
  ('burdah', 'Qosidah Burdah', 'قَصِيْدَةُ الْبُرْدَةْ'),
  ('ummy', 'Sholawat Ummy', 'صَلَوَاتُ الْأُمِّيْ'),
  ('yasin', 'Surat Yaasin', 'سُوْرَةُ يٰسۤ'),
  ('wirdul', 'Wirdul Shoghir', 'الْوِرْدُ الصَّغِيْرْ'),
  ('tambahan', 'Tambahan', 'تَتِمَّةٌ'),
];

void bukaHalaman(BuildContext context, String alamat, String judul) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => HalamanWeb(alamat: kWeb + alamat, judul: judul)));
}

Future<void> bukaLuar(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}

class HalamanUtama extends StatefulWidget {
  const HalamanUtama({super.key});
  @override
  State<HalamanUtama> createState() => _HalamanUtamaState();
}

class _HalamanUtamaState extends State<HalamanUtama> {
  Timer? _t;
  DateTime _wib = _sekarangWib();
  DateTime? _kembali;

  static DateTime _sekarangWib() => DateTime.now().toUtc().add(const Duration(hours: 7));

  HeadlessInAppWebView? _sinkron;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _wib = _sekarangWib());
    });
    _mulaiSinkron();
    _ambilJadwal();
  }

  List<Map<String, dynamic>>? _jadwal; // jadwal hari ini (null = belum dimuat)

  Future<void> _ambilJadwal() async {
    try {
      final hc = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      hc.userAgent = kUa;
      final req = await hc.getUrl(Uri.parse('${kWeb}api.php?r=jadwal'));
      final res = await req.close().timeout(const Duration(seconds: 15));
      final body = await res.transform(utf8.decoder).join();
      hc.close();
      final j = jsonDecode(body);
      final data = (j is Map && j['data'] is Map) ? j['data'] : j;
      final list = (data is Map ? data['hari_ini'] : null) as List? ?? [];
      if (mounted) setState(() => _jadwal = list.map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (_) {
      if (mounted && _jadwal == null) setState(() => _jadwal = const []);
    }
  }

  String _teksJalan() {
    final j = _jadwal;
    if (j == null) return 'Memuat jadwal Safari hari ini …';
    if (j.isEmpty) return 'Tidak ada jadwal Safari Maulid hari ini — ketuk untuk melihat semua jadwal';
    return 'JADWAL SAFARI HARI INI:  ' +
        j.map((e) {
          final alamat = (e['alamat'] ?? '').toString().trim();
          return '${e['nama_tempat']}${alamat.isNotEmpty ? ' — $alamat' : ''}';
        }).join('   ✦   ') +
        '   ·   ketuk untuk detail';
  }

  void _bukaJadwalHariIni() {
    final j = _jadwal ?? const [];
    if (j.isEmpty) {
      bukaHalaman(context, 'jadwal.php', 'Jadwal');
      return;
    }
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: kCream,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .75),
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
            const Text('Jadwal Safari Hari Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kMaroon)),
            const SizedBox(height: 10),
            for (final e in j) _KartuJadwal(data: e),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: kMaroon),
              onPressed: () {
                Navigator.of(ctx).pop();
                bukaHalaman(context, 'jadwal.php', 'Jadwal');
              },
              icon: const Icon(Icons.event_note_rounded),
              label: const Text('Lihat semua jadwal'),
            ),
          ]),
        ),
      ),
    );
  }

  /// Saat aplikasi dibuka: diam-diam menyamakan data tersimpan di HP dengan web,
  /// sehingga halaman berikutnya langsung terbuka dari HP (cepat & tetap bisa offline).
  void _mulaiSinkron() {
    try {
      _sinkron = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('${kWeb}index.php?sinkron=1')),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          domStorageEnabled: true,
          databaseEnabled: true,
          cacheEnabled: true,
          applicationNameForUserAgent: kUa,
        ),
      );
      _sinkron!.run();
      Future.delayed(const Duration(minutes: 3), () {
        _sinkron?.dispose();
        _sinkron = null;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _t?.cancel();
    _sinkron?.dispose();
    super.dispose();
  }

  static const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', "Jum'at", 'Sabtu', 'Ahad'];
  static const _bulan = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
  String _dua(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: Atur.i, builder: (context, _) => _bangun(context));
  }

  Widget _bangun(BuildContext context) {
    final a = Atur.i;
    final t = a.tema;
    final mq = MediaQuery.of(context);
    final top = mq.padding.top;
    final tampil = a.urutanBagian.where((b) => !a.bagianSembunyi.contains(b)).toList();

    // ---------- kepala (logo, nama, tombol pengaturan, jam) ----------
    final kepala = MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Container(
        padding: EdgeInsets.fromLTRB(14, top + 8, 6, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [t.terang, t.utama, t.gelap], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Column(children: [
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset('assets/logo.png', width: 44, height: 44, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Safari Maulid', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, height: 1.1)),
                const SizedBox(height: 2),
                Text('KARESIDENAN MADIUN', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: t.aksen, fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w700)),
              ]),
            ),
            IconButton(
              tooltip: 'Login admin',
              icon: const Icon(Icons.login_rounded, color: Colors.white),
              onPressed: () => bukaHalaman(context, 'admin/login.php', 'Login'),
            ),
            IconButton(
              tooltip: 'Pengaturan',
              icon: const Icon(Icons.settings_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HalamanPengaturan())),
            ),
          ]),
          if (tampil.contains('jam')) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.aksen.withValues(alpha: 0.3)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text('${_dua(_wib.hour)}:${_dua(_wib.minute)}:${_dua(_wib.second)}',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1, fontFeatures: [FontFeature.tabularFigures()])),
                    const SizedBox(width: 3),
                    Text('WIB', style: TextStyle(color: t.aksen, fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 1)),
                    Container(width: 1, height: 16, margin: const EdgeInsets.symmetric(horizontal: 10), color: t.aksen.withValues(alpha: 0.5)),
                    Text('${_hari[_wib.weekday - 1]}, ${_wib.day} ${_bulan[_wib.month - 1]} ${_wib.year}',
                        style: const TextStyle(color: Color(0xFFF1DCD2), fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                ),
              ),
            ),
          ],
        ]),
      ),
    );

    Widget? bagian(String kode) {
      switch (kode) {
        case 'jalan':
          return Material(
            color: t.aksen,
            child: InkWell(
              onTap: _bukaJadwalHariIni,
              child: SizedBox(
                height: 34,
                child: Row(children: [
                  Container(
                    color: t.gelap,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    child: Icon(Icons.campaign_rounded, color: t.aksen, size: 20),
                  ),
                  Expanded(
                    child: _TeksBerjalan(
                      teks: _teksJalan(),
                      kecepatan: a.kecepatanJalan,
                      gaya: TextStyle(color: t.gelap, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ]),
              ),
            ),
          );
        case 'menu':
          final menu = a.menuTampil;
          if (menu.isEmpty) return null;
          final rasio = (a.kolom == 4 ? 1.0 : 1.35) / ((a.skalaHuruf + a.skalaIkon) / 2);
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const _Judul('Menu Utama'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.count(
                padding: EdgeInsets.zero,
                crossAxisCount: a.kolom,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: rasio,
                children: [for (final m in menu) _KotakMenu(menu: m)],
              ),
            ),
          ]);
        case 'kitab':
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const _Judul('Kitab'),
            _BarisKitab(tinggi: 44 * a.skalaHuruf),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Center(
                child: Text('‹ geser untuk melihat kitab lainnya ›',
                    style: TextStyle(color: kMuted, fontSize: 11.5, letterSpacing: .5)),
              ),
            ),
          ]);
        case 'ikuti':
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const _Judul('Ikuti Kami'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                Expanded(child: _Tautan(ikon: Icons.smart_display_rounded, label: 'YouTube', warna: const [Color(0xFFFF0033), Color(0xFFCC0029)], onTap: () => bukaLuar(kYoutube))),
                const SizedBox(width: 8),
                Expanded(child: _Tautan(ikon: Icons.camera_alt_rounded, label: 'Instagram', warna: const [Color(0xFFFD5949), Color(0xFFD6249F), Color(0xFF285AEB)], onTap: () => bukaLuar(kInstagram))),
                const SizedBox(width: 8),
                Expanded(child: _Tautan(ikon: Icons.language_rounded, label: 'Website', warna: [t.terang, t.gelap], onTap: () => bukaLuar(kWeb))),
              ]),
            ),
          ]);
      }
      return null;
    }

    final isi = <Widget>[kepala];
    for (final kode in tampil) {
      if (kode == 'jam') continue; // jam ada di dalam kepala
      final w = bagian(kode);
      if (w != null) isi.add(w);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_kembali == null || now.difference(_kembali!) > const Duration(seconds: 2)) {
          _kembali = now;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Tekan sekali lagi untuk keluar'), behavior: SnackBarBehavior.floating));
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        body: MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(a.skalaHuruf)),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              ...isi,
              const SizedBox(height: 14),
              const Center(
                child: Text('Tim Safari Maulid · safarimaulid.web.id', style: TextStyle(color: kMuted, fontSize: 11.5)),
              ),
              SizedBox(height: 12 + mq.padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

/// Deretan tombol kitab yang bisa digeser, dengan panah kecil di kiri & kanan.
class _BarisKitab extends StatefulWidget {
  final double tinggi;
  const _BarisKitab({required this.tinggi});
  @override
  State<_BarisKitab> createState() => _BarisKitabState();
}

class _BarisKitabState extends State<_BarisKitab> {
  final _gulir = ScrollController();
  bool _kiri = false, _kanan = true;

  @override
  void initState() {
    super.initState();
    _gulir.addListener(_cek);
    WidgetsBinding.instance.addPostFrameCallback((_) => _cek());
  }

  void _cek() {
    if (!_gulir.hasClients) return;
    final p = _gulir.position;
    final kiri = p.pixels > 2;
    final kanan = p.pixels < p.maxScrollExtent - 2;
    if (kiri != _kiri || kanan != _kanan) setState(() {
      _kiri = kiri;
      _kanan = kanan;
    });
  }

  void _geser(int arah) {
    if (!_gulir.hasClients) return;
    final p = _gulir.position;
    final tujuan = (p.pixels + arah * p.viewportDimension * 0.7).clamp(0.0, p.maxScrollExtent);
    _gulir.animateTo(tujuan, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _gulir.dispose();
    super.dispose();
  }

  Widget _panah(IconData ikon, VoidCallback onTap, Color warna) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: Color(0xFFE8DCC6))),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 28, height: 28, child: Icon(ikon, size: 20, color: warna)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = Atur.i;
    final t = a.tema;
    return SizedBox(
      height: widget.tinggi,
      child: Stack(alignment: Alignment.center, children: [
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (_) {
            _cek();
            return false;
          },
          child: ListView.separated(
            controller: _gulir,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: kKitab.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final k = kKitab[i];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => bukaHalaman(context, 'kitab.php?k=${k.$1}', k.$2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE8DCC6)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.menu_book_rounded, color: t.utama, size: 18 * a.skalaIkon),
                      const SizedBox(width: 6),
                      Text(k.$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kInk)),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
        if (_kiri) Positioned(left: 4, child: _panah(Icons.chevron_left_rounded, () => _geser(-1), t.utama)),
        if (_kanan) Positioned(right: 4, child: _panah(Icons.chevron_right_rounded, () => _geser(1), t.utama)),
      ]),
    );
  }
}

class _Judul extends StatelessWidget {
  final String teks;
  const _Judul(this.teks);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: kGold2, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text(teks, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kInk)),
      ]),
    );
  }
}

class _KotakMenu extends StatelessWidget {
  final Menu menu;
  const _KotakMenu({required this.menu});
  @override
  Widget build(BuildContext context) {
    final t = Atur.i.tema;
    final k = Atur.i.skalaIkon;
    final login = menu.judul == 'Login';
    return Material(
      color: login ? t.utama : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => bukaHalaman(context, menu.alamat, menu.judul),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: login ? t.utama : const Color(0xFFE8DCC6)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 40 * k,
              height: 40 * k,
              decoration: BoxDecoration(
                gradient: login
                    ? const LinearGradient(colors: [kGold, kGold2])
                    : LinearGradient(colors: [t.terang, t.utama], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12 * k),
              ),
              child: Icon(menu.ikon, color: login ? t.gelap : t.aksen, size: 22 * k),
            ),
            const SizedBox(height: 5),
            Text(menu.judul, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: login ? Colors.white : kInk)),
          ]),
        ),
      ),
    );
  }
}

class _Tautan extends StatelessWidget {
  final IconData ikon;
  final String label;
  final List<Color> warna;
  final VoidCallback onTap;
  const _Tautan({required this.ikon, required this.label, required this.warna, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(gradient: LinearGradient(colors: warna), borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(ikon, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ]),
      ),
    );
  }
}

/// Teks berjalan (marquee) sederhana yang berulang tanpa putus.
class _TeksBerjalan extends StatefulWidget {
  final String teks;
  final TextStyle gaya;
  final double kecepatan;
  const _TeksBerjalan({required this.teks, required this.gaya, this.kecepatan = 1.0});
  @override
  State<_TeksBerjalan> createState() => _TeksBerjalanState();
}

class _TeksBerjalanState extends State<_TeksBerjalan> {
  final _gulir = ScrollController();
  Timer? _t;
  double _pos = 0;

  double get _lebar {
    final tp = TextPainter(text: TextSpan(text: '${widget.teks}          ', style: widget.gaya), textDirection: TextDirection.ltr, maxLines: 1)
      ..layout();
    return tp.width;
  }

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!_gulir.hasClients) return;
      final w = _lebar;
      _pos += 1.1 * widget.kecepatan;
      if (_pos >= w) _pos -= w;
      _gulir.jumpTo(_pos.clamp(0.0, _gulir.position.maxScrollExtent));
    });
  }

  @override
  void didUpdateWidget(covariant _TeksBerjalan old) {
    super.didUpdateWidget(old);
    if (old.teks != widget.teks) _pos = 0;
  }

  @override
  void dispose() {
    _t?.cancel();
    _gulir.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final satu = '${widget.teks}          ';
    return IgnorePointer(
      child: SingleChildScrollView(
        controller: _gulir,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Center(child: Text(satu * 4, maxLines: 1, softWrap: false, style: widget.gaya)),
        ),
      ),
    );
  }
}

class _KartuJadwal extends StatelessWidget {
  final Map<String, dynamic> data;
  const _KartuJadwal({required this.data});

  String _v(String k) => (data[k] ?? '').toString().trim();

  String? _wa() {
    final m = RegExp(r'(\+?62|0)8[\d\s\-.]{7,14}').firstMatch(_v('khodim'));
    if (m == null) return null;
    var hp = m.group(0)!.replaceAll(RegExp(r'\D'), '');
    if (hp.startsWith('0')) hp = '62${hp.substring(1)}';
    return hp;
  }

  @override
  Widget build(BuildContext context) {
    final peta = _v('peta_url');
    final wa = _wa();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8DCC6)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_v('hijriah').isNotEmpty)
          Text('${_v('hari')} · ${_v('hijriah')}', style: const TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(_v('nama_tempat'), style: const TextStyle(color: kInk, fontSize: 16, fontWeight: FontWeight.w800)),
        if (_v('tag').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_v('tag'), style: const TextStyle(color: kGold2, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        if (_v('alamat').isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.place_rounded, size: 16, color: kMaroon),
            const SizedBox(width: 4),
            Expanded(child: Text(_v('alamat'), style: const TextStyle(fontSize: 13, height: 1.3))),
          ]),
        ],
        if (_v('khodim').isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.person_rounded, size: 16, color: kMaroon),
            const SizedBox(width: 4),
            Expanded(child: Text(_v('khodim'), style: const TextStyle(fontSize: 13, height: 1.3))),
          ]),
        ],
        if (peta.isNotEmpty || wa != null) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            if (peta.isNotEmpty)
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: kMaroon, visualDensity: VisualDensity.compact),
                onPressed: () => bukaLuar(peta),
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('Peta'),
              ),
            if (wa != null)
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1FA855), visualDensity: VisualDensity.compact),
                onPressed: () => bukaLuar('https://wa.me/$wa'),
                icon: const Icon(Icons.chat_rounded, size: 18),
                label: const Text('WhatsApp'),
              ),
          ]),
        ],
      ]),
    );
  }
}

// =====================================================================
// HALAMAN PENGATURAN
// =====================================================================
class HalamanPengaturan extends StatelessWidget {
  const HalamanPengaturan({super.key});

  static const _namaKecepatan = {25: 'Lambat', 50: 'Sedang', 80: 'Cepat'};

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Atur.i,
      builder: (context, _) {
        final a = Atur.i;
        final t = a.tema;
        return Scaffold(
          appBar: AppBar(title: const Text('Pengaturan')),
          body: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
            // ---------------- bagian halaman depan
            const _JudulAtur('Bagian halaman depan', 'Geser ☰ untuk mengubah urutan, matikan untuk menyembunyikan.'),
            _Kartu(
              child: ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorder: (lama, baru) => a.ubah((x) {
                  if (baru > lama) baru--;
                  final b = x.urutanBagian.removeAt(lama);
                  x.urutanBagian.insert(baru, b);
                }),
                children: [
                  for (var i = 0; i < a.urutanBagian.length; i++)
                    _BarisUrut(
                      key: ValueKey('b_${a.urutanBagian[i]}'),
                      index: i,
                      judul: kBagian.firstWhere((b) => b.$1 == a.urutanBagian[i]).$2,
                      aktif: !a.bagianSembunyi.contains(a.urutanBagian[i]),
                      warna: t.utama,
                      onUbah: (v) => a.ubah((x) {
                        if (v) {
                          x.bagianSembunyi.remove(x.urutanBagian[i]);
                        } else {
                          x.bagianSembunyi.add(x.urutanBagian[i]);
                        }
                      }),
                    ),
                ],
              ),
            ),

            // ---------------- menu utama
            const _JudulAtur('Menu utama', 'Atur menu yang tampil, urutan, dan jumlah kolom.'),
            _Kartu(
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                  child: Row(children: [
                    const Expanded(child: Text('Jumlah kolom', style: TextStyle(fontWeight: FontWeight.w600))),
                    SegmentedButton<int>(
                      segments: const [ButtonSegment(value: 3, label: Text('3')), ButtonSegment(value: 4, label: Text('4'))],
                      selected: {a.kolom},
                      showSelectedIcon: false,
                      onSelectionChanged: (v) => a.ubah((x) => x.kolom = v.first),
                    ),
                  ]),
                ),
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorder: (lama, baru) => a.ubah((x) {
                    if (baru > lama) baru--;
                    final m = x.urutanMenu.removeAt(lama);
                    x.urutanMenu.insert(baru, m);
                  }),
                  children: [
                    for (var i = 0; i < a.urutanMenu.length; i++)
                      _BarisUrut(
                        key: ValueKey('m_${a.urutanMenu[i]}'),
                        index: i,
                        judul: a.urutanMenu[i],
                        ikon: kMenu.firstWhere((m) => m.judul == a.urutanMenu[i]).ikon,
                        aktif: !a.menuSembunyi.contains(a.urutanMenu[i]),
                        warna: t.utama,
                        onUbah: (v) => a.ubah((x) {
                          if (v) {
                            x.menuSembunyi.remove(x.urutanMenu[i]);
                          } else {
                            x.menuSembunyi.add(x.urutanMenu[i]);
                          }
                        }),
                      ),
                  ],
                ),
              ]),
            ),

            // ---------------- warna & ukuran
            const _JudulAtur('Warna & ukuran', 'Berlaku untuk halaman depan dan bilah judul aplikasi.'),
            _Kartu(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Warna utama', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    for (var i = 0; i < kTema.length; i++)
                      InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () => a.ubah((x) => x.temaKe = i),
                        child: Column(children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [kTema[i].terang, kTema[i].gelap]),
                              border: Border.all(color: a.temaKe == i ? kGold2 : Colors.transparent, width: 3),
                            ),
                            child: a.temaKe == i ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
                          ),
                          const SizedBox(height: 3),
                          Text(kTema[i].nama, style: const TextStyle(fontSize: 11)),
                        ]),
                      ),
                  ]),
                  const SizedBox(height: 10),
                  _Geser(
                    judul: 'Ukuran tulisan',
                    nilai: a.skalaHuruf,
                    min: 0.85,
                    max: 1.3,
                    bagi: 9,
                    label: '${(a.skalaHuruf * 100).round()}%',
                    warna: t.utama,
                    onUbah: (v) => a.ubah((x) => x.skalaHuruf = v),
                  ),
                  _Geser(
                    judul: 'Ukuran ikon menu',
                    nilai: a.skalaIkon,
                    min: 0.8,
                    max: 1.4,
                    bagi: 12,
                    label: '${(a.skalaIkon * 100).round()}%',
                    warna: t.utama,
                    onUbah: (v) => a.ubah((x) => x.skalaIkon = v),
                  ),
                  _Geser(
                    judul: 'Kecepatan tulisan berjalan',
                    nilai: a.kecepatanJalan,
                    min: 0.5,
                    max: 3.0,
                    bagi: 10,
                    label: '${a.kecepatanJalan.toStringAsFixed(2)}x',
                    warna: t.utama,
                    onUbah: (v) => a.ubah((x) => x.kecepatanJalan = v),
                  ),
                ]),
              ),
            ),

            // ---------------- tampilan web
            const _JudulAtur('Tampilan halaman (jadwal, kitab, galeri, dll.)',
                'Berlaku saat halaman dibuka berikutnya.'),
            _Kartu(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _Geser(
                    judul: 'Ukuran teks halaman',
                    nilai: a.webZoom.toDouble(),
                    min: 80,
                    max: 150,
                    bagi: 14,
                    label: '${a.webZoom}%',
                    warna: t.utama,
                    onUbah: (v) => a.ubah((x) => x.webZoom = v.round(), web: true),
                  ),
                  _Geser(
                    judul: 'Ukuran huruf Arab kitab',
                    nilai: a.webHurufArab.toDouble(),
                    min: 20,
                    max: 48,
                    bagi: 14,
                    label: '${a.webHurufArab}',
                    warna: t.utama,
                    onUbah: (v) => a.ubah((x) => x.webHurufArab = v.round(), web: true),
                  ),
                  Row(children: [
                    const Expanded(child: Text('Kecepatan gulir otomatis kitab', style: TextStyle(fontWeight: FontWeight.w600))),
                    SegmentedButton<int>(
                      segments: [
                        for (final e in _namaKecepatan.entries) ButtonSegment(value: e.key, label: Text(e.value)),
                      ],
                      selected: {a.webGulir},
                      showSelectedIcon: false,
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                      onSelectionChanged: (v) => a.ubah((x) => x.webGulir = v.first, web: true),
                    ),
                  ]),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tampilkan terjemah kitab', style: TextStyle(fontWeight: FontWeight.w600)),
                    value: a.webTerjemah,
                    activeTrackColor: t.utama,
                    onChanged: (v) => a.ubah((x) => x.webTerjemah = v, web: true),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tampilkan penghitung tasbih', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Butir tasbih & tombol Hitung di bacaan berulang'),
                    value: a.webTasbih,
                    activeTrackColor: t.utama,
                    onChanged: (v) => a.ubah((x) => x.webTasbih = v, web: true),
                  ),
                ]),
              ),
            ),

            const SizedBox(height: 14),
            Center(
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: t.utama),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Kembalikan ke pengaturan awal'),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Kembalikan pengaturan?'),
                      content: const Text('Semua tampilan akan kembali seperti awal.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Kembalikan')),
                      ],
                    ),
                  );
                  if (ok == true) a.kembalikanAwal();
                },
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _JudulAtur extends StatelessWidget {
  final String judul;
  final String ket;
  const _JudulAtur(this.judul, this.ket);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(judul, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kInk)),
        const SizedBox(height: 2),
        Text(ket, style: const TextStyle(fontSize: 12, color: kMuted)),
      ]),
    );
  }
}

class _Kartu extends StatelessWidget {
  final Widget child;
  const _Kartu({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DCC6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _BarisUrut extends StatelessWidget {
  final int index;
  final String judul;
  final IconData? ikon;
  final bool aktif;
  final Color warna;
  final ValueChanged<bool> onUbah;
  const _BarisUrut({
    super.key,
    required this.index,
    required this.judul,
    this.ikon,
    required this.aktif,
    required this.warna,
    required this.onUbah,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: ListTile(
        dense: true,
        leading: ReorderableDragStartListener(
          index: index,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.drag_handle_rounded, color: kMuted),
          ),
        ),
        title: Row(children: [
          if (ikon != null) ...[Icon(ikon, size: 18, color: aktif ? warna : kMuted), const SizedBox(width: 8)],
          Expanded(
            child: Text(judul,
                style: TextStyle(fontWeight: FontWeight.w600, color: aktif ? kInk : kMuted)),
          ),
        ]),
        trailing: Switch(value: aktif, activeTrackColor: warna, onChanged: onUbah),
      ),
    );
  }
}

class _Geser extends StatelessWidget {
  final String judul;
  final double nilai;
  final double min;
  final double max;
  final int bagi;
  final String label;
  final Color warna;
  final ValueChanged<double> onUbah;
  const _Geser({
    required this.judul,
    required this.nilai,
    required this.min,
    required this.max,
    required this.bagi,
    required this.label,
    required this.warna,
    required this.onUbah,
  });
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(judul, style: const TextStyle(fontWeight: FontWeight.w600))),
        Text(label, style: TextStyle(color: warna, fontWeight: FontWeight.w800)),
      ]),
      Slider(
        value: nilai.clamp(min, max),
        min: min,
        max: max,
        divisions: bagi,
        activeColor: warna,
        onChanged: onUbah,
      ),
    ]);
  }
}

// =====================================================================
// HALAMAN WEB (isi dari safarimaulid.web.id)
// =====================================================================
class HalamanWeb extends StatefulWidget {
  final String alamat;
  final String judul;
  const HalamanWeb({super.key, required this.alamat, required this.judul});
  @override
  State<HalamanWeb> createState() => _HalamanWebState();
}

class _HalamanWebState extends State<HalamanWeb> {
  InAppWebViewController? _web;
  bool _layarMenyala = false;

  /// Halaman kitab: layar HP dibuat tetap menyala (tidak mati otomatis).
  void _aturLayar(WebUri? url) {
    final kitab = (url?.path ?? '').contains('kitab.php');
    if (kitab == _layarMenyala) return;
    _layarMenyala = kitab;
    WakelockPlus.toggle(enable: kitab).catchError((_) {});
  }

  @override
  void dispose() {
    if (_layarMenyala) WakelockPlus.disable().catchError((_) {});
    super.dispose();
  }
  late final PullToRefreshController _tarik;
  late String _judul = widget.judul;
  double _progres = 0;
  bool _pertamaSelesai = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tarik = PullToRefreshController(
      settings: PullToRefreshSettings(color: kMaroon),
      onRefresh: () async {
        await _segarkan();
      },
    );
  }

  bool _hostSendiri(Uri? u) => u != null && kHostSendiri.contains(u.host.toLowerCase());

  void _pesan(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(t), behavior: SnackBarBehavior.floating, backgroundColor: kMaroonDeep));
  }

  Future<void> _bukaLuar(Uri u) async {
    try {
      final ok = await launchUrl(u, mode: LaunchMode.externalApplication);
      if (!ok) _pesan('Tidak ada aplikasi untuk membuka tautan ini.');
    } catch (_) {
      _pesan('Tidak dapat membuka tautan.');
    }
  }

  Future<void> _kembali() async {
    if (_error != null) {
      setState(() => _error = null);
    }
    final web = _web;
    if (web != null && await web.canGoBack()) {
      await web.goBack();
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _cobaLagi() async {
    setState(() {
      _error = null;
      _progres = 0;
    });
    final url = await _web?.getUrl();
    await _web?.loadUrl(urlRequest: URLRequest(url: url ?? WebUri(widget.alamat)));
  }

  /// Ambil versi terbaru langsung dari web (melewati data tersimpan di HP).
  Future<void> _segarkan() async {
    final now = await _web?.getUrl();
    if (now == null) return;
    final u = Uri.parse(now.toString());
    final q = Map<String, String>.from(u.queryParameters)..['segar'] = '1';
    await _web?.loadUrl(urlRequest: URLRequest(url: WebUri(u.replace(queryParameters: q).toString())));
  }

  /// Kembali ke menu utama aplikasi (halaman beranda web tidak dipakai di APK).
  void _keMenu() {
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  bool _halamanBeranda(Uri u) {
    final p = u.path.toLowerCase();
    return p == '/' || p.isEmpty || p == '/index.php' || p == '/index.html';
  }

  String _rapikanJudul(String? t) {
    if (t == null || t.trim().isEmpty) return _judul;
    final i = t.indexOf(' — ');
    var j = i > 0 ? t.substring(0, i) : t;
    if (j.toUpperCase().startsWith('SAFARI MAULID')) j = 'Safari Maulid';
    return j.trim();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _kembali();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _kembali, tooltip: 'Kembali'),
          title: Text(_judul, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), tooltip: 'Muat ulang', onPressed: _segarkan),
            IconButton(
              icon: const Icon(Icons.grid_view_rounded),
              tooltip: 'Menu utama',
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: (_progres < 1 && _error == null)
                ? LinearProgressIndicator(value: _progres, minHeight: 3, color: kGold, backgroundColor: Colors.transparent)
                : const SizedBox(height: 3),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Stack(children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.alamat)),
              pullToRefreshController: _tarik,
              initialUserScripts: UnmodifiableListView<UserScript>([
                UserScript(source: Atur.i.skripWeb, injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START),
              ]),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                useShouldOverrideUrlLoading: true,
                useOnDownloadStart: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                supportZoom: true,
                builtInZoomControls: true,
                displayZoomControls: false,
                cacheEnabled: true,
                allowFileAccess: true,
                textZoom: Atur.i.webZoom,
                applicationNameForUserAgent: kUa,
              ),
              onWebViewCreated: (c) => _web = c,
              onTitleChanged: (c, t) {
                final j = _rapikanJudul(t);
                if (j != _judul) setState(() => _judul = j);
              },
              onProgressChanged: (c, p) {
                setState(() => _progres = p / 100);
                if (p >= 100) _tarik.endRefreshing();
              },
              onUpdateVisitedHistory: (c, url, isReload) => _aturLayar(url),
              onLoadStop: (c, url) {
                _aturLayar(url);
                _tarik.endRefreshing();
                if (!_pertamaSelesai) setState(() => _pertamaSelesai = true);
              },
              onReceivedError: (c, request, error) {
                _tarik.endRefreshing();
                if (request.isForMainFrame == false) return;
                if (error.type == WebResourceErrorType.CANCELLED) return;
                setState(() {
                  _pertamaSelesai = true;
                  _error = error.description;
                });
              },
              shouldOverrideUrlLoading: (c, aksi) async {
                final u = aksi.request.url;
                if (u == null) return NavigationActionPolicy.ALLOW;
                final skema = u.scheme.toLowerCase();
                if (skema == 'about' || skema == 'data' || skema == 'javascript' || skema == 'blob') {
                  return NavigationActionPolicy.ALLOW;
                }
                if ((skema == 'http' || skema == 'https') && _hostSendiri(u)) {
                  // tautan ke beranda web (logo, keluar admin, dsb.) -> kembali ke menu utama aplikasi
                  if (aksi.isForMainFrame && _halamanBeranda(u)) {
                    _keMenu();
                    return NavigationActionPolicy.CANCEL;
                  }
                  return NavigationActionPolicy.ALLOW;
                }
                await _bukaLuar(u);
                return NavigationActionPolicy.CANCEL;
              },
              onDownloadStartRequest: (c, req) async {
                await _bukaLuar(req.url);
              },
              onPermissionRequest: (c, req) async {
                if (req.resources.contains(PermissionResourceType.CAMERA)) {
                  final st = await Permission.camera.request();
                  if (!st.isGranted) {
                    return PermissionResponse(resources: req.resources, action: PermissionResponseAction.DENY);
                  }
                }
                return PermissionResponse(resources: req.resources, action: PermissionResponseAction.GRANT);
              },
            ),
            if (!_pertamaSelesai)
              const ColoredBox(
                color: kCream,
                child: Center(child: CircularProgressIndicator(color: kMaroon)),
              ),
            if (_error != null) _LayarOffline(pesan: _error!, onCobaLagi: _cobaLagi, onBeranda: _keMenu),
          ]),
        ),
      ),
    );
  }
}

class _LayarOffline extends StatelessWidget {
  final String pesan;
  final VoidCallback onCobaLagi;
  final VoidCallback onBeranda;
  const _LayarOffline({required this.pesan, required this.onCobaLagi, required this.onBeranda});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kCream,
      padding: const EdgeInsets.all(28),
      child: Center(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_rounded, size: 50, color: kMaroon),
            const SizedBox(height: 10),
            const Text('Tidak ada koneksi internet',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: kMaroon)),
            const SizedBox(height: 6),
            const Text(
                'Halaman ini belum tersimpan di HP. Jadwal, kitab, galeri, sejarah, pengurus, legalitas & panduan '
                'tetap bisa dibuka dari data yang tersimpan saat terakhir online.',
                textAlign: TextAlign.center, style: TextStyle(color: kMuted, height: 1.4)),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: kMaroon, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
              onPressed: onCobaLagi,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: kMaroon, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              onPressed: onBeranda,
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text('Kembali ke menu'),
            ),
            const SizedBox(height: 10),
            Text(pesan, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFFB0A391))),
          ]),
        ),
      ),
    );
  }
}
