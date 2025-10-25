# ⏰ Fitur Waktu Habit - Dokumentasi Lengkap

## 🎯 Cara Kerja Fitur

### 1. **Set Waktu Habit**
- Buka Detail Habit
- Klik icon ⏰ di pojok kanan atas
- Atau klik card "Waktu Habit" jika sudah di-set sebelumnya
- Pilih **Waktu Mulai** (contoh: 06:00)
- Pilih **Waktu Selesai** (contoh: 22:00)
- Klik **Simpan Waktu**

### 2. **Auto-Complete Setiap 24 Jam**
System akan otomatis mencentang habit ketika:
- ✅ Waktu sekarang berada dalam range waktu yang di-set
- ✅ Habit belum di-complete hari ini
- ✅ Aplikasi sedang berjalan (foreground)

**Contoh:**
```
Habit: "Minum Air"
Waktu: 06:00 - 22:00

Jam 06:00 → Auto-check ✅
Jam 10:00 → Sudah complete ✅ (tidak di-check lagi)
Jam 00:00 (hari berikutnya) → Reset, siap auto-check lagi
```

### 3. **Progress Tracking**
Setiap 24 jam (tengah malam), habit akan:
- Reset status completion
- Calendar grid akan menampilkan tanggal yang sudah complete (warna biru)
- Streak akan bertambah jika habit complete berturut-turut

## 📊 Tampilan di UI

### Home Page
```
┌────────────────────────────────┐
│  🎯 Olahraga Pagi              │
│  Lari 30 menit                 │
│  🔥 5 hari beruntun             │
│  ⏰ 2 jam 30 menit lagi ← BARU │ ← Countdown jika dalam range
└────────────────────────────────┘
```

### Detail Page
```
┌────────────────────────────────┐
│  Waktu Habit                   │
│  06:00 - 22:00          [Edit] │
└────────────────────────────────┘

Riwayat 30 Hari:
[26] [27] [28] [29] [30] [ 1] [ 2]
                    [25] ← Hari ini (biru jika complete)
```

## 🔧 File yang Di-update

1. **models/habit.dart**
   - Tambah field: `startTime`, `endTime`
   - Update: `toMap()`, `fromMap()`, `copyWith()`

2. **database/database_helper.dart**
   - Tambah kolom: `startTime TEXT`, `endTime TEXT`

3. **pages/habit_time_settings_page.dart** ← BARU
   - UI untuk set waktu mulai & selesai
   - TimePicker dialog
   - Save & Clear time

4. **pages/habit_detail_page.dart**
   - Tambah icon ⏰ di AppBar
   - Tampilkan card "Waktu Habit" jika sudah di-set
   - Button edit waktu

5. **services/habit_auto_check_service.dart** ← BARU
   - `isWithinTimeRange()` - Check apakah sekarang dalam range waktu
   - `autoCheckHabit()` - Auto-complete habit
   - `checkAllHabits()` - Loop semua habit untuk auto-check
   - `getRemainingTime()` - Hitung sisa waktu
   - `shouldShowReminder()` - Logic untuk reminder (future)

6. **widgets/habit_card.dart**
   - Tampilkan info waktu di bawah streak
   - Countdown jika dalam range waktu
   - Warna hijau jika aktif

7. **pages/home_page.dart**
   - Integrasi `HabitAutoCheckService`
   - Auto-check setiap 1 menit

## 💡 Use Cases

### Use Case 1: Habit Pagi
```
Habit: "Sarapan Sehat"
Waktu: 06:00 - 10:00

06:00 → Auto-check ✅
10:01 → Expired (harus manual jika belum complete)
```

### Use Case 2: Habit Malam
```
Habit: "Tidur Tepat Waktu"
Waktu: 22:00 - 23:59

22:00 → Auto-check ✅
00:00 → Reset untuk hari berikutnya
```

### Use Case 3: Habit Lintas Hari
```
Habit: "Shift Malam"
Waktu: 23:00 - 06:00 (besok)

23:00 → Auto-check ✅
00:30 → Masih dalam range ✅
06:01 → Expired
```

### Use Case 4: Habit Sepanjang Hari
```
Habit: "Minum 8 Gelas Air"
Waktu: 06:00 - 22:00

Sistem akan auto-check saat masuk range
User bisa manual check kapan saja
```

## ⚠️ Catatan Penting

### 1. **Batasan Auto-Check**
- Hanya berjalan saat aplikasi aktif (foreground)
- Tidak berjalan di background (butuh background service terpisah)
- Check setiap 1 menit, bukan real-time

### 2. **Manual Override**
User tetap bisa:
- ✅ Manual check/uncheck kapan saja
- ✅ Edit waktu kapan saja
- ✅ Hapus setting waktu

### 3. **Database Migration**
Jika sudah ada data lama:
```dart
// Option 1: Uninstall & reinstall app
// Option 2: Tambah migration script
await db.execute('ALTER TABLE habits ADD COLUMN startTime TEXT');
await db.execute('ALTER TABLE habits ADD COLUMN endTime TEXT');
```

## 🎨 Warna & Icon

| Status | Icon | Warna | Keterangan |
|--------|------|-------|-----------|
| Dalam range waktu | ⏰ | Hijau (#4CAF50) | Countdown aktif |
| Di luar range | ⏰ | Abu-abu (#757575) | Tampil waktu saja |
| Tidak ada waktu | - | - | Tidak tampil |
| Complete | ✅ | Biru (#0077BE) | Sudah selesai |

## 🚀 Future Enhancements

1. **Notifications** 🔔
   - Reminder 1 jam sebelum end time
   - Push notification saat masuk time range

2. **Background Service** 🔄
   - Auto-check meski app tidak aktif
   - Persistent tracking

3. **Recurring Time** 📅
   - Atur waktu berbeda per hari
   - Weekend vs Weekday

4. **Smart Suggestions** 🤖
   - AI suggest best time berdasarkan history
   - Optimal time berdasarkan completion rate

5. **Time Analytics** 📊
   - Grafik completion by time
   - Best performing time slots
   - Productivity heatmap

## 📝 Testing Checklist

- [✅] Set waktu mulai & selesai
- [ ] Auto-check saat masuk range waktu
- [ ] Countdown tampil dengan benar
- [ ] Calendar grid update setiap hari
- [ ] Streak bertambah jika complete berturut-turut
- [✅] Edit waktu berfungsi
- [✅] Hapus waktu berfungsi
- [ ] Manual check/uncheck tetap bisa
- [ ] Tidak double-check di hari yang sama
- [ ] Reset tengah malam

## 🐛 Known Issues

1. **Background Limitation**: Auto-check hanya saat app aktif
2. **Time Zone**: Belum handle multiple timezone
3. **Battery**: Polling setiap menit bisa drain battery

## 📞 Support

Jika ada bug atau pertanyaan, silakan kontak developer! 🚀