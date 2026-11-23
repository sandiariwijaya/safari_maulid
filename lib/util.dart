import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';

const Color kMaroon = Color(0xFF6B1010);
const Color kMaroon2 = Color(0xFF8B2323);
const Color kGold = Color(0xFFC9A24A);
const Color kGoldSoft = Color(0xFFF6ECD2);
const Color kCream = Color(0xFFF6F2EA);
const Color kInk = Color(0xFF2B2118);
const Color kMuted = Color(0xFF8A7B6A);

String s(dynamic v) => v == null ? '' : v.toString();

/// Ubah potongan HTML sederhana menjadi teks biasa.
String bersihHtml(dynamic v) {
  var t = s(v);
  t = t.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  t = t.replaceAll(RegExp(r'</(p|div)>', caseSensitive: false), '\n\n');
  t = t.replaceAll(RegExp(r'<[^>]+>'), '');
  t = t
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&#039;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&middot;', '·')
      .replaceAll('&ndash;', '–')
      .replaceAll('&amp;', '&');
  t = t.replaceAll(RegExp(r'[ \t]+\n'), '\n').replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return t.trim();
}

/// Teks dengan **tebal** -> TextSpan
TextSpan teksKaya(String teks, TextStyle gaya) {
  final spans = <TextSpan>[];
  final re = RegExp(r'\*\*(.+?)\*\*', dotAll: true);
  var awal = 0;
  for (final m in re.allMatches(teks)) {
    if (m.start > awal) spans.add(TextSpan(text: teks.substring(awal, m.start)));
    spans.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w700)));
    awal = m.end;
  }
  if (awal < teks.length) spans.add(TextSpan(text: teks.substring(awal)));
  return TextSpan(style: gaya, children: spans);
}

const _bulan = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
const _bulanPendek = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Ahad'];

DateTime? parseTgl(dynamic v) {
  final t = s(v).trim();
  if (t.isEmpty) return null;
  return DateTime.tryParse(t.replaceFirst(' ', 'T'));
}

String tglId(dynamic v, {bool pendek = false, bool tahun = true, bool hari = false}) {
  final d = parseTgl(v);
  if (d == null) return s(v);
  final b = pendek ? _bulanPendek[d.month - 1] : _bulan[d.month - 1];
  return '${hari ? '${_hari[d.weekday - 1]}, ' : ''}${d.day} $b${tahun ? ' ${d.year}' : ''}';
}

String bulanTahun(DateTime d) => '${_bulan[d.month - 1]} ${d.year}';

DateTime hariIni() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

Future<void> buka(String url) async {
  if (url.trim().isEmpty) return;
  final u = Uri.tryParse(url.trim());
  if (u == null) return;
  await launchUrl(u, mode: LaunchMode.externalApplication);
}

/// Ambil nomor HP dari teks seperti "Ust. Fulan - 0812-3456-7890"
String? nomorHp(String teks) {
  final m = RegExp(r'(\+?62|0)8[\d\s\-.]{7,14}').firstMatch(teks);
  if (m == null) return null;
  return m.group(0)!.replaceAll(RegExp(r'[^\d+]'), '');
}

Future<void> hubungiWa(String nomor) async {
  var n = nomor.replaceAll(RegExp(r'[^\d]'), '');
  if (n.startsWith('0')) n = '62${n.substring(1)}';
  await buka('https://wa.me/$n');
}

Future<void> telepon(String nomor) async {
  await launchUrl(Uri(scheme: 'tel', path: nomor));
}

/// Pembungkus halaman: tarik ke bawah untuk memuat ulang + pesan offline.
class Muat extends StatelessWidget {
  final Widget child;
  const Muat({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Data.i,
      builder: (context, _) {
        final d = Data.i;
        if (d.kosong) {
          return RefreshIndicator(
            onRefresh: d.segarkan,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(
                  child: d.memuat
                      ? const CircularProgressIndicator(color: kMaroon)
                      : Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(children: [
                            const Icon(Icons.wifi_off, size: 48, color: kMuted),
                            const SizedBox(height: 12),
                            Text(d.error ?? 'Memuat data…', textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            FilledButton(onPressed: d.segarkan, child: const Text('Coba lagi')),
                          ]),
                        ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(color: kMaroon, onRefresh: d.segarkan, child: child);
      },
    );
  }
}

class JudulBagian extends StatelessWidget {
  final String teks;
  const JudulBagian(this.teks, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Row(children: [
        Text(teks.toUpperCase(),
            style: const TextStyle(color: kGold, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 13)),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: Color(0xFFE8DFCF))),
      ]),
    );
  }
}

class Kartu extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? warna;
  final VoidCallback? onTap;
  const Kartu({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.warna, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(
      color: warna ?? Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE8DFCF))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}
