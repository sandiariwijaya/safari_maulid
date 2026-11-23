# Aplikasi Android Safari Maulid (versi online)

Aplikasi ini **membuka website https://safarimaulid.web.id secara langsung (online)**,
jadi semua isinya **selalu sama dengan website**: beranda, jadwal, kitab Rotib & Simtudduror
(termasuk gulir otomatis ▾ ▾▾ ▾▾▾ dan ketuk layar untuk mulai/berhenti), galeri, sejarah,
pengurus, legalitas, panduan, dan panel admin. Tidak perlu build ulang APK setiap kali isi
website diubah — cukup ubah lewat panel admin.

Fitur aplikasi:
- Tampilan layar penuh dengan warna status bar marun
- Tarik layar ke bawah untuk memuat ulang
- Tombol kembali HP = kembali ke halaman sebelumnya; tekan 2× di beranda untuk keluar
- Link YouTube, Instagram, WhatsApp, Google Maps & telepon dibuka di aplikasinya masing-masing
- Unduh foto / PDF lewat browser HP
- Upload foto & kamera di panel admin tetap berfungsi (izin kamera diminta saat dipakai)
- Layar "Tidak ada koneksi internet" + tombol Coba lagi saat offline

## Build APK lewat GitHub
1. Upload semua isi zip ini ke repository GitHub (timpa file lama).
   **Hapus file lama** `lib/api.dart`, `lib/util.dart`, dan folder `lib/pages/` (sudah tidak dipakai).
2. Tab **Actions** › **Build APK Safari Maulid** berjalan otomatis (±6–10 menit).
3. Setelah centang hijau, buka **Releases** (kanan halaman repo) › unduh `SafariMaulid-N.apk`.

Alamat website diatur di `lib/main.dart` (`kUrl`).

## Play Store
Langkah keystore sama seperti sebelumnya (workflow **Buat Keystore Play Store** › isi 4 Secrets).
Bahan Play Console ada di folder `playstore/`.
Catatan: Google Play kadang menolak aplikasi yang isinya hanya website. Aplikasi ini sudah
menambah fitur bawaan HP (tarik-muat-ulang, buka WA/Maps/telepon, kamera admin, layar offline),
tetapi keputusan akhir ada di Google.
