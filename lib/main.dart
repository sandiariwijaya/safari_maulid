import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Alamat website. Aplikasi selalu online & membuka website ini,
/// jadi semua isi (jadwal, kitab, galeri, dll) sama persis dengan web.
const String kUrl = 'https://safarimaulid.web.id/';
const List<String> kHostSendiri = ['safarimaulid.web.id', 'www.safarimaulid.web.id'];

const Color kMaroon = Color(0xFF6B1010);
const Color kMaroonDeep = Color(0xFF3A0707);
const Color kGold = Color(0xFFE3C77D);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: kMaroonDeep,
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
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: kMaroon, primary: kMaroon)),
      home: const HalamanWeb(),
    );
  }
}

class HalamanWeb extends StatefulWidget {
  const HalamanWeb({super.key});
  @override
  State<HalamanWeb> createState() => _HalamanWebState();
}

class _HalamanWebState extends State<HalamanWeb> {
  InAppWebViewController? _web;
  late final PullToRefreshController _tarik;
  double _progres = 0;
  bool _pertamaSelesai = false;
  String? _error;
  DateTime? _terakhirKembali;

  @override
  void initState() {
    super.initState();
    _tarik = PullToRefreshController(
      settings: PullToRefreshSettings(color: kMaroon),
      onRefresh: () async {
        await _web?.reload();
      },
    );
  }

  bool _hostSendiri(Uri? u) => u != null && kHostSendiri.contains(u.host.toLowerCase());

  Future<void> _bukaLuar(Uri u) async {
    try {
      final ok = await launchUrl(u, mode: LaunchMode.externalApplication);
      if (!ok && mounted) _pesan('Tidak ada aplikasi untuk membuka tautan ini.');
    } catch (_) {
      if (mounted) _pesan('Tidak dapat membuka tautan.');
    }
  }

  void _pesan(String t) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(t), behavior: SnackBarBehavior.floating, backgroundColor: kMaroonDeep));
  }

  Future<void> _kembali() async {
    final web = _web;
    if (_error != null) {
      setState(() => _error = null);
      return;
    }
    if (web != null && await web.canGoBack()) {
      await web.goBack();
      return;
    }
    final now = DateTime.now();
    if (_terakhirKembali == null || now.difference(_terakhirKembali!) > const Duration(seconds: 2)) {
      _terakhirKembali = now;
      _pesan('Tekan sekali lagi untuk keluar');
      return;
    }
    await SystemNavigator.pop();
  }

  Future<void> _cobaLagi() async {
    setState(() {
      _error = null;
      _progres = 0;
    });
    final url = await _web?.getUrl();
    await _web?.loadUrl(urlRequest: URLRequest(url: url ?? WebUri(kUrl)));
  }

  /// Buka beranda: saat offline, beranda diambil dari data yang tersimpan di HP
  Future<void> _keBeranda() async {
    setState(() => _error = null);
    await _web?.loadUrl(urlRequest: URLRequest(url: WebUri(kUrl)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _kembali();
      },
      child: Scaffold(
        backgroundColor: kMaroonDeep,
        body: SafeArea(
          child: Stack(children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(kUrl)),
              pullToRefreshController: _tarik,
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                useShouldOverrideUrlLoading: true,
                useOnDownloadStart: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                supportZoom: false,
                builtInZoomControls: false,
                displayZoomControls: false,
                cacheEnabled: true,
                allowFileAccess: true,
                applicationNameForUserAgent: 'SafariMaulidApp/1.2',
              ),
              onWebViewCreated: (c) => _web = c,
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
                // YouTube, Instagram, WhatsApp, Google Maps, telepon, dll -> buka di aplikasinya
                await _bukaLuar(u);
                return NavigationActionPolicy.CANCEL;
              },
              onDownloadStartRequest: (c, req) async {
                // Foto / PDF diunduh lewat browser HP
                await _bukaLuar(req.url);
              },
              onPermissionRequest: (c, req) async {
                // Kamera untuk upload foto dari panel admin
                final butuhKamera = req.resources.contains(PermissionResourceType.CAMERA);
                if (butuhKamera) {
                  final st = await Permission.camera.request();
                  if (!st.isGranted) {
                    return PermissionResponse(resources: req.resources, action: PermissionResponseAction.DENY);
                  }
                }
                return PermissionResponse(resources: req.resources, action: PermissionResponseAction.GRANT);
              },
            ),
            if (_progres < 1 && _pertamaSelesai && _error == null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(value: _progres, minHeight: 3, color: kGold, backgroundColor: Colors.transparent),
              ),
            if (!_pertamaSelesai) const _LayarMuat(),
            if (_error != null) _LayarOffline(pesan: _error!, onCobaLagi: _cobaLagi, onBeranda: _keBeranda),
          ]),
        ),
      ),
    );
  }
}

class _LayarMuat extends StatelessWidget {
  const _LayarMuat();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [kMaroon, kMaroonDeep], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image(image: AssetImage('assets/logo.png'), width: 110),
          SizedBox(height: 16),
          Text('Safari Maulid', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
          Text('KARESIDENAN MADIUN', style: TextStyle(color: kGold, fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w700)),
          SizedBox(height: 28),
          SizedBox(width: 26, height: 26, child: CircularProgressIndicator(color: kGold, strokeWidth: 3)),
        ]),
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
      color: const Color(0xFFFBF7EF),
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Image(image: AssetImage('assets/logo.png'), width: 84),
          const SizedBox(height: 18),
          const Icon(Icons.wifi_off_rounded, size: 46, color: kMaroon),
          const SizedBox(height: 10),
          const Text('Tidak ada koneksi internet',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: kMaroon)),
          const SizedBox(height: 6),
          const Text(
              'Halaman ini belum tersimpan di HP. Beranda, jadwal, kitab, galeri, sejarah, pengurus, legalitas & panduan '
              'tetap bisa dibuka dari data yang tersimpan saat terakhir online.',
              textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF85745F), height: 1.4)),
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
    );
  }
}
