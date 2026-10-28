# KasKita — Auth flow (Flutter + Node/Express + MySQL via Docker)

Hasil konversi desain Figma (section **login**, file KasKita) jadi kode.

## Struktur
```
kaskita/
├── docker-compose.yml        # MySQL 8 + API Node
├── .env.example              # copy jadi .env kalau mau ganti password/secret/SMTP
├── backend/                  # Express + mysql2 + JWT + bcrypt
│   ├── db/init.sql           # tabel users & otps (auto-jalan saat DB pertama dibuat)
│   └── src/index.js
└── flutter_app/
    ├── download_assets.sh    # download 10 aset dari Figma -> assets/images
    ├── pubspec.yaml
    └── lib/ (core, widgets, screens)
```

## 1. Jalankan backend (Docker)
```bash
docker compose up -d --build
docker compose logs -f api      # kode OTP muncul di sini kalau SMTP belum diisi
curl localhost:3000/health      # {"ok":true}
```
Reset total DB: `docker compose down -v`.

Endpoint (semua POST JSON, prefix `/auth`):
| Endpoint | Body | Keterangan |
|---|---|---|
| `/register` | name, email, password | buat akun + kirim OTP 4 digit |
| `/verify-otp` | email, code | verifikasi akun, balikin token |
| `/resend-otp` | email, purpose (`register`/`reset`) | kirim ulang kode |
| `/login` | email, password | balikin token (403 + `needsVerification` kalau belum verifikasi) |
| `/forgot-password` | email | kirim OTP reset |
| `/verify-reset-otp` | email, code | balikin `resetToken` (10 menit) |
| `/reset-password` | resetToken, newPassword | ganti password |

## 2. KasTarget API
Endpoint berikut membutuhkan header `Authorization: Bearer <token>`:

| Method & endpoint | Request | Keterangan |
|---|---|---|
| `GET /targets` | — | daftar target milik pengguna (`items`) |
| `POST /targets` | `name`, `targetAmount`, `deadline` (`YYYY-MM-DD`), `initialAmount` (opsional) | buat target; setoran awal mengurangi saldo KasKita |
| `GET /targets/:id` | — | detail target dan riwayat setoran/penarikan |
| `POST /targets/:id/deposits` | `amount`, `note` (opsional) | setoran dari saldo KasKita |
| `POST /targets/:id/withdrawals` | `amount`, `note` (opsional) | penarikan ke saldo KasKita |

Setoran dan penarikan dicatat sebagai mutasi target dan transaksi KasKita dalam satu transaksi database. Tabel KasTarget dibuat otomatis saat API dimulai.

## 3. Setup Flutter
```bash
# dari folder kaskita/
flutter create --org com.kaskita --project-name kaskita tmp_app
cp -r tmp_app/android tmp_app/ios tmp_app/web tmp_app/.metadata flutter_app/ 2>/dev/null
rm -rf tmp_app
cd flutter_app
bash download_assets.sh         # WAJIB: tarik aset gambar dari Figma
flutter pub get
flutter run
```
- Emulator Android otomatis pakai `http://10.0.2.2:3000`.
- HP fisik: `flutter run --dart-define=API_URL=http://IP_LAPTOP:3000`.
- Android release/HP fisik pakai HTTP biasa: tambahin `android:usesCleartextTraffic="true"` di `<application>` pada `android/app/src/main/AndroidManifest.xml` (dan permission `android.permission.INTERNET` kalau belum ada).

## Alur screen
Splash → Welcome → Login / Sign Up → Verifikasi OTP → Akun Berhasil → Login → Home (placeholder)
Login → Forgot Password → Verifikasi OTP → Kata Sandi Baru → Kata Sandi Diubah → Login
Tab KasTarget → daftar target → buat target / detail → tambah dana atau tarik dana

## Catatan
- Layout memakai kanvas 393×852 (frame iPhone 16 di Figma) yang di-scale mengikuti lebar layar, jadi posisi/ukuran sama dengan desain. Status bar palsu ("TSEL", wifi, baterai) tidak dikodekan karena itu milik sistem.
- Warna teks tombol sengaja ngikutin Figma (hitam di Login/Sign Up/Continue, putih di Kirim Kode/Welcome).
- Login saat ini hanya via email (kolom "Email or Phone Number" di desain), "Nomor HP?" dan login Google/Apple/Facebook belum ada backend-nya.
- Animasi phoenix di layar "Akun Berhasil" dipakai versi gambar statis dari Figma (belum Lottie).
