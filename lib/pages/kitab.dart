import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';
import '../util.dart';

class HalamanKitab extends StatefulWidget {
  const HalamanKitab({super.key});
  @override
  State<HalamanKitab> createState() => _HalamanKitabState();
}

class _HalamanKitabState extends State<HalamanKitab> {
  double _ukuran = 26;
  bool _terjemah = true;
  final Map<String, int> _hitung = {};

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() {
        _ukuran = p.getDouble('kitab_ukuran') ?? 26;
        _terjemah = p.getBool('kitab_terjemah') ?? true;
      });
    });
  }

  Future<void> _simpan() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('kitab_ukuran', _ukuran);
    await p.setBool('kitab_terjemah', _terjemah);
  }

  void _ubahUkuran(double delta) {
    setState(() => _ukuran = (_ukuran + delta).clamp(18.0, 44.0));
    _simpan();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kitab'),
          actions: [
            IconButton(
              tooltip: _terjemah ? 'Sembunyikan terjemah' : 'Tampilkan terjemah',
              icon: Icon(_terjemah ? Icons.translate : Icons.g_translate_outlined),
              onPressed: () {
                setState(() => _terjemah = !_terjemah);
                _simpan();
              },
            ),
            IconButton(tooltip: 'Perkecil huruf', icon: const Icon(Icons.text_decrease), onPressed: () => _ubahUkuran(-2)),
            IconButton(tooltip: 'Perbesar huruf', icon: const Icon(Icons.text_increase), onPressed: () => _ubahUkuran(2)),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFE8CFCF),
            indicatorColor: kGold,
            indicatorWeight: 3,
            tabs: [Tab(text: 'Rotib Al-Haddad'), Tab(text: 'Maulid Simtudduror')],
          ),
        ),
        body: Muat(
          child: ListenableBuilder(
            listenable: Data.i,
            builder: (context, _) => TabBarView(children: [_isi('ratib'), _isi('simtud')]),
          ),
        ),
      ),
    );
  }

  Widget _isi(String kitab) {
    final d = Data.i;
    final grup = d.kitab[kitab] is List ? d.kitab[kitab] as List : const [];
    final arab = GoogleFonts.amiri(fontSize: _ukuran, height: 2.0, color: kInk);
    final terj = TextStyle(fontSize: (_ukuran * .55).clamp(13.0, 20.0), color: kMuted, fontStyle: FontStyle.italic, height: 1.5);
    return ListView(
      key: PageStorageKey('kitab_$kitab'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
      children: [
        Text(d.set('${kitab}_penyusun'),
            textAlign: TextAlign.center, style: const TextStyle(color: kMaroon, fontStyle: FontStyle.italic)),
        if (kitab == 'simtud' && d.set('simtud_catatan').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(d.set('simtud_catatan'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: kMuted)),
          ),
        const SizedBox(height: 8),
        Kartu(
          padding: EdgeInsets.zero,
          child: ExpansionTile(
            shape: const Border(),
            title: Text(d.set('${kitab}_intro_judul'),
                style: const TextStyle(fontWeight: FontWeight.w700, color: kMaroon, fontSize: 14.5)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [Text(bersihHtml(d.set('${kitab}_intro_isi')), style: const TextStyle(height: 1.55))],
          ),
        ),
        if (grup.isEmpty)
          const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('Belum ada data kitab.'))),
        for (var gi = 0; gi < grup.length; gi++) ..._grup(kitab, gi, grup[gi], arab, terj),
      ],
    );
  }

  List<Widget> _grup(String kitab, int gi, dynamic g, TextStyle arab, TextStyle terj) {
    final layout = s(g['layout']).isEmpty ? 'kartu' : s(g['layout']);
    final items = g['items'] is List ? g['items'] as List : const [];
    final out = <Widget>[JudulBagian('${gi + 1}. ${bersihHtml(g['group'])}')];

    if (layout == 'plain') {
      for (final it in items) {
        out.add(Kartu(child: Text(bersihHtml(it['plainText']), style: TextStyle(fontSize: (_ukuran * .6).clamp(14.0, 24.0), height: 1.7))));
      }
      return out;
    }

    if (layout == 'plain-arabic') {
      final kepala = <Widget>[
        if (s(g['titleArabic']).isNotEmpty)
          Text(bersihHtml(g['titleArabic']),
              textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: arab.copyWith(color: kMaroon, fontWeight: FontWeight.w700)),
        for (final k in ['subtitle', 'subtitle2', 'author'])
          if (s(g[k]).isNotEmpty)
            Text(bersihHtml(g[k]), textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontSize: 13, height: 1.5)),
      ];
      out.add(Kartu(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ...kepala,
          if (kepala.isNotEmpty) const Divider(height: 22),
          for (var i = 0; i < items.length; i++) ...[
            if (s(items[i]['arabic']).isNotEmpty)
              Text(bersihHtml(items[i]['arabic']),
                  textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: arab),
            if (_terjemah && s(items[i]['translation']).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(bersihHtml(items[i]['translation']), textAlign: TextAlign.center, style: terj),
              ),
            if (s(items[i]['plainText']).isNotEmpty) Text(bersihHtml(items[i]['plainText']), textAlign: TextAlign.center),
            if (g['_withBorder'] == true && i < items.length - 1) const Divider(color: Color(0xFFEADFCB)),
          ],
        ]),
      ));
      return out;
    }

    // kartu bacaan
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      final key = '$kitab-$gi-$i';
      final jumlah = int.tryParse(s(it['count'])) ?? 1;
      final n = _hitung[key] ?? 0;
      final doa = it['doa'] == true;
      out.add(Kartu(
        warna: doa ? const Color(0xFFFBF5E6) : null,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (s(it['arabic']).isNotEmpty)
            Text(bersihHtml(it['arabic']), textAlign: TextAlign.right, textDirection: TextDirection.rtl, style: arab),
          if (s(it['plainText']).isNotEmpty) Text(bersihHtml(it['plainText']), style: const TextStyle(height: 1.6)),
          if (_terjemah && s(it['translation']).isNotEmpty) ...[
            const Divider(height: 18, color: Color(0xFFEADFCB)),
            Text(bersihHtml(it['translation']), style: terj),
          ],
          if (jumlah > 1) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onLongPress: () => setState(() => _hitung.remove(key)),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: n >= jumlah ? Colors.green.shade700 : kMaroon),
                  onPressed: () => setState(() => _hitung[key] = n >= jumlah ? 0 : n + 1),
                  icon: Icon(n >= jumlah ? Icons.check_circle : Icons.touch_app, size: 18),
                  label: Text(n >= jumlah ? 'Selesai $jumlah×' : 'Dibaca $n / $jumlah×'),
                ),
              ),
            ),
          ],
        ]),
      ));
    }
    return out;
  }
}
