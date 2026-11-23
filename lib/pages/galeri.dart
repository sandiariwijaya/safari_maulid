import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../api.dart';
import '../util.dart';
import 'viewer.dart';

class HalamanGaleri extends StatelessWidget {
  const HalamanGaleri({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Galeri Foto')),
      body: Muat(
        child: ListenableBuilder(
          listenable: Data.i,
          builder: (context, _) {
            final d = Data.i;
            final foto = d.galeri;
            final semuaUrl = foto.map((f) => s(f['url'])).toList();
            final semuaKet = foto.map((f) => [s(f['keterangan']), tglId(f['tanggal_foto'], hari: true)].where((e) => e.isNotEmpty).join(' • ')).toList();
            final grup = <String, List<int>>{};
            for (var i = 0; i < foto.length; i++) {
              grup.putIfAbsent(s(foto[i]['tanggal_foto']), () => []).add(i);
            }
            final mulai = parseTgl(d.set('acara_mulai'));
            final selesai = parseTgl(d.set('acara_selesai'));

            if (foto.isEmpty) {
              return ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [
                SizedBox(height: 120),
                Icon(Icons.photo_library_outlined, size: 56, color: kMuted),
                SizedBox(height: 8),
                Center(child: Text('Belum ada foto', style: TextStyle(color: kMuted))),
              ]);
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                for (final e in grup.entries) ...[
                  SliverToBoxAdapter(child: _kepala(e.key, e.value.length, mulai, selesai)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 140,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, k) {
                          final idx = e.value[k];
                          final f = foto[idx];
                          return GestureDetector(
                            onTap: () => bukaViewer(context, semuaUrl, idx, judul: 'Galeri', keterangan: semuaKet),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: s(f['thumb_url']),
                                  fit: BoxFit.cover,
                                  memCacheWidth: 300,
                                  placeholder: (_, __) => Container(color: const Color(0xFFEDE4D3)),
                                  errorWidget: (_, __, ___) =>
                                      Container(color: const Color(0xFFEDE4D3), child: const Icon(Icons.broken_image, color: kMuted)),
                                ),
                              ),
                          );
                        },
                        childCount: e.value.length,
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _kepala(String tgl, int n, DateTime? mulai, DateTime? selesai) {
    final t = parseTgl(tgl);
    String? hariKe;
    if (t != null && mulai != null) {
      final m = DateTime(mulai.year, mulai.month, mulai.day);
      final ke = t.difference(m).inDays + 1;
      final batas = selesai == null ? null : DateTime(selesai.year, selesai.month, selesai.day);
      if (ke >= 1 && (batas == null || !t.isAfter(batas))) hariKe = 'Safari Maulid Hari ke-$ke';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (hariKe != null)
          Text(hariKe.toUpperCase(), style: const TextStyle(color: kGold, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1)),
        Row(children: [
          Expanded(
            child: Text(t == hariIni() ? 'Hari ini' : tglId(tgl, hari: true),
                style: const TextStyle(fontWeight: FontWeight.w800, color: kMaroon, fontSize: 15)),
          ),
          Text('$n foto', style: const TextStyle(color: kMuted, fontSize: 12.5)),
        ]),
      ]),
    );
  }
}
