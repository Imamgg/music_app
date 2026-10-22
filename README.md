# 🎵 Dokumentasi Teknis & Spesifikasi Fitur (TECH_SPEC.md)
**Nama Proyek:** AUNO  
**Platform:** Android & iOS (Cross-platform via Flutter)  
**Arsitektur:** Hybrid Metadata-Audio Streaming (Client-Side Extraction)

---

## 1. Gambaran Arsitektur Sistem (System Architecture)

Aplikasi ini memisahkan antara **Sumber Katalog (Metadata)** dan **Sumber Suara (Audio Stream)** agar memiliki antarmuka serapi Spotify namun dapat memutar musik secara gratis tanpa membebani server pribadi:

1. **Metadata Engine (Spotify Web API / Deezer API):** Mengambil daftar *Chart* terpopuler, sampul album resolusi tinggi, nama artis yang rapi, daftar lagu dalam album, dan rekomendasi genre.
2. **Audio Engine (`youtube_explode_dart`):** Saat pengguna menekan tombol *Play* pada lagu di katalog, aplikasi melakukan pencarian otomatis di latar belakang ke YouTube menggunakan pola `"Nama Artis - Judul Lagu Official Audio"`, mengekstrak URL *raw audio stream* (`m4a`/`opus`), lalu memutarnya.
3. **Lyrics Engine (LRCLIB API):** Mengambil lirik berwaktu (*time-synced lyrics* `.lrc`) berdasarkan judul lagu, nama artis, dan durasi lagu.
4. **Cloud Backend (Supabase):** Menangani autentikasi pengguna, sinkronisasi *playlist* kustom, lagu yang disukai (*Liked Songs*), dan riwayat pemutaran.

> **Catatan Penting Database:** URL *stream* audio dari YouTube memiliki masa kedaluwarsa (*expired* dalam 2–6 jam). Database **dilarang** menyimpan URL stream. Database hanya menyimpan `video_id` YouTube atau `spotify_track_id`. Ekstraksi URL *stream* selalu dilakukan secara *on-the-fly* (saat lagu hendak diputar) atau disimpan di penyimpanan lokal perangkat (mode *Offline*).

---

## 2. Tech Stack & Pustaka (Libraries)

### A. Core & State Management
* **Framework:** Flutter SDK (Dart)
* **State Management:** `flutter_riverpod` (atau `flutter_bloc`) — Mengelola *state* antrean lagu (*queue*), status pemutar, dan sinkronisasi data.
* **Routing:** `go_router` — Navigasi halaman dan dukungan *deep-linking* (berbagi link lagu/playlist).

### B. Audio & Media Playback
* **`just_audio`:** *Engine* utama pemutar audio (mendukung *gapless playback*, *crossfade*, dan *audio caching*).
* **`audio_service` / `just_audio_background`:** Menjalankan pemutar musik di *background service* (musik tetap jalan saat layar mati) serta menampilkan kontrol *lockscreen* & bar notifikasi Android/iOS.
* **`youtube_explode_dart`:** Mengekstrak *manifest* audio murni (tanpa video) dari YouTube secara langsung dari perangkat pengguna (*client-side*).

### C. Database, Caching & Penyimpanan Lokal
* **Cloud Backend:** `supabase_flutter` (PostgreSQL Database + Auth).
* **Local Database:** `isar` atau `hive_ce` — Menyimpan *cache* pencarian, pengaturan aplikasi, dan daftar lagu yang diunduh (*offline mode*).
* **Networking:** `dio` — HTTP client untuk mengambil metadata dari API eksternal dan mengunduh file audio ke penyimpanan lokal.

### D. UI / UX Pendukung
* **`palette_generator`:** Mengekstrak warna dominan dari gambar sampul album (*album art*) untuk membuat *background* gradasi dinamis seperti layar pemutar Spotify.
* **`cached_network_image`:** Menyimpan *cache* gambar sampul album agar hemat kuota dan tidak berkedip saat di-*scroll*.
* **`flutter_lyric`:** Menampilkan animasi lirik berjalan (*karaoke/synced style*) yang mengikuti detik lagu.

---

## 3. Daftar Fitur Lengkap (Feature Breakdown)

