import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF0077BE); // Biru laut
  static const Color secondaryBlue = Color(0xFF87CEEB); // Biru muda
  static const Color accentOrange = Color(0xFFFF6B35); // Orange untuk streak
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningYellow = Color(0xFFFFD700);
  static const Color backgroundColor = Colors.white;
  static const Color textPrimary = Colors.black;
  static Color textSecondary = Colors.grey[600]!;
  static Color divider = Colors.grey[300]!;
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}

class AppConstants {
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double cardElevation = 2.0;
  
  static const List<String> habitIcons = [
    // Fitness & Health
    '🎯', '💪', '🏃', '🧘', '🚴', '⛹️', '🏊', '🤸',
    
    // Learning & Productivity
    '📚', '✍️', '📖', '💻', '📝',
    
    // Creative & Hobbies
    '🎨', '🎸', '🎬', '📷', '🎮', '🧩',
    
    // Social & Spiritual
    '📿','💝', '🤝',
    
    // Daily Habits
    '☕', '🌅', '🌙', '🔔','📅', '✅',
    
    // Nature & Environment
    '🌳','🌊', '🏔️',
    
  ];

  static const List<String> motivationalQuotes = [
    'Setiap hari adalah kesempatan baru!',
    'Konsistensi adalah kunci kesuksesan',
    'Mulai hari ini, bukan besok',
    'Progress, bukan perfeksi',
    'Kebiasaan kecil, hasil besar',
  ];
}

class AppDurations {
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}