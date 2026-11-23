import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../api.dart';
import '../util.dart';
import 'jadwal.dart';
import 'viewer.dart';

class HalamanBeranda extends StatelessWidget {
  final void Function(int) keTab;
  const HalamanBeranda({super.key, required this.keTab});

  @override
  Widget build(BuildContext context) {
    return Muat(
      child: ListenableBuilder(
        listenable: Data.i,
        builder: (context, _) {
          final d = Data.i;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _Header(),
              if (d.offline)
                Container(
                  color: const Color(0xFFFFF3CD),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Text('Mode offline — menampilkan data terakhir yang tersimpan.',
                      style: TextStyle(fontSize: 12.5)),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _HitungMundur(),
                    _JadwalRingkas(keTab: keTab),
                    if (d.slider.isNotEmpty) ...[
                      const JudulBagian('Dokumentasi'),
                      _Slider(item: d.slider),
                    ],
                    const JudulBagian('Menu'),
                    _MenuCepat(keTab: keTab),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final d = Data.i;
    final top = MediaQuery.of(context).padding.top;
    final arab = d
        .set('marquee_teks')
        .split('\n')
        .firstWhere((e) => RegExp(r'[\u0600-\u06FF]').hasMatch(e), orElse: () => '')
        .trim();
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 18, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [kMaroon, kMaroon2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Column(children: [
        Image.asset('assets/logo.png', height: 92),
        const SizedBox(height: 10),
        Text(d.set('nama_situs').isEmpty ? 'Safari Maulid' : d.set('nama_situs'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(d.set('meta_deskripsi'),
            textAlign: TextAlign.center, style: const TextStyle(color: kGoldSoft, fontSize: 13, letterSpacing: .8)),
        if (arab.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(arab, textDirection: TextDirection.rtl, style: const TextStyle(color: kGold, fontSize: 20)),
        ],
      ]),
    );
  }
}

// ---------------------------------------------------------------- hitung mundur
class _HitungMundur extends StatefulWidget {
  const _HitungMundur();
  @override
  State<_HitungMundur> createState() => _HitungMundurState();
}

class _HitungMundurState extends State<_HitungMundur> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Widget _kotak(String angka, String label) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Text(angka, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kMaroon)),
            Text(label, style: const TextStyle(fontSize: 11, color: kMuted)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final d = Data.i;
    final mulai = parseTgl(d.set('acara_mulai'));
    final selesai = parseTgl(d.set('acara_selesai'));
    if (mulai == null) return const SizedBox.shrink();
    final now = DateTime.now();
    Widget isi;
    if (now.isBefore(mulai)) {
      final sisa = mulai.difference(now);
      isi = Column(children: [
        Text('⏳ ${d.set('countdown_judul')}',
            textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, color: kMaroon)),
        Text(tglId(d.set('acara_mulai')), style: const TextStyle(color: kMuted, fontSize: 13)),
        const SizedBox(height: 10),
        Row(children: [
          _kotak('${sisa.inDays}', 'Hari'),
          _kotak('${sisa.inHours % 24}'.padLeft(2, '0'), 'Jam'),
          _kotak('${sisa.inMinutes % 60}'.padLeft(2, '0'), 'Menit'),
          _kotak('${sisa.inSeconds % 60}'.padLeft(2, '0'), 'Detik'),
        ]),
      ]);
    } else if (selesai == null || now.isBefore(selesai)) {
      final ke = hariIni().difference(DateTime(mulai.year, mulai.month, mulai.day)).inDays + 1;
      isi = Column(children: [
        const Text('🕌 Safari Maulid sedang berlangsung', style: TextStyle(fontWeight: FontWeight.w700, color: kMaroon)),
        const SizedBox(height: 6),
        Text('Hari ke-$ke', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: kMaroon)),
        Text('${tglId(d.set('acara_mulai'), tahun: false)} s/d ${tglId(d.set('acara_selesai'))}',
            style: const TextStyle(color: kMuted, fontSize: 13)),
      ]);
    } else {
      isi = Column(children: [
        const Text('Alhamdulillah, Safari Maulid telah selesai', style: TextStyle(fontWeight: FontWeight.w700, color: kMaroon)),
        Text('Jazakumullah khairan katsiran atas kehadirannya.', style: TextStyle(color: Colors.brown.shade400, fontSize: 13)),
      ]);
    }
    return Kartu(warna: kGoldSoft, child: isi);
  }
}

// ---------------------------------------------------------------- jadwal ringkas
class _JadwalRingkas extends StatelessWidget {
  final void Function(int) keTab;
  const _JadwalRingkas({required this.keTab});

  @override
  Widget build(BuildContext context) {
    final semua = Data.i.jadwal;
    final hari = hariIni();
    final hariIniList = semua.where((j) => parseTgl(j['tanggal']) == hari && j['kosong'] != true).toList();
    final berikut = semua
        .where((j) => (parseTgl(j['tanggal'])?.isAfter(hari) ?? false) && j['kosong'] != true)
        .take(3)
        .toList();
    if (hariIniList.isEmpty && berikut.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (hariIniList.isNotEmpty) ...[
        const JudulBagian('Jadwal hari ini'),
        for (final j in hariIniList) ItemJadwal(j: j, sorot: true),
      ],
      if (berikut.isNotEmpty) ...[
        const JudulBagian('Jadwal berikutnya'),
        for (final j in berikut) ItemJadwal(j: j),
      ],
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () => keTab(1),
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text('Lihat semua jadwal'),
        ),
      ),
    ]);
  }
}

// ---------------------------------------------------------------- slider foto
class _Slider extends StatefulWidget {
  final List<dynamic> item;
  const _Slider({required this.item});
  @override
  State<_Slider> createState() => _SliderState();
}

class _SliderState extends State<_Slider> {
  int _i = 0;
  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final foto = it.where((e) => e['tipe'] == 'image').map((e) => s(e['url'])).toList();
    final cur = it[_i < it.length ? _i : 0];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: PageView.builder(
            itemCount: it.length,
            onPageChanged: (i) => setState(() => _i = i),
            itemBuilder: (context, i) {
              final e = it[i];
              if (e['tipe'] == 'video') {
                return InkWell(
                  onTap: () => buka(s(e['url'])),
                  child: Container(
                    color: Colors.black,
                    child: const Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.play_circle_fill, color: Colors.white, size: 64),
                        SizedBox(height: 6),
                        Text('Putar video', style: TextStyle(color: Colors.white)),
                      ]),
                    ),
                  ),
                );
              }
              return GestureDetector(
                onTap: () => bukaViewer(context, foto, foto.indexOf(s(e['url'])), judul: 'Dokumentasi'),
                child: CachedNetworkImage(
                  imageUrl: s(e['url']),
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: const Color(0xFFEDE4D3)),
                  errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: kMuted)),
                ),
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(s(cur['judul']).isEmpty ? s(cur['keterangan']) : s(cur['judul']),
          style: const TextStyle(fontWeight: FontWeight.w700, color: kMaroon)),
      if (s(cur['judul']).isNotEmpty && s(cur['keterangan']).isNotEmpty)
        Text(s(cur['keterangan']), style: const TextStyle(fontSize: 13, color: kMuted)),
      Text('${_i + 1} / ${it.length} • geser untuk melihat lainnya', style: const TextStyle(fontSize: 11.5, color: kMuted)),
    ]);
  }
}

// ---------------------------------------------------------------- menu cepat
class _MenuCepat extends StatelessWidget {
  final void Function(int) keTab;
  const _MenuCepat({required this.keTab});

  @override
  Widget build(BuildContext context) {
    final d = Data.i;
    final menu = <(IconData, String, VoidCallback)>[
      (Icons.event_note, 'Jadwal', () => keTab(1)),
      (Icons.menu_book, 'Kitab', () => keTab(2)),
      (Icons.photo_library, 'Galeri', () => keTab(3)),
      (Icons.grid_view, 'Lainnya', () => keTab(4)),
      if (d.set('youtube_url').isNotEmpty) (Icons.smart_display, 'YouTube', () => buka(d.set('youtube_url'))),
      if (d.set('instagram_url').isNotEmpty) (Icons.camera_alt, 'Instagram', () => buka(d.set('instagram_url'))),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.25,
      children: [
        for (final m in menu)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: m.$3,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(m.$1, color: kMaroon, size: 28),
                const SizedBox(height: 6),
                Text(m.$2, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
          ),
      ],
    );
  }
}
