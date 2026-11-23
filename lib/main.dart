import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    return MaterialApp(
      title: 'Safari Maulid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kMaroon, primary: kMaroon),
        scaffoldBackgroundColor: kCream,
        appBarTheme: const AppBarTheme(
          backgroundColor: kMaroon,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      home: const HalamanUtama(),
    );
  }
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
  Menu(Icons.login_rounded, 'Login', 'admin/login.php'),
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
    final top = MediaQuery.of(context).padding.top;
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
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ---------- kepala ----------
            Container(
              padding: EdgeInsets.fromLTRB(20, top + 18, 20, 26),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [kMaroon2, kMaroon, kMaroonDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(children: [
                Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset('assets/logo.png', width: 64, height: 64, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Safari Maulid', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800, height: 1.1)),
                      SizedBox(height: 3),
                      Text('KARESIDENAN MADIUN', style: TextStyle(color: kGold, fontSize: 11.5, letterSpacing: 2.6, fontWeight: FontWeight.w700)),
                      SizedBox(height: 3),
                      Text('Majlis Dzikir, Sholawat & Taklim', style: TextStyle(color: Color(0xFFF1DCD2), fontSize: 12.5)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: kGold.withValues(alpha: 0.35)),
                  ),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${_dua(_wib.hour)}:${_dua(_wib.minute)}:${_dua(_wib.second)}',
                          style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800, height: 1, fontFeatures: [FontFeature.tabularFigures()])),
                      const SizedBox(width: 6),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text('WIB', style: TextStyle(color: kGold, fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 12)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text('${_hari[_wib.weekday - 1]}, ${_wib.day} ${_bulan[_wib.month - 1]} ${_wib.year}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  ]),
                ),
              ]),
            ),

            // ---------- menu utama ----------
            const _Judul('Menu Utama'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.05,
                children: [for (final m in kMenu) _KotakMenu(menu: m)],
              ),
            ),

            // ---------- kitab ----------
            const _Judul('Kitab'),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: kKitab.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final k = kKitab[i];
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => bukaHalaman(context, 'kitab.php?k=${k.$1}', k.$2),
                      child: Container(
                        width: 136,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8DCC6)),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.menu_book_rounded, color: kMaroon, size: 24),
                          const SizedBox(height: 6),
                          Text(k.$2, textAlign: TextAlign.center, maxLines: 2,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kInk, height: 1.2)),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ---------- tautan ----------
            const _Judul('Ikuti Kami'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(children: [
                Expanded(child: _Tautan(ikon: Icons.smart_display_rounded, label: 'YouTube', warna: const [Color(0xFFFF0033), Color(0xFFCC0029)], onTap: () => bukaLuar(kYoutube))),
                const SizedBox(width: 10),
                Expanded(child: _Tautan(ikon: Icons.camera_alt_rounded, label: 'Instagram', warna: const [Color(0xFFFD5949), Color(0xFFD6249F), Color(0xFF285AEB)], onTap: () => bukaLuar(kInstagram))),
                const SizedBox(width: 10),
                Expanded(child: _Tautan(ikon: Icons.language_rounded, label: 'Website', warna: const [kMaroon2, kMaroonDeep], onTap: () => bukaLuar(kWeb))),
              ]),
            ),
            const SizedBox(height: 26),
            const Center(
              child: Text('Tim Safari Maulid · safarimaulid.web.id', style: TextStyle(color: kMuted, fontSize: 12)),
            ),
            SizedBox(height: 20 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

class _Judul extends StatelessWidget {
  final String teks;
  const _Judul(this.teks);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
      child: Row(children: [
        Container(width: 5, height: 18, decoration: BoxDecoration(color: kGold2, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text(teks, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kInk)),
      ]),
    );
  }
}

class _KotakMenu extends StatelessWidget {
  final Menu menu;
  const _KotakMenu({required this.menu});
  @override
  Widget build(BuildContext context) {
    final login = menu.judul == 'Login';
    return Material(
      color: login ? kMaroon : Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => bukaHalaman(context, menu.alamat, menu.judul),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: login ? kMaroon : const Color(0xFFE8DCC6)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: login
                    ? const LinearGradient(colors: [kGold, kGold2])
                    : const LinearGradient(colors: [kMaroon2, kMaroon], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(menu.ikon, color: login ? kMaroonDeep : kGold, size: 27),
            ),
            const SizedBox(height: 8),
            Text(menu.judul,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: login ? Colors.white : kInk)),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(gradient: LinearGradient(colors: warna), borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Icon(ikon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ]),
      ),
    );
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

  Future<void> _keAwal() async {
    setState(() => _error = null);
    await _web?.loadUrl(urlRequest: URLRequest(url: WebUri(kWeb)));
  }

  String _rapikanJudul(String? t) {
    if (t == null || t.trim().isEmpty) return _judul;
    final i = t.indexOf(' — ');
    var j = i > 0 ? t.substring(0, i) : t;
    if (j.toUpperCase().startsWith('SAFARI MAULID')) j = 'Beranda';
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
              onLoadStop: (c, url) {
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
            if (_error != null) _LayarOffline(pesan: _error!, onCobaLagi: _cobaLagi, onBeranda: _keAwal),
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
                'Halaman ini belum tersimpan di HP. Beranda, jadwal, kitab, galeri, sejarah, pengurus, legalitas & panduan '
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
              icon: const Icon(Icons.offline_pin_outlined),
              label: const Text('Buka data tersimpan'),
            ),
            const SizedBox(height: 10),
            Text(pesan, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFFB0A391))),
          ]),
        ),
      ),
    );
  }
}
