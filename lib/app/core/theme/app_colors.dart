import 'package:flutter/material.dart';

/// Chinese-style color palette for Village Explorer app
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color chineseRed = Color(0xFFC41E3A);
  static const Color chineseRedLight = Color(0xFFE85A6B);
  static const Color chineseRedDark = Color(0xFF8B1528);

  // Secondary Colors
  static const Color imperialGold = Color(0xFFFFD700);
  static const Color imperialGoldLight = Color(0xFFFFE44D);
  static const Color imperialGoldDark = Color(0xFFCCAA00);

  // Accent Colors
  static const Color jadeGreen = Color(0xFF00A86B);
  static const Color jadeGreenLight = Color(0xFF4DC99A);
  static const Color jadeGreenDark = Color(0xFF007A4D);

  // Background Colors
  static const Color warmCream = Color(0xFFFFF8F0);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color paperWhite = Color(0xFFFAF9F6);

  // Text Colors
  static const Color darkGray = Color(0xFF2D2D2D);
  static const Color mediumGray = Color(0xFF666666);
  static const Color lightGray = Color(0xFFE0E0E0);

  // Additional Chinese Colors
  static const Color indigoBlue = Color(0xFF2E4A62);
  static const Color cinnabar = Color(0xFFE34234);
  static const Color bambooGreen = Color(0xFF7BA05B);
  static const Color inkBlack = Color(0xFF1A1A1A);

  // Functional Colors
  static const Color success = jadeGreen;
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = indigoBlue;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [chineseRed, chineseRedDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [imperialGoldLight, imperialGold, imperialGoldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [pureWhite, warmCream],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
