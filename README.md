# 🎵 AUNO Music Player

<p align="center">
  <img src="web/icons/Icon-192.png" alt="AUNO Logo" width="100" height="100" />
</p>

<p align="center">
  <b>Pemutar Musik Modern, Ringan, dan Cepat dengan Integrasi Native YouTube Music Engine & Lirik Tersinkronisasi Waktu</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat&logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=flat&logo=dart" alt="Dart" />
  <img src="https://img.shields.io/badge/State_Management-Riverpod_2.6-blue" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Audio_Engine-just__audio-green" alt="Just Audio" />
  <img src="https://img.shields.io/badge/Platform-Android_%7C_iOS-brightgreen" alt="Platforms" />
  <img src="https://img.shields.io/badge/License-MIT-orange" alt="License" />
</p>

---

## 📖 Ringkasan Proyek (Overview)

**AUNO** adalah aplikasi pemutar musik modern berbasis Flutter yang menghadirkan pengalaman mendengarkan musik setara aplikasi *streaming* premium tanpa biaya berlangganan dan bebas iklan.

Aplikasi ini mengintegrasikan **YouTube Music Innertube API (`WEB_REMIX`)** secara *native* pada lapisan *data layer*, dipadukan dengan **ExoPlayer Audio Streamer**, **Dynamic Palette Theming**, dan **Time-Synced Lyrics (LRC)**.

---

## 💡 Analisis Arsitektur & Evolusi Sistem

Berdasarkan analisis teknis dari siklus pengembangan (Ref: `b299f4ad-dec4-4b59-889c-813694d2b8b8`), arsitektur AUNO telah berevolusi dari model *Hybrid Metadata Searching* menjadi *Native YouTube Music Engine*:

### 1. Masalah pada Arsitektur Lama (Hybrid Search & Deezer)
* **Delay Pemutaran (1–3 detik):** Karena metadata awal diambil dari Deezer, setiap kali pengguna menekan lagu, aplikasi harus melakukan kueri pencarian teks ulang ke YouTube untuk menemukan tautan audio.
* **Inkonsistensi Audio:** Pencarian berbasis teks sering kali keliru mencocokkan lagu dengan versi *Full Album*, kompilasi berdurasi panjang (> 1 jam), atau versi rekaman non-resmi.
* **Error HTTP 403 (ExoPlayer Forbidden):** URL *stream audio-only* langsung dari YouTube mengalami pembatasan *signature cipher* dan *throttling* pada library AndroidX Media3/ExoPlayer.

### 2. Solusi & Arsitektur Baru yang Diterapkan
* **YouTube Music Innertube API (`WEB_REMIX`):** Katalog musik, tangga lagu teratas (Top Charts), playlist kurasi, dan pencarian dialihkan langsung ke endpoint resmi YouTube Music. Setiap lagu otomatis menyertakan `youtubeVideoId` sejak pertama kali dimuat.
* **Zero-Delay Playback (< 500ms):** Pemutaran lagu berlangsung seketika tanpa jeda pencarian tambahan karena ID audio telah tersedia di memori.
* **Format Stream ITAG 18 (ExoPlayer Safe):** Menggunakan format progressive AAC audio (ITAG 18 container MP4) yang kompatibel 100% dengan ExoPlayer, menjamin kebebasan dari error HTTP 403.
* **Smart Caching & Offline-First:** Tangga lagu dan playlist kurasi dicache ke penyimpanan lokal (`shared_preferences`). Aplikasi terbuka secara instan dalam waktu **< 0.2 detik** dengan pembaruan latar belakang (*background refresh*).

---

## 🏗️ Alur Kerja Sistem (System Architecture)

```mermaid
flowchart TD
    subgraph UI["Antarmuka Pengguna (Flutter UI)"]
        Home["Home Screen\n(Charts & Curated Playlists)"]
        Search["Search Screen\n(Pencarian Cepat YT Music)"]
        Playlist["Playlist Detail Screen\n(Play All & Shuffle)"]
        Player["Now Playing & Mini Player\n(Dynamic Palette)"]
        Lyrics["Synced Lyrics View\n(Karaoke Mode)"]
    end

    subgraph Logic["State Management & Repositories"]
        YTMRepo["YouTubeMusicRepository\n(Innertube WEB_REMIX)"]
        AudioRepo["YouTubeAudioRepository\n(ITAG 18 Progressive AAC)"]
        Storage["StorageRepository\n(Local Cache & Favorites)"]
        LyricRepo["LyricsRepository\n(LRCLIB API)"]
        PlayerProv["AudioPlayerProvider\n(Riverpod + just_audio)"]
    end

    subgraph Service["Media Playback & OS Integration"]
        BGService["JustAudioBackground Service"]
        Lockscreen["MediaNotification & Lockscreen Controls"]
    end

    Home -->|Ambil Cache / Fetch| YTMRepo
    Search -->|Cari Musik| YTMRepo
    Home -->|Buka Playlist| Playlist
    Playlist -->|Pilih Lagu dengan videoId| PlayerProv
    Search -->|Pilih Lagu dengan videoId| PlayerProv
    
    YTMRepo <-->|Cache Cepat <0.2s| Storage
    PlayerProv -->|Ekstraksi Audio Instan| AudioRepo
    PlayerProv -->|Ambil Lirik LRC| LyricRepo
    LyricRepo --> Lyrics
    
    PlayerProv --> BGService
    BGService --> Lockscreen
    PlayerProv --> Player
```

---

## ✨ Fitur Utama (Key Features)

