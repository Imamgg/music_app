import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppStrings {
  const AppStrings(this.locale);
  final Locale locale;
  static const delegate = _AppStringsDelegate();
  static const supportedLocales = [
    Locale('id'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ];
  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ??
      const AppStrings(Locale('id'));
  String tr(String value) {
    final index = ['en', 'ja', 'ko'].indexOf(locale.languageCode);
    if (index < 0) return value;
    final exact = translations[value];
    if (exact != null) return exact[index];
    final count = RegExp(r'^(\d+) lagu$').firstMatch(value);
    if (count != null) {
      return ['${count[1]} songs', '${count[1]}曲', '${count[1]}곡'][index];
    }
    for (final prefix in [
      'Timer aktif: ',
      'Sisa waktu: ',
      'Ukuran saat ini: ',
    ]) {
      if (value.startsWith(prefix)) {
        final labels = {
          'Timer aktif: ': ['Timer active: ', 'タイマー: ', '타이머: '],
          'Sisa waktu: ': ['Remaining: ', '残り: ', '남은 시간: '],
          'Ukuran saat ini: ': ['Current size: ', '現在のサイズ: ', '현재 크기: '],
        };
        return '${labels[prefix]![index]}${tr(value.substring(prefix.length))}';
      }
    }
    final minutes = RegExp(r'^Timer diatur: (\d+) menit$').firstMatch(value);
    if (minutes != null) {
      return [
        'Timer set: ${minutes[1]} minutes',
        'タイマー: ${minutes[1]}分',
        '타이머 설정: ${minutes[1]}분',
      ][index];
    }
    if (value.startsWith('Cache: ')) {
      return value.replaceAll('Riwayat pencarian', tr('Riwayat pencarian'));
    }
    if (value.startsWith('Versi ')) {
      return value.replaceFirst('Versi ', ['Version ', 'バージョン ', '버전 '][index]);
    }
    final prefixes = {
      'Ditambahkan ke antrean: ': ['Added to queue: ', 'キューに追加: ', '대기열에 추가: '],
      'Gunakan saran ': ['Use suggestion ', '検索候補を使用: ', '제안 사용: '],
      'Gagal memuat musik: ': [
        'Could not load music: ',
        '音楽を読み込めません: ',
        '음악을 불러올 수 없습니다: ',
      ],
      'Gagal memuat lagu playlist: ': [
        'Could not load playlist: ',
        'プレイリストを読み込めません: ',
        '재생목록을 불러올 수 없습니다: ',
      ],
      'Kendala pemutaran: ': ['Playback error: ', '再生エラー: ', '재생 오류: '],
      'Terjadi kendala saat memutar lagu: ': [
        'Playback error: ',
        '再生エラー: ',
        '재생 오류: ',
      ],
      'Tidak ada hasil untuk ': ['No results for ', '検索結果なし: ', '검색 결과 없음: '],
    };
    for (final entry in prefixes.entries) {
      if (value.startsWith(entry.key)) {
        return '${entry.value[index]}${value.substring(entry.key.length)}';
      }
    }
    return value;
  }

  static const Map<String, List<String>> translations = {
    "Musik untuk setiap suasana": [
      "Music for every mood",
      "気分に合う音楽",
      "모든 기분에 맞는 음악",
    ],
    "Pilihan cepat": ["Quick picks", "クイック選曲", "빠른 선곡"],
    "Putar lagi": ["Listen again", "もう一度聴く", "다시 듣기"],
    "Trending Indonesia": ["Trending in Indonesia", "インドネシアのトレンド", "인도네시아 인기곡"],
    "Artis yang kamu ikuti": [
      "Artists you follow",
      "フォロー中のアーティスト",
      "팔로우한 아티스트",
    ],
    "Playlist pilihan": ["Featured playlists", "おすすめプレイリスト", "추천 재생목록"],
    "Menyiapkan pilihan musik…": [
      "Preparing your music…",
      "音楽を準備中…",
      "음악 준비 중…",
    ],
    "Musik belum dapat dimuat. Coba lagi.": [
      "Unable to load music. Please retry.",
      "音楽を読み込めません。再試行してください。",
      "음악을 불러올 수 없습니다. 다시 시도하세요.",
    ],
    "Belum ada lagu untuk suasana ini.": [
      "No songs found for this mood yet.",
      "この気分に合う曲はまだありません。",
      "이 기분에 맞는 곡이 아직 없습니다.",
    ],
    "Lihat semua": ["See all", "すべて表示", "모두 보기"],
    "Santai": ["Relax", "リラックス", "휴식"],
    "Fokus": ["Focus", "集中", "집중"],
    "Sedih": ["Feeling blue", "切ない気分", "슬픔"],
    "Perjalanan": ["On the road", "ドライブ", "여행"],
    "Olahraga": ["Workout", "ワークアウト", "운동"],
    "Tidur": ["Sleep", "睡眠", "수면"],
    "Menyiapkan lirik…": ["Preparing lyrics…", "歌詞を読み込み中…", "가사 준비 중…"],
    "Instrumental": ["Instrumental", "間奏", "간주"],
    "Gagal berpindah ke baris lirik.": [
      "Unable to jump to this lyric.",
      "この歌詞に移動できませんでした。",
      "이 가사로 이동할 수 없습니다.",
    ],
    "Ketuk baris untuk melompat": [
      "Tap a line to jump",
      "行をタップして移動",
      "가사를 눌러 이동",
    ],
    "Lirik tanpa sinkronisasi waktu": [
      "Lyrics without timing",
      "タイミング情報のない歌詞",
      "시간 정보가 없는 가사",
    ],
    "Lirik layar penuh": ["Fullscreen lyrics", "歌詞を全画面表示", "전체 화면 가사"],
    "Kembali ke lirik aktif": [
      "Back to current line",
      "現在の歌詞に戻る",
      "현재 가사로 돌아가기",
    ],
    "Artis yang diikuti": ["Followed artists", "フォロー中のアーティスト", "팔로우한 아티스트"],
    "Nama A–Z": ["Name A–Z", "名前順", "이름순"],
    "Terbaru ditambahkan": ["Recently added", "追加した順", "최근 추가순"],
    "Cari artis": ["Search artists", "アーティストを検索", "아티스트 검색"],
    "Artis yang Anda ikuti akan muncul di sini.": [
      "Artists you follow will appear here.",
      "フォローしたアーティストがここに表示されます。",
      "팔로우한 아티스트가 여기에 표시됩니다.",
    ],
    "Artis tidak ditemukan.": [
      "No artists found.",
      "アーティストが見つかりません。",
      "아티스트를 찾을 수 없습니다.",
    ],
    "Artis tersimpan": ["Saved artist", "保存済みアーティスト", "저장된 아티스트"],
    "Opsi artis": ["Artist options", "アーティストのオプション", "아티스트 옵션"],
    "Berhenti mengikuti": ["Unfollow", "フォローを解除", "팔로우 취소"],
    "Semua": ["All", "すべて", "전체"],
    "Playlist": ["Playlists", "プレイリスト", "재생목록"],
    "Unduhan": ["Downloads", "ダウンロード", "다운로드"],
    "Musik tanpa internet": [
      "Music without internet",
      "オフラインで音楽を楽しむ",
      "인터넷 없이 음악 듣기",
    ],
    "Unduh lagu melalui menu lagu. Biarkan aplikasi terbuka sampai unduhan selesai.": [
      "Download from the song menu. Keep the app open until downloads finish.",
      "曲のメニューからダウンロードできます。完了までアプリを開いたままにしてください。",
      "곡 메뉴에서 다운로드하세요. 완료될 때까지 앱을 열어 두세요.",
    ],
    "Mengunduh lagu": ["Downloading song", "曲をダウンロード中", "곡 다운로드 중"],
    "Tersedia offline": ["Available offline", "オフラインで利用可能", "오프라인 사용 가능"],
    "Unduh untuk offline": [
      "Download for offline",
      "オフライン用にダウンロード",
      "오프라인용 다운로드",
    ],
    "Batalkan unduhan": ["Cancel download", "ダウンロードをキャンセル", "다운로드 취소"],
    "Hapus unduhan": ["Remove download", "ダウンロードを削除", "다운로드 삭제"],
    "Hapus unduhan?": ["Remove download?", "ダウンロードを削除しますか？", "다운로드를 삭제할까요?"],
    "Unduhan gagal. Periksa koneksi dan ruang penyimpanan, lalu coba lagi.": [
      "Download failed. Check your connection and storage, then retry.",
      "ダウンロードに失敗しました。接続と空き容量を確認して再試行してください。",
      "다운로드 실패. 연결과 저장 공간을 확인한 후 다시 시도하세요.",
    ],
    "Unduhan belum dapat dihapus. Coba lagi setelah lagu berhenti.": [
      "Unable to remove download. Retry after playback stops.",
      "削除できません。再生停止後に再試行してください。",
      "삭제할 수 없습니다. 재생을 중지한 후 다시 시도하세요.",
    ],
    "Equalizer": ["Equalizer", "イコライザー", "이퀄라이저"],
    "Aktifkan equalizer": ["Enable equalizer", "イコライザーを有効にする", "이퀄라이저 켜기"],
    "Pengaturan suara berlaku untuk semua lagu.": [
      "Sound settings apply to all songs.",
      "音質設定はすべての曲に適用されます。",
      "사운드 설정은 모든 곡에 적용됩니다.",
    ],
    "Equalizer tersedia di Android.": [
      "Equalizer is available on Android.",
      "イコライザーはAndroidで利用できます。",
      "이퀄라이저는 Android에서 사용할 수 있습니다.",
    ],
    "Efek audio tidak tersedia pada perangkat ini.": [
      "Audio effects are unavailable on this device.",
      "この端末では音響効果を利用できません。",
      "이 기기에서는 오디오 효과를 사용할 수 없습니다.",
    ],
    "Putar lagu untuk mengaktifkan equalizer.": [
      "Play a song to activate the equalizer.",
      "曲を再生するとイコライザーが利用できます。",
      "곡을 재생하면 이퀄라이저를 사용할 수 있습니다.",
    ],
    "Karakter suara": ["Sound profile", "サウンド設定", "사운드 프로필"],
    "Normal": ["Normal", "標準", "기본"],
    "Bass Boost": ["Bass Boost", "低音強調", "저음 강조"],
    "Vokal": ["Vocals", "ボーカル", "보컬"],
    "Manual": ["Manual", "手動", "수동"],
    "Bass booster": ["Bass booster", "低音ブースター", "베이스 부스터"],
    "Bass booster tidak tersedia pada sesi audio ini.": [
      "Bass booster is unavailable for this audio session.",
      "このオーディオセッションでは低音ブースターを利用できません。",
      "이 오디오 세션에서는 베이스 부스터를 사용할 수 없습니다.",
    ],
    "Reset suara": ["Reset sound", "音質設定をリセット", "사운드 초기화"],
    "Sesuaikan karakter suara dan bass.": [
      "Adjust your sound profile and bass.",
      "音質と低音を調整します。",
      "사운드와 저음을 조절하세요.",
    ],
    'Dibuat oleh': ['Created by', '制作', '제작'],
    'Pengembang AUNO': ['AUNO developer', 'AUNO開発者', 'AUNO 개발자'],
    'Dibangun dengan perhatian pada setiap pengalaman mendengarkan.': [
      'Crafted with care for every listening experience.',
      '一つひとつのリスニング体験を大切に。',
      '모든 감상 경험을 세심하게 만듭니다.',
    ],
    'Terhubung dengan pengembang': [
      'Connect with the developer',
      '開発者とつながる',
      '개발자와 연결',
    ],
    'Profil belum dapat dibuka. Silakan coba lagi.': [
      'Could not open the profile. Please try again.',
      'プロフィールを開けません。もう一度お試しください。',
      '프로필을 열 수 없습니다. 다시 시도하세요.',
    ],
    'Lagu belum dapat dimuat. Periksa koneksi dan coba lagi.': [
      'Unable to load songs. Check your connection and retry.',
      '曲を読み込めません。接続を確認して再試行してください。',
      '곡을 불러올 수 없습니다. 연결을 확인하고 다시 시도하세요.',
    ],
    'Tidak ada lagu dalam playlist ini': [
      'This playlist has no tracks',
      'このプレイリストに曲はありません',
      '재생목록에 곡이 없습니다',
    ],
    "Beranda": ["Home", "ホーム", "홈"],
    "Cari": ["Search", "検索", "검색"],
    "Koleksi Kamu": ["Your library", "ライブラリ", "내 보관함"],
    "Pengaturan": ["Settings", "設定", "설정"],
    "Tampilan": ["Appearance", "表示", "화면"],
    "Tampilan aplikasi": ["App appearance", "アプリの表示", "앱 화면"],
    "Tema dinamis, ukuran teks & auto-scroll lirik": [
      "Dynamic theme, text size & lyrics scrolling",
      "動的テーマ、文字サイズ、歌詞の自動スクロール",
      "동적 테마, 글자 크기 및 가사 자동 스크롤",
    ],
    "Pemutar & konten": ["Player & content", "再生とコンテンツ", "플레이어 및 콘텐츠"],
    "Pemutar & audio": ["Player & audio", "プレーヤーと音声", "플레이어 및 오디오"],
    "Kualitas streaming audio & waktu tidur": [
      "Streaming quality & sleep timer",
      "音質とスリープタイマー",
      "스트리밍 음질 및 취침 타이머",
    ],
    "Bahasa aplikasi": ["App language", "アプリの言語", "앱 언어"],
    "Penyimpanan & data": ["Storage & data", "ストレージとデータ", "저장 공간 및 데이터"],
    "Penyimpanan": ["Storage", "ストレージ", "저장 공간"],
    "Informasi aplikasi": ["App information", "アプリ情報", "앱 정보"],
    "Tentang AUNO": ["About AUNO", "AUNOについて", "AUNO 정보"],
    "Tema & warna": ["Theme & colors", "テーマと色", "테마 및 색상"],
    "Warna latar dinamis": ["Dynamic background", "動的な背景", "동적 배경"],
    "Aurora mengikuti warna sampul album yang diputar.": [
      "Aurora follows the current album artwork colors.",
      "オーロラが再生中のアルバムの色に合わせて変化します。",
      "오로라가 재생 중인 앨범 표지 색상에 맞춰 변합니다.",
    ],
    "Lirik lagu": ["Lyrics", "歌詞", "가사"],
    "Lirik Lagu": ["Lyrics", "歌詞", "가사"],
    "Ukuran teks lirik": ["Lyrics text size", "歌詞の文字サイズ", "가사 글자 크기"],
    "Gulir otomatis lirik": ["Auto-scroll lyrics", "歌詞の自動スクロール", "가사 자동 스크롤"],
    "Ikuti baris lirik yang sedang dinyanyikan.": [
      "Follow the lyrics as the song plays.",
      "再生に合わせて歌詞を追います。",
      "재생 중인 가사를 따라갑니다.",
    ],
    "Kecil": ["Small", "小", "작게"],
    "Sedang": ["Medium", "中", "보통"],
    "Besar": ["Large", "大", "크게"],
    "Ikuti Sistem": ["Follow system", "システムに従う", "시스템 설정 사용"],
    "Gunakan bahasa perangkat": ["Use device language", "端末の言語を使用", "기기 언어 사용"],
    "Bahasa antarmuka aplikasi": [
      "App interface language",
      "アプリの表示言語",
      "앱 표시 언어",
    ],
    "Personalisasi": ["Personalization", "カスタマイズ", "개인 설정"],
    "Preferensi bahasa": ["Language preference", "言語設定", "언어 설정"],
    "Mengubah bahasa menu dan tombol aplikasi. Musik, rekomendasi, serta lirik asli tetap sama.": [
      "Change the language of menus and buttons. Music, recommendations and original lyrics stay the same.",
      "メニューとボタンの言語を変更します。音楽、おすすめ、歌詞の原文は変わりません。",
      "메뉴와 버튼의 언어를 변경합니다. 음악, 추천 및 원문 가사는 그대로 유지됩니다.",
    ],
    "Kualitas audio": ["Audio quality", "音質", "음질"],
    "Kualitas audio streaming": [
      "Streaming audio quality",
      "ストリーミング音質",
      "스트리밍 음질",
    ],
    "Tinggi (192-256 kbps)": [
      "High (192–256 kbps)",
      "高音質 (192–256 kbps)",
      "높음 (192–256 kbps)",
    ],
    "Standar (128 kbps)": [
      "Standard (128 kbps)",
      "標準 (128 kbps)",
      "표준 (128 kbps)",
    ],
    "Hemat Kuota (64 kbps)": [
      "Data saver (64 kbps)",
      "データ節約 (64 kbps)",
      "데이터 절약 (64 kbps)",
    ],
    "Kualitas audio terbaik, cocok untuk Wi-Fi": [
      "Best available quality, ideal for Wi-Fi",
      "最高音質、Wi-Fi向け",
      "최고 음질, Wi-Fi에 적합",
    ],
    "Seimbang antara kualitas dan kuota (Rekomendasi)": [
      "Balance quality and data use (recommended)",
      "音質とデータ使用量のバランス（推奨）",
      "음질과 데이터 사용량의 균형 (권장)",
    ],
    "Irit kuota data & loading tercepat": [
      "Lower data use and faster loading",
      "データ使用量を抑えて素早く読み込み",
      "데이터 절약 및 빠른 로딩",
    ],
    "Waktu & istirahat": ["Time & rest", "タイマーと休息", "시간 및 휴식"],
    "Pengatur waktu tidur": ["Sleep timer", "スリープタイマー", "취침 타이머"],
    "Pengatur Waktu Tidur": ["Sleep timer", "スリープタイマー", "취침 타이머"],
    "Hentikan musik secara otomatis saat Anda tertidur.": [
      "Automatically stop music while you sleep.",
      "就寝時に音楽を自動停止します。",
      "잠들면 음악을 자동으로 멈춥니다.",
    ],
    "Tentang pemutaran": ["About playback", "再生について", "재생 정보"],
    "Dengarkan dengan nyaman": ["Listen comfortably", "快適なリスニング", "편안하게 감상하세요"],
    "Perubahan kualitas berlaku mulai lagu berikutnya. Bitrate menyesuaikan stream yang tersedia dari sumber lagu.": [
      "Quality changes apply from the next track. Bitrate depends on available streams.",
      "音質の変更は次の曲から適用されます。ビットレートは配信元によって異なります。",
      "음질 변경은 다음 곡부터 적용됩니다. 비트레이트는 제공되는 스트림에 따라 달라집니다.",
    ],
    "Musik akan berhenti otomatis saat timer habis.": [
      "Music stops automatically when the timer ends.",
      "タイマー終了時に音楽が自動停止します。",
      "타이머가 끝나면 음악이 자동으로 멈춥니다.",
    ],
    "Timer Sedang Aktif": ["Timer active", "タイマー作動中", "타이머 작동 중"],
    "Waktu tidur dibatalkan": [
      "Sleep timer cancelled",
      "スリープタイマーを解除しました",
      "취침 타이머가 취소되었습니다",
    ],
    "Batalkan": ["Cancel", "キャンセル", "취소"],
    "15 Menit": ["15 minutes", "15分", "15분"],
    "30 Menit": ["30 minutes", "30分", "30분"],
    "45 Menit": ["45 minutes", "45分", "45분"],
    "1 Jam (60 Menit)": ["1 hour (60 minutes)", "1時間（60分）", "1시간 (60분)"],
    "Di akhir lagu saat ini": [
      "At the end of this track",
      "この曲の終了時",
      "현재 곡이 끝날 때",
    ],
    "Di akhir lagu ini": ["At the end of this track", "この曲の終了時", "현재 곡이 끝날 때"],
    "Musik akan berhenti di akhir lagu ini": [
      "Music will stop at the end of this track",
      "この曲の終了時に音楽を停止します",
      "현재 곡이 끝나면 음악이 멈춥니다",
    ],
    "Nonaktif": ["Off", "オフ", "꺼짐"],
    "Batal": ["Cancel", "キャンセル", "취소"],
    "Tutup": ["Close", "閉じる", "닫기"],
    "Simpan": ["Save", "保存", "저장"],
    "Hapus": ["Delete", "削除", "삭제"],
    "Bersihkan": ["Clear", "消去", "지우기"],
    "Memori & cache": ["Memory & cache", "メモリとキャッシュ", "메모리 및 캐시"],
    "Cache aplikasi": ["App cache", "アプリのキャッシュ", "앱 캐시"],
    "Riwayat pencarian": ["Search history", "検索履歴", "검색 기록"],
    "Riwayat kata kunci": ["Search terms", "検索キーワード", "검색어 기록"],
    "Bersihkan pencarian lagu sebelumnya.": [
      "Clear previous music searches.",
      "過去の音楽検索を消去します。",
      "이전 음악 검색 기록을 지웁니다.",
    ],
    "Hapus cache aplikasi?": [
      "Clear app cache?",
      "キャッシュを消去しますか？",
      "앱 캐시를 지울까요?",
    ],
    "Hapus riwayat pencarian?": [
      "Clear search history?",
      "検索履歴を消去しますか？",
      "검색 기록을 지울까요?",
    ],
    "File sementara dan gambar sampul yang tersimpan akan dibersihkan. Playlist dan lagu favorit tetap aman.": [
      "Cached files and artwork will be cleared. Playlists and favorites are kept.",
      "一時ファイルと画像を消去します。プレイリストとお気に入りは保持されます。",
      "임시 파일과 표지 캐시를 지웁니다. 재생목록과 좋아요는 유지됩니다.",
    ],
    "Semua kata kunci pencarian yang tersimpan akan dihapus.": [
      "All saved search terms will be removed.",
      "保存された検索キーワードをすべて削除します。",
      "저장된 검색어가 모두 삭제됩니다.",
    ],
    "Hapus cache": ["Clear cache", "キャッシュを消去", "캐시 지우기"],
    "Hapus riwayat": ["Clear history", "履歴を消去", "기록 지우기"],
    "Data belum dapat dibersihkan. Silakan coba lagi.": [
      "Unable to clear data. Please try again.",
      "データを消去できません。もう一度お試しください。",
      "데이터를 지울 수 없습니다. 다시 시도하세요.",
    ],
    "Cache aplikasi dibersihkan": [
      "App cache cleared",
      "キャッシュを消去しました",
      "앱 캐시가 지워졌습니다",
    ],
    "Riwayat pencarian dihapus": [
      "Search history cleared",
      "検索履歴を消去しました",
      "검색 기록이 지워졌습니다",
    ],
    "Bersihkan file sementara untuk menghemat ruang. Koleksi lagu dan playlist Anda tetap tersimpan.": [
      "Clear temporary files to free space. Your library and playlists are kept.",
      "一時ファイルを消去して容量を確保します。ライブラリとプレイリストは保持されます。",
      "임시 파일을 지워 공간을 확보합니다. 보관함과 재생목록은 유지됩니다.",
    ],
    "Ruang untuk musik favorit Anda": [
      "A space for your favorite music",
      "お気に入りの音楽のための空間",
      "좋아하는 음악을 위한 공간",
    ],
    "Pengalaman mendengarkan": ["Listening experience", "リスニング体験", "감상 경험"],
    "Cahaya dan warna mengikuti musik, dipadukan dengan permukaan kaca yang lembut.":
        [
          "Light and color follow your music, with soft glass surfaces.",
          "音楽に合わせて光と色が変化する、柔らかなガラスのデザイン。",
          "음악을 따라 변하는 빛과 색상, 부드러운 유리 디자인.",
        ],
    "Musik menemani aktivitas Anda": [
      "Music throughout your day",
      "毎日に寄り添う音楽",
      "일상과 함께하는 음악",
    ],
    "Kontrol pemutaran melalui notifikasi dan layar kunci yang didukung perangkat.":
        [
          "Control playback from supported notifications and lock screens.",
          "対応端末の通知やロック画面から再生を操作できます。",
          "지원되는 알림 및 잠금 화면에서 재생을 제어하세요.",
        ],
    "Lisensi": ["Licenses", "ライセンス", "라이선스"],
    "Lisensi sumber terbuka": [
      "Open source licenses",
      "オープンソースライセンス",
      "오픈 소스 라이선스",
    ],
    "Lihat lisensi pustaka yang digunakan AUNO.": [
      "View licenses for libraries used by AUNO.",
      "AUNOで使用するライブラリのライセンスを表示します。",
      "AUNO에서 사용하는 라이브러리의 라이선스를 확인하세요.",
    ],
    "Selamat pagi": ["Good morning", "おはようございます", "좋은 아침이에요"],
    "Selamat siang": ["Good afternoon", "こんにちは", "좋은 오후예요"],
    "Selamat sore": ["Good afternoon", "こんにちは", "좋은 오후예요"],
    "Selamat malam": ["Good evening", "こんばんは", "좋은 저녁이에요"],
    "Coba Lagi": ["Try again", "再試行", "다시 시도"],
    "Coba lagi": ["Try again", "再試行", "다시 시도"],
    "Playlist Pilihan YouTube Music": [
      "YouTube Music playlists",
      "YouTube Musicのプレイリスト",
      "YouTube Music 재생목록",
    ],
    "Tangga Lagu Terpopuler": ["Popular charts", "人気チャート", "인기 차트"],
    "Musik pilihan untukmu": ["Music for you", "あなたへの音楽", "나를 위한 음악"],
    "Buat Playlist Baru": ["Create playlist", "プレイリストを作成", "재생목록 만들기"],
    "Nama Playlist": ["Playlist name", "プレイリスト名", "재생목록 이름"],
    "Nama playlist": ["Playlist name", "プレイリスト名", "재생목록 이름"],
    "Deskripsi (opsional)": ["Description (optional)", "説明（任意）", "설명 (선택사항)"],
    "Lagu yang Disukai": ["Liked songs", "お気に入りの曲", "좋아요 표시한 곡"],
    "Playlist Saya": ["My playlists", "マイプレイリスト", "내 재생목록"],
    "Belum ada lagu yang disukai": [
      "No liked songs yet",
      "お気に入りの曲はまだありません",
      "아직 좋아요 표시한 곡이 없습니다",
    ],
    "Tekan tombol hati pada lagu apa pun untuk menyimpannya di sini": [
      "Tap a song’s heart button to save it here",
      "曲のハートを押すとここに保存されます",
      "곡의 하트 버튼을 눌러 여기에 저장하세요",
    ],
    "Playlist ini masih kosong": [
      "This playlist is empty",
      "このプレイリストは空です",
      "재생목록이 비어 있습니다",
    ],
    "Tambahkan lagu dari menu opsi pada lagu": [
      "Add songs from the song options menu",
      "曲のオプションから追加してください",
      "곡 옵션 메뉴에서 노래를 추가하세요",
    ],
    "Tidak ada lagu yang sedang diputar": [
      "Nothing is playing",
      "再生中の曲はありません",
      "재생 중인 곡이 없습니다",
    ],
    "MEMUTAR DARI ALBUM": ["PLAYING FROM ALBUM", "アルバムから再生", "앨범에서 재생 중"],
    "MEMUTAR DARI ARTIS": ["PLAYING FROM ARTIST", "アーティストから再生", "아티스트에서 재생 중"],
    "Antrean Musik": ["Play queue", "再生キュー", "재생 대기열"],
    "Opsi lagu": ["Song options", "曲のオプション", "곡 옵션"],
    "Tampilkan Sampul": ["Show artwork", "ジャケットを表示", "표지 보기"],
    "Antrean Pemutaran": ["Play queue", "再生キュー", "재생 대기열"],
    "Antrean masih kosong": ["The queue is empty", "キューは空です", "대기열이 비어 있습니다"],
    "Sedang Diputar": ["Now playing", "再生中", "현재 재생 중"],
    "Berikutnya dalam Antrean": ["Up next", "次の曲", "다음 곡"],
    "Putar Semua": ["Play all", "すべて再生", "모두 재생"],
    "Acak": ["Shuffle", "シャッフル", "셔플"],
    "Pencarian": ["Search", "検索", "검색"],
    "Mau dengarkan apa?": [
      "What do you want to hear?",
      "何を聴きますか？",
      "어떤 음악을 듣고 싶으세요?",
    ],
    "Saran pencarian": ["Search suggestions", "検索候補", "검색 제안"],
    "Rekomendasi artis": ["Suggested artists", "おすすめのアーティスト", "추천 아티스트"],
    "Artis": ["Artist", "アーティスト", "아티스트"],
    "ARTIS": ["ARTIST", "アーティスト", "아티스트"],
    "Lagu": ["Songs", "曲", "노래"],
    "Coba lengkapi nama artis atau judul lagu.": [
      "Try a fuller artist name or song title.",
      "アーティスト名や曲名を詳しく入力してください。",
      "아티스트 이름이나 곡 제목을 더 입력하세요.",
    ],
    "Pencarian Terakhir": ["Recent searches", "最近の検索", "최근 검색"],
    "Jelajahi Semua": ["Browse all", "すべて見る", "모두 둘러보기"],
    "Tambahkan ke playlist": ["Add to playlist", "プレイリストに追加", "재생목록에 추가"],
    "Lihat artis": ["View artist", "アーティストを見る", "아티스트 보기"],
    "Lihat album": ["View album", "アルバムを見る", "앨범 보기"],
    "Cari informasi album": ["Find album details", "アルバム情報を検索", "앨범 정보 찾기"],
    "Tambah ke antrean": ["Add to queue", "キューに追加", "대기열에 추가"],
    "Waktu tidur": ["Sleep timer", "スリープタイマー", "취침 타이머"],
    "Hapus dari favorit": ["Remove from favorites", "お気に入りから削除", "좋아요 취소"],
    "Sukai lagu": ["Like song", "お気に入りに追加", "좋아요"],
    "Jeda": ["Pause", "一時停止", "일시 정지"],
    "Putar": ["Play", "再生", "재생"],
    "Lagu berikutnya": ["Next track", "次の曲", "다음 곡"],
    "Lirik belum tersedia untuk lagu ini": [
      "Lyrics are unavailable for this track",
      "この曲の歌詞はまだありません",
      "이 곡의 가사를 찾을 수 없습니다",
    ],
    "Lagu ditambahkan ke playlist": [
      "Song added to playlist",
      "プレイリストに追加しました",
      "재생목록에 추가되었습니다",
    ],
    "Gagal menyimpan. Coba lagi.": [
      "Could not save. Try again.",
      "保存できません。再試行してください。",
      "저장하지 못했습니다. 다시 시도하세요.",
    ],
    "Simpan playlist": ["Save playlist", "プレイリストを保存", "재생목록 저장"],
    "Nama playlist wajib diisi": [
      "Enter a playlist name",
      "プレイリスト名を入力してください",
      "재생목록 이름을 입력하세요",
    ],
    "Buat playlist baru": ["Create a playlist", "プレイリストを作成", "재생목록 만들기"],
    "Belum ada playlist. Buat yang pertama.": [
      "No playlists yet. Create your first.",
      "最初のプレイリストを作成しましょう。",
      "아직 재생목록이 없습니다. 첫 목록을 만드세요.",
    ],
    "Lagu sudah ditambahkan": ["Song already added", "追加済みの曲", "이미 추가된 곡"],
    "Tautan disalin": ["Link copied", "リンクをコピーしました", "링크를 복사했습니다"],
    "Salin tautan": ["Copy link", "リンクをコピー", "링크 복사"],
    "Katalog belum dapat dimuat. Periksa koneksi lalu coba lagi.": [
      "Could not load the catalog. Check your connection and retry.",
      "読み込めません。接続を確認して再試行してください。",
      "목록을 불러올 수 없습니다. 연결을 확인하고 다시 시도하세요.",
    ],
    "Daftar lagu belum tersedia.": [
      "Track list is unavailable.",
      "曲一覧はまだありません。",
      "곡 목록을 사용할 수 없습니다.",
    ],
    "Lagu populer": ["Top songs", "人気の曲", "인기곡"],
    "Album": ["Album", "アルバム", "앨범"],
    "Hapus album tersimpan": ["Remove saved album", "保存済みアルバムを削除", "저장된 앨범 삭제"],
    "Simpan album di perangkat": [
      "Save album on device",
      "端末にアルバムを保存",
      "기기에 앨범 저장",
    ],
    "Opsi album": ["Album options", "アルバムのオプション", "앨범 옵션"],
    "Putar acak": ["Shuffle play", "シャッフル再生", "셔플 재생"],
    "Diikuti": ["Following", "フォロー中", "팔로잉"],
    "Ikuti artis": ["Follow artist", "フォロー", "아티스트 팔로우"],
    "Tentang": ["About", "概要", "정보"],
    "Biografi artis belum tersedia.": [
      "Artist biography is unavailable.",
      "アーティスト紹介はまだありません。",
      "아티스트 소개를 찾을 수 없습니다.",
    ],
    "Tampilkan lebih sedikit": ["Show less", "閉じる", "간략히 보기"],
    "Selengkapnya": ["Show more", "もっと見る", "더 보기"],
  };
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();
  @override
  bool isSupported(Locale locale) => AppStrings.supportedLocales.any(
    (l) => l.languageCode == locale.languageCode,
  );
  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture(AppStrings(locale));
  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}

extension AppTranslation on BuildContext {
  String tr(String value) => AppStrings.of(this).tr(value);
}

/// Only use for interface copy. Song titles, artist names and lyrics stay original.
class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    this.textDirection,
  });
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final String? semanticsLabel;
  final TextDirection? textDirection;
  @override
  Widget build(BuildContext context) => Text(
    context.tr(data),
    style: style,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
    softWrap: softWrap,
    semanticsLabel: semanticsLabel,
    textDirection: textDirection,
  );
}
