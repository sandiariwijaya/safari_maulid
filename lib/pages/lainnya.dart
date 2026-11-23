import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../api.dart';
import '../util.dart';
import 'viewer.dart';

class HalamanLainnya extends StatelessWidget {
  const HalamanLainnya({super.key});

  @override
  Widget build(BuildContext context) {
    void ke(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    return Scaffold(
      appBar: AppBar(title: const Text('Lainnya')),
      body: ListenableBuilder(
        listenable: Data.i,
        builder: (context, _) {
          final d = Data.i;
          final pdf = d.set('panduan_pdf_url');
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _menu(Icons.history_edu, 'Sejarah Safari Maulid', () => ke(const HalamanSejarah())),
              _menu(Icons.groups, 'Susunan Pengurus', () => ke(const HalamanPengurus())),
              _menu(Icons.verified, 'Legalitas', () => ke(const HalamanLegalitas())),
              _menu(Icons.auto_stories, 'Panduan Safari Maulid', () => ke(const HalamanPanduan())),
              if (pdf.isNotEmpty) _menu(Icons.picture_as_pdf, 'Unduh Panduan (PDF)', () => buka(pdf)),
              const SizedBox(height: 8),
              _menu(Icons.language, 'Buka Website', () => buka(kBaseUrl)),
              if (d.set('youtube_url').isNotEmpty) _menu(Icons.smart_display, 'YouTube', () => buka(d.set('youtube_url'))),
              if (d.set('instagram_url').isNotEmpty) _menu(Icons.camera_alt, 'Instagram', () => buka(d.set('instagram_url'))),
              const SizedBox(height: 20),
              Center(child: Image.asset('assets/logo.png', height: 64)),
              const SizedBox(height: 6),
              Center(
                child: Text(d.set('footer_teks'), textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontSize: 12)),
              ),
              if (d.offline)
                const Center(child: Text('Mode offline', style: TextStyle(color: kMuted, fontSize: 12))),
            ],
          );
        },
      ),
    );
  }

  Widget _menu(IconData ic, String t, VoidCallback f) => Kartu(
        padding: EdgeInsets.zero,
        onTap: f,
        child: ListTile(
          leading: CircleAvatar(backgroundColor: kGoldSoft, child: Icon(ic, color: kMaroon)),
          title: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right, color: kMuted),
        ),
      );
}

// =================================================================== SEJARAH
class HalamanSejarah extends StatelessWidget {
  const HalamanSejarah({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sejarah')),
      body: Muat(
        child: ListenableBuilder(
          listenable: Data.i,
          builder: (context, _) {
            final d = Data.i;
            final blok = d.sejarah['blok'] is List ? d.sejarah['blok'] as List : const [];
            final stat = d.sejarah['statistik'] is List ? d.sejarah['statistik'] as List : const [];
            const gaya = TextStyle(fontSize: 15, height: 1.65, color: kInk);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
              children: [
                Text(d.set('sejarah_bismillah'),
                    textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 24, color: kMaroon)),
                const SizedBox(height: 6),
                Text(d.set('sejarah_judul'),
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kMaroon)),
                const SizedBox(height: 10),
                for (final b in blok) _blok(b, stat, gaya),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _paragraf(String isi, TextStyle gaya) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final p in isi.split(RegExp(r'\n\s*\n')))
            if (p.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text.rich(teksKaya(p.trim(), gaya), textAlign: TextAlign.justify),
              ),
        ],
      );

  Widget _blok(dynamic b, List stat, TextStyle gaya) {
    final isi = s(b['isi']);
    switch (s(b['tipe'])) {
      case 'judul':
        return JudulBagian(s(b['judul']));
      case 'sorotan':
        return Kartu(
          warna: kGoldSoft,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (s(b['judul']).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(s(b['judul']), style: const TextStyle(fontWeight: FontWeight.w800, color: kMaroon)),
              ),
            _paragraf(isi, gaya),
          ]),
        );
      case 'daftar':
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(children: [
            for (final l in isi.split('\n'))
              if (l.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Padding(padding: EdgeInsets.only(top: 3, right: 8), child: Icon(Icons.star, size: 14, color: kGold)),
                    Expanded(child: Text.rich(teksKaya(l.trim(), gaya))),
                  ]),
                ),
          ]),
        );
      case 'statistik':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            for (final st in stat)
              Container(
                width: 104,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8DFCF)),
                ),
                child: Column(children: [
                  Text(s(st['angka']), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kMaroon)),
                  Text(s(st['label']), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: kMuted)),
                ]),
              ),
          ]),
        );
      case 'doa':
        return Kartu(
          warna: const Color(0xFFFBF5E6),
          child: Column(children: [
            Text.rich(teksKaya(isi, gaya.copyWith(fontStyle: FontStyle.italic)), textAlign: TextAlign.center),
            if (s(b['judul']).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(s(b['judul']), style: const TextStyle(fontWeight: FontWeight.w800, color: kGold)),
            ],
          ]),
        );
      default:
        return _paragraf(isi, gaya);
    }
  }
}

