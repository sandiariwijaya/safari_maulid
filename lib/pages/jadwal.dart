import 'package:flutter/material.dart';

import '../api.dart';
import '../util.dart';

class HalamanJadwal extends StatefulWidget {
  const HalamanJadwal({super.key});
  @override
  State<HalamanJadwal> createState() => _HalamanJadwalState();
}

class _HalamanJadwalState extends State<HalamanJadwal> {
  bool _mendatang = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ListenableBuilder(
        listenable: Data.i,
        builder: (_, __) => Text(Data.i.set('jadwal_judul').isEmpty ? 'Jadwal' : Data.i.set('jadwal_judul')),
      )),
      body: Muat(
        child: ListenableBuilder(
          listenable: Data.i,
          builder: (context, _) {
            final d = Data.i;
            final hari = hariIni();
            var list = d.jadwal;
            if (_mendatang) {
              list = list.where((j) => !(parseTgl(j['tanggal'])?.isBefore(hari) ?? false)).toList();
            }
            // kelompokkan per bulan
            final grup = <String, List<dynamic>>{};
            for (final j in list) {
              final t = parseTgl(j['tanggal']);
              if (t == null) continue;
              grup.putIfAbsent(bulanTahun(t), () => []).add(j);
            }
            final catatan = d.set('jadwal_catatan');
            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              children: [
                Kartu(
                  warna: kGoldSoft,
                  child: Row(children: [
                    Column(children: [
                      Text('${d.jadwal.length}',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kMaroon)),
                      const Text('Titik Safari', style: TextStyle(fontSize: 11.5, color: kMuted)),
                    ]),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (d.jadwal.isNotEmpty)
                          Text(
                              '${tglId(d.jadwal.first['tanggal'], tahun: false)} s/d ${tglId(d.jadwal.last['tanggal'], tahun: false)}',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: kMaroon)),
                        Text(d.set('jadwal_label_tahun'), style: const TextStyle(fontSize: 12.5, color: kMuted)),
                      ]),
                    ),
                  ]),
                ),
                if (catatan.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF0DFA8)),
                    ),
                    child: Text('📌 $catatan', style: const TextStyle(fontSize: 13)),
                  ),
                Row(children: [
                  ChoiceChip(
                    label: const Text('Semua'),
                    selected: !_mendatang,
                    onSelected: (_) => setState(() => _mendatang = false),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Hari ini & mendatang'),
                    selected: _mendatang,
                    onSelected: (_) => setState(() => _mendatang = true),
                  ),
                ]),
                if (grup.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: Text('Belum ada jadwal.', style: TextStyle(color: kMuted))),
                  ),
                for (final e in grup.entries) ...[
                  JudulBagian('${e.key} • ${e.value.length} kegiatan'),
                  for (final j in e.value) ItemJadwal(j: j, sorot: parseTgl(j['tanggal']) == hari),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class ItemJadwal extends StatelessWidget {
  final dynamic j;
  final bool sorot;
  const ItemJadwal({super.key, required this.j, this.sorot = false});

  @override
  Widget build(BuildContext context) {
    final t = parseTgl(j['tanggal']);
    final lewat = t != null && t.isBefore(hariIni());
    final kosong = j['kosong'] == true;
    final khodim = s(j['khodim']);
    final hp = nomorHp(khodim);
    final tag = s(j['tag']);
    return Opacity(
      opacity: lewat && !sorot ? 0.6 : 1,
      child: Kartu(
        warna: sorot ? const Color(0xFFFFF4E5) : null,
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              width: 74,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              color: sorot ? kMaroon : const Color(0xFFF3E9D6),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(s(j['no']), style: TextStyle(fontSize: 11, color: sorot ? kGoldSoft : kMuted)),
                Text(t != null ? '${t.day}' : '',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: sorot ? Colors.white : kMaroon)),
                Text(s(j['tgl_pendek']).split(' ').last,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sorot ? Colors.white : kMaroon)),
                const SizedBox(height: 2),
                Text(s(j['hari']),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10.5, color: sorot ? kGoldSoft : kMuted)),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s(j['hijriah']), style: const TextStyle(fontSize: 11.5, color: kGold, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(kosong ? '—' : s(j['nama_tempat']),
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: kInk)),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    if (sorot) _lencana('HARI INI', Colors.green.shade700),
                    if (tag.isNotEmpty) _lencana(tag.toUpperCase(), kGold),
                    if (lewat && !sorot) _lencana('SELESAI', kMuted),
                  ]),
                  if (!kosong && s(j['alamat']).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(s(j['alamat']), style: const TextStyle(fontSize: 13, color: kMuted)),
                  ],
                  if (!kosong && khodim.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.person, size: 15, color: kMaroon2),
                      const SizedBox(width: 4),
                      Expanded(child: Text(khodim, style: const TextStyle(fontSize: 12.5, color: kMaroon2))),
                    ]),
                  ],
                  if (!kosong && (s(j['peta_url']).isNotEmpty || hp != null)) ...[
                    const SizedBox(height: 6),
                    Wrap(spacing: 8, children: [
                      if (s(j['peta_url']).isNotEmpty)
                        _tombol(Icons.map, 'Peta', () => buka(s(j['peta_url']))),
                      if (hp != null) _tombol(Icons.chat, 'WhatsApp', () => hubungiWa(hp)),
                      if (hp != null) _tombol(Icons.call, 'Telepon', () => telepon(hp)),
                    ]),
                  ],
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _lencana(String t, Color c) => Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8)),
        child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
      );

  Widget _tombol(IconData ic, String t, VoidCallback f) => OutlinedButton.icon(
        onPressed: f,
        icon: Icon(ic, size: 16),
        label: Text(t),
        style: OutlinedButton.styleFrom(
          foregroundColor: kMaroon,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          side: const BorderSide(color: Color(0xFFE0D2B5)),
        ),
      );
}