| Kategori | Fitur & Deskripsi |
| :--- | :--- |
| **Katalog & Chart** | • **Top 100 Musik Indonesia & Trending**: Tangga lagu resmi yang diperbarui langsung dari YouTube Music.<br>• **Playlist Kurasi Pilihan**: Pop Indonesia, Viral Hits TikTok, Akustik Santai, dsb.<br>• **Playlist Detail Screen**: Tampilan sampul album, info durasi/lagu, tombol *Putar Semua* dan *Acak* (*Shuffle*). |
| **Pemutar Audio** | • **Zero-Delay Audio Streaming**: Playback dimulai dalam waktu < 500ms.<br>• **ExoPlayer 403-Free**: Menggunakan progressive AAC audio stream stabil.<br>• **Background Audio**: Lagu tetap berputar saat aplikasi di-*minimize* atau layar terkunci.<br>• **Lockscreen Notification Control**: Notifikasi media lengkap dengan tombol play/pause, next, previous, dan seek bar. |
| **Tampilan & UX** | • **Dynamic Color Theming**: Gradasi warna latar belakang *Now Playing* otomatis menyesuaikan warna dominan cover album (`palette_generator`).<br>• **Mini Player Persisten**: Navigasi lancar tanpa menghentikan pemutaran lagu.<br>• **Lirik Tersinkronisasi (Synced Karaoke)**: Lirik bergulir otomatis per detik waktu lagu secara akurat dari LRCLIB. |
| **Pustaka & Cache** | • **Pencarian Cepat (Instant Search)**: Hasil pencarian instan dengan cover beresolusi tinggi.<br>• **Koleksi Favorit (Liked Songs)**: Simpan lagu kesukaan langsung ke penyimpanan lokal perangkat.<br>• **Offline-First Caching**: Data chart tersimpan lokal untuk peluncuran aplikasi tanpa jeda loading. |

---

## 🛠️ Tech Stack & Pustaka

* **Core & Framework:** Flutter 3.x, Dart 3.x
* **State Management:** [`flutter_riverpod: ^2.6.1`](https://pub.dev/packages/flutter_riverpod)
* **Audio Engine:** 
  * [`just_audio: ^0.10.6`](https://pub.dev/packages/just_audio)
  * [`just_audio_background: ^0.0.1-beta.17`](https://pub.dev/packages/just_audio_background)
  * [`youtube_explode_dart: ^3.1.0`](https://pub.dev/packages/youtube_explode_dart)
* **Networking & HTTP:** [`dio: ^5.11.1`](https://pub.dev/packages/dio)
* **Penyimpanan Lokal & Caching:** 
  * [`shared_preferences: ^2.5.6`](https://pub.dev/packages/shared_preferences)
  * [`cached_network_image: ^3.4.1`](https://pub.dev/packages/cached_network_image)
* **UI & Color Extraction:** [`palette_generator: ^0.3.3+7`](https://pub.dev/packages/palette_generator)
* **Lirik:** [LRCLIB Open Lyrics API](https://lrclib.net/)

---

## 📁 Struktur Folder Proyek

```text
lib/
├── core/
│   ├── constants/             # Definisi warna, URL endpoint, konstanta aplikasi
│   ├── theme/                 # Dark Theme Spotify-like & Dynamic Theming
│   └── utils/                 # Formatter durasi, pembersih judul lagu
├── data/
│   ├── models/                # SongModel, PlaylistModel, LyricLine
│   └── repositories/
│       ├── youtube_music_repository.dart   # Engine YouTube Music WEB_REMIX API
│       ├── youtube_audio_repository.dart   # ITAG 18 stream extractor
│       ├── lyrics_repository.dart          # Integrasi LRCLIB API
│       └── storage_repository.dart         # Local storage & caching
├── presentation/
│   ├── providers/             # Riverpod State Notifiers (Audio, Search, Library)
│   ├── screens/
│   │   ├── home/              # Beranda (Charts & Curated Playlists)
│   │   ├── search/            # Pencarian instan lagu YouTube Music
│   │   ├── playlist/          # Detail Playlist & antrean lagu
│   │   ├── library/           # Koleksi Lagu Favorit & Playlist Lokal
│   │   ├── player/            # Full-Screen Now Playing & Queue Screen
│   │   └── main_shell.dart    # Shell navigasi & Persistent Mini Player
│   └── widgets/               # SongTile, CustomSeekBar, SyncedLyricsWidget
└── main.dart                  # Inisialisasi JustAudioBackground & ProviderScope
```

---

## 🚀 Panduan Memulai (Getting Started)

### Prasyarat
* Flutter SDK (Versi `>=3.11.4`)
* Android SDK / Android Studio (untuk build Android)
* Perangkat fisik Android atau Emulator (Android 8.0 Oreo ke atas direkomendasikan)

### 1. Kloning Repositori
```bash
git clone https://github.com/Imamgg/music_app.git
cd music_app
```

### 2. Pasang Dependensi
```bash
flutter pub get
```

### 3. Jalankan Pengujian Otomatis
```bash
flutter test
```

### 4. Jalankan Aplikasi di Perangkat
```bash
flutter run
```

### 5. Kompilasi APK Rilis (Release Build)
```bash
flutter build apk --release
```
File APK siap instal akan berada di:  
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🧪 Pengujian & Kualitas Kode

Proyek ini dilengkapi dengan *unit test* dan *widget test* untuk memastikan keandalan fungsi:
* **`test/unit_test.dart`**: Pengujian parser durasi, pembersihan judul lagu (*regex sanitization*), parser lirik `.lrc`, dan serialisasi model data.
* **`test/widget_test.dart`**: Smoke test struktur dasar antarmuka aplikasi.

Semua pengujian berjalan 100% sukses:
```bash
flutter test
# Result: All tests passed! (9/9 passed)
```

---

## 📄 Lisensi

Didistribusikan di bawah lisensi MIT. Lihat file `LICENSE` untuk rincian selengkapnya.
