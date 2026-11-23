# Aplikasi Android Safari Maulid

Aplikasi Android (Flutter) untuk **Safari Maulid Karesidenan Madiun**.
Semua isi diambil dari website `https://safarimaulid.web.id/api.php`, jadi apa pun yang
diubah di panel admin website otomatis ikut berubah di aplikasi (tarik layar ke bawah untuk memuat ulang).
Data terakhir disimpan di HP sehingga aplikasi tetap bisa dibuka saat tidak ada sinyal.

Menu: **Beranda** (hitung mundur / hari ke-, jadwal hari ini & berikutnya, foto dokumentasi),
**Jadwal** (peta, WhatsApp & telepon khodim), **Kitab** (Rotib Al-Haddad & Simtudduror, ukuran huruf,
terjemah, tombol hitung bacaan), **Galeri** (zoom & geser), **Lainnya** (Sejarah, Pengurus,
Legalitas, Panduan + PDF, YouTube, Instagram).

## Cara build APK lewat GitHub

1. Buat repository baru di GitHub (sebaiknya **Private**), misal `safari-maulid-apk`.
2. Upload **semua isi zip ini** ke repository (termasuk folder `.github`).
   Lewat browser: *Add file › Upload files* lalu seret semua file & folder.
   > Folder `.github` kadang tersembunyi di Windows/HP. Jika tidak ikut terupload, buat manual:
   > *Add file › Create new file*, ketik nama `.github/workflows/build-apk.yml`, lalu tempel isinya.
3. Buka tab **Actions** › workflow **Build APK Safari Maulid** berjalan otomatis setiap ada perubahan
   (bisa juga ditekan **Run workflow**). Tunggu ±6–10 menit.
4. Setelah centang hijau, klik build-nya › bagian **Artifacts** › unduh `SafariMaulid-build-N`
   (berisi file `.apk`). Ekstrak, lalu pasang APK di HP.

Tanpa keystore, APK sudah bisa dipasang dan dibagikan, tetapi **belum bisa diunggah ke Play Store**.

## Persiapan Play Store (sekali saja)

1. Tab **Actions** › **Buat Keystore Play Store** › **Run workflow**.
2. Setelah selesai, unduh artifact `keystore-safari-maulid-RAHASIA` › buka `SECRETS-KEYSTORE.txt`.
3. Repository › **Settings › Secrets and variables › Actions › New repository secret**, buat 4 secret:
   `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` (nilai dari file tadi).
4. **Simpan file keystore & teks tersebut di tempat aman** (Google Drive pribadi, dll).
   Hapus artifact-nya dari GitHub. Kunci ini dipakai untuk setiap update aplikasi.
5. Jalankan lagi **Build APK Safari Maulid**. Sekarang hasilnya juga berisi
   `SafariMaulid-N-playstore.aab` — file inilah yang diunggah ke Google Play Console.

Nomor versi (versionCode) otomatis naik mengikuti nomor build GitHub, jadi setiap update
bisa langsung diunggah ke Play Store. Nama versi diubah di `pubspec.yaml` (`version: 1.0.0+1`).

## Bahan Play Console (folder `playstore/`)

- `ikon-512.png` — ikon aplikasi 512×512
- `feature-graphic-1024x500.png` — gambar fitur
- `kebijakan-privasi.html` — upload ke website (mis. `safarimaulid.web.id/kebijakan-privasi.html`)
  lalu masukkan alamatnya di Play Console (wajib).
- Screenshot: ambil dari HP setelah aplikasi terpasang (minimal 2).

## Mengubah sesuatu

- Alamat website: `lib/api.dart` (`kBaseUrl`)
- Warna: `lib/util.dart`
- Nama aplikasi di HP: `tool/patch_android.py` (`NAMA_APP`)
- Ikon: ganti `assets/icon.png` (1024×1024) dan `assets/icon_fg.png` (logo transparan)
- ID aplikasi Play Store: `id.web.safarimaulid` (di workflow, `--org id.web --project-name safarimaulid`).
  **Jangan diubah setelah aplikasi terbit** di Play Store.