// =================================================================== PENGURUS
class HalamanPengurus extends StatelessWidget {
  const HalamanPengurus({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Susunan Pengurus')),
      body: Muat(
        child: ListenableBuilder(
          listenable: Data.i,
          builder: (context, _) {
            final d = Data.i;
            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 30),
              children: [
                if (d.set('struktur_deskripsi').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 4),
                    child: Text(d.set('struktur_deskripsi'), textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
                  ),
                for (final k in d.pengurus) ..._kelompok(k),
                if (d.set('struktur_catatan').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(d.set('struktur_catatan'),
                        textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontStyle: FontStyle.italic)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _kelompok(dynamic k) {
    final anggota = k['anggota'] is List ? k['anggota'] as List : const [];
    final tampil = s(k['tampilan']);
    final out = <Widget>[JudulBagian(s(k['nama']))];
    if (tampil == 'chip') {
      out.add(Wrap(spacing: 6, runSpacing: 6, children: [
        for (final a in anggota)
          Chip(
            label: Text(s(a['nama'])),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE8DFCF)),
          ),
      ]));
      return out;
    }
    for (final a in anggota) {
      final pembina = tampil == 'pembina';
      final jab = s(a['jabatan']).isEmpty ? s(k['nama']) : s(a['jabatan']);
      final dasar = pembina ? s(a['nama']).replaceFirst(RegExp(r'^al\s+', caseSensitive: false), '') : jab;
      final hp = s(a['telepon']);
      out.add(Kartu(
        warna: pembina ? kGoldSoft : null,
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: pembina ? kMaroon : kGold,
            child: Text(dasar.isEmpty ? '•' : dasar[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          title: Text(s(a['nama']), style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(hp.isEmpty ? jab.toUpperCase() : '${jab.toUpperCase()}\n$hp',
              style: const TextStyle(fontSize: 12, height: 1.4)),
          isThreeLine: hp.isNotEmpty,
          trailing: hp.isEmpty
              ? null
              : IconButton(
                  tooltip: 'WhatsApp',
                  icon: const Icon(Icons.chat, color: kMaroon),
                  onPressed: () => hubungiWa(hp),
                ),
        ),
      ));
    }
    return out;
  }
}

// =================================================================== LEGALITAS
class HalamanLegalitas extends StatelessWidget {
  const HalamanLegalitas({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legalitas')),
      body: Muat(
        child: ListenableBuilder(
          listenable: Data.i,
          builder: (context, _) {
            final d = Data.i;
            const gaya = TextStyle(fontSize: 14.5, height: 1.55, color: kInk);
            final poin = d.set('legal_poin').split('\n').where((e) => e.trim().isNotEmpty);
            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
              children: [
                Text(d.set('legal_judul'),
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kMaroon)),
                Text(d.set('legal_deskripsi'), textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
                const SizedBox(height: 12),
                Kartu(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text.rich(teksKaya(d.set('legal_intro'), gaya)),
                    const SizedBox(height: 8),
                    for (final p in poin)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Padding(padding: EdgeInsets.only(top: 2, right: 8), child: Icon(Icons.check_circle, size: 17, color: Colors.green)),
                          Expanded(child: Text.rich(teksKaya(p.trim(), gaya))),
                        ]),
                      ),
                    if (d.set('legal_badge').isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.verified, color: Colors.white, size: 18),
                        label: Text(d.set('legal_badge'), style: const TextStyle(color: Colors.white)),
                        backgroundColor: kMaroon,
                      ),
                  ]),
                ),
                JudulBagian('Dokumen (${d.legalitas.length})'),
                _GridDokumen(item: d.legalitas, judul: 'Legalitas'),
              ],
            );
          },
        ),
      ),
    );
  }
}

// =================================================================== PANDUAN
class HalamanPanduan extends StatelessWidget {
  const HalamanPanduan({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panduan')),
      body: Muat(
        child: ListenableBuilder(
          listenable: Data.i,
          builder: (context, _) {
            final d = Data.i;
            final urls = d.panduan.map((e) => s(e['url'])).toList();
            final pdf = d.set('panduan_pdf_url');
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
              children: [
                if (pdf.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FilledButton.icon(
                      onPressed: () => buka(pdf),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Unduh Panduan (PDF)'),
                    ),
                  ),
                for (var i = 0; i < urls.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => bukaViewer(context, urls, i, judul: 'Panduan'),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: urls[i],
                          fit: BoxFit.fitWidth,
                          placeholder: (_, __) => Container(height: 300, color: const Color(0xFFEDE4D3)),
                          errorWidget: (_, __, ___) => Container(height: 120, color: const Color(0xFFEDE4D3), child: const Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GridDokumen extends StatelessWidget {
  final List<dynamic> item;
  final String judul;
  const _GridDokumen({required this.item, required this.judul});

  @override
  Widget build(BuildContext context) {
    final urls = item.map((e) => s(e['url'])).toList();
    final ket = item.map((e) => s(e['keterangan'])).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: .72,
      ),
      itemCount: urls.length,
      itemBuilder: (context, i) => GestureDetector(
        onTap: () => bukaViewer(context, urls, i, judul: judul, keterangan: ket),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: urls[i],
            fit: BoxFit.cover,
            memCacheWidth: 320,
            placeholder: (_, __) => Container(color: const Color(0xFFEDE4D3)),
            errorWidget: (_, __, ___) => Container(color: const Color(0xFFEDE4D3), child: const Icon(Icons.broken_image)),
          ),
        ),
      ),
    );
  }
}
