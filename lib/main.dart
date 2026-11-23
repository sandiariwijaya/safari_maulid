import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api.dart';
import 'pages/beranda.dart';
import 'pages/galeri.dart';
import 'pages/jadwal.dart';
import 'pages/kitab.dart';
import 'pages/lainnya.dart';
import 'util.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  Data.i.muatAwal();
  runApp(const SafariMaulidApp());
}

class SafariMaulidApp extends StatelessWidget {
  const SafariMaulidApp({super.key});

  @override
  Widget build(BuildContext context) {
    final skema = ColorScheme.fromSeed(seedColor: kMaroon, primary: kMaroon, secondary: kGold, surface: Colors.white);
    return MaterialApp(
      title: 'Safari Maulid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: skema,
        scaffoldBackgroundColor: kCream,
        appBarTheme: const AppBarTheme(
          backgroundColor: kMaroon,
          foregroundColor: Colors.white,
          centerTitle: false,
          titleTextStyle: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: kGoldSoft,
          labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
      home: const Kerangka(),
    );
  }
}

class Kerangka extends StatefulWidget {
  const Kerangka({super.key});
  @override
  State<Kerangka> createState() => _KerangkaState();
}

class _KerangkaState extends State<Kerangka> {
  int _tab = 0;

  void pindahTab(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final halaman = [
      HalamanBeranda(keTab: pindahTab),
      const HalamanJadwal(),
      const HalamanKitab(),
      const HalamanGaleri(),
      const HalamanLainnya(),
    ];
    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _tab = 0);
      },
      child: Scaffold(
        body: IndexedStack(index: _tab, children: halaman),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: pindahTab,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: kMaroon), label: 'Beranda'),
            NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note, color: kMaroon), label: 'Jadwal'),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book, color: kMaroon), label: 'Kitab'),
            NavigationDestination(icon: Icon(Icons.photo_library_outlined), selectedIcon: Icon(Icons.photo_library, color: kMaroon), label: 'Galeri'),
            NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view, color: kMaroon), label: 'Lainnya'),
          ],
        ),
      ),
    );
  }
}