### Fase 1: Core MVP (Fungsi Dasar)
- [x] **Pencarian Pintar (Smart Search):** Mencari lagu, artis, atau album dengan pemisahan kategori.
- [x] **Audio-Only Streaming:** Memutar stream audio bitrate tertinggi (128kbps–160kbps Opus/AAC) tanpa mengunduh data video.
- [x] **Mini Player & Full-Screen Player:** Transisi *swipe-up* dari *mini player* di bawah layar menuju tampilan pemutar penuh.
- [x] **Background Playback & Media Notification:** Kontrol *Play, Pause, Next, Previous*, dan *Seek bar* langsung dari panel notifikasi HP dan layar kunci.

### Fase 2: Pengalaman Setara Spotify (Rich Features)
- [ ] **Manajemen Antrean (Queue System):** Tambah lagu ke antrean (*Add to Queue*), ubah urutan lagu dengan *drag-and-drop*, fitur *Shuffle* (acak), dan *Repeat* (Ulangi Semua / Ulangi Satu Lagu).
- [ ] **Lirik Berjalan (Time-Synced Lyrics):** Lirik otomatis bergulir mengikuti ketukan waktu lagu saat ini (diambil secara gratis dari `lrclib.net`).
- [ ] **Dynamic Color Theming:** Warna latar belakang halaman *Now Playing* berubah otomatis menyesuaikan warna sampul lagu yang sedang diputar.
- [ ] **Pre-fetching (Zero Buffer Transition):** Saat lagu A mencapai durasi 80%, aplikasi otomatis mengekstrak URL YouTube untuk lagu B di urutan berikutnya agar perpindahan lagu berlangsung instan tanpa jeda *loading*.

### Fase 3: Cloud Sync & Offline Mode
- [ ] **Autentikasi & Cloud Playlist (Supabase):** Buat *playlist* kustom, ubah sampul *playlist*, dan simpan daftar *Liked Songs* yang tersinkronisasi di akun pengguna.
- [ ] **Download Offline (Local Caching):** Mengunduh *stream* audio ke penyimpanan internal HP beserta sampul dan liriknya agar bisa diputar tanpa koneksi internet.
- [ ] **Import Playlist Spotify/YouTube:** Memasukkan link *playlist* publik dari Spotify atau YouTube untuk langsung disalin ke dalam aplikasi.

### Fase 4: Fitur Lanjutan (Advanced / Nice-to-Have)
- [ ] **Sleep Timer:** Matikan pemutar musik secara otomatis setelah waktu yang ditentukan (15 menit, 30 menit, atau akhir lagu).
- [ ] **Audio Quality Selector:** Pilihan kualitas audio (Hemat Data ~48kbps untuk jaringan lambat, atau Kualitas Tinggi ~160kbps untuk Wi-Fi).
- [ ] **Equalizer & Bass Booster:** Pengaturan frekuensi suara bawaan menggunakan *pipeline* `AndroidEqualizer` dari `just_audio`.
- [ ] **Statistik Mendengarkan (Wrapped Sederhana):** Menampilkan riwayat lagu dan artis yang paling sering diputar oleh pengguna setiap bulannya.

---

## 4. Struktur Folder Proyek (Clean Architecture)

```text
lib/
├── core/
│   ├── constants/         # API endpoints, warna tema, konfigurasi
│   ├── theme/             # Dark theme ala Spotify & Dynamic Palette
│   └── utils/             # Formatter durasi, pencocok string lagu
├── data/
│   ├── datasources/
│   │   ├── youtube_source.dart    # Wrapper youtube_explode_dart
│   │   ├── metadata_source.dart   # Koneksi ke Spotify/Deezer API
│   │   ├── lyrics_source.dart     # Koneksi ke LRCLIB API
│   │   └── supabase_source.dart   # Koneksi ke Supabase DB
│   ├── models/            # SongModel, PlaylistModel, LyricModel
│   └── repositories/      # Implementasi logika penggabungan data
├── domain/
│   ├── entities/          # Struktur objek murni
│   └── usecases/          # PlaySong, DownloadSong, SyncPlaylist
├── presentation/
│   ├── providers/         # State management (Riverpod providers)
│   ├── screens/
│   │   ├── home/          # Beranda, rekomendasi, chart
│   │   ├── search/        # Halaman pencarian & filter
│   │   ├── library/       # Koleksi playlist & lagu offline
│   │   └── player/        # Full-screen player, lirik, & antrean
│   └── widgets/           # MiniPlayer, SongTile, CustomSeekBar
└── main.dart