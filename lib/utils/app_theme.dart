import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryColor = Color(0xFF7B6BFF);
  static const incomeColor = Color(0xFF3EE184);
  static const expenseColor = Color(0xFFFF7070);
  static const warningColor = Color(0xFFFFD95A);
  static const infoColor = Color(0xFF6AA5FF);
  static const surfaceColor = Color(0xFF161616);
  static const cardColor = Color(0xFF1E1E1E);
  static const elevatedSurfaceColor = Color(0xFF262626);
  static const backgroundColor = Color(0xFF0D0D0D);
  static const borderColor = Color(0xFF2D2D2D);
  static const dividerColor = Color(0xFF383838);
  static const inputBorderColor = Color(0xFF404040);
  static const primaryTextColor = Color(0xFFF5F5F5);
  static const secondaryTextColor = Color(0xFFB0B0B8);
  static const mutedTextColor = Color(0xFF7A7A85);
  static const disabledTextColor = Color(0xFF5A5A63);
  static const glassColor = Color(0x661E1E1E);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: warningColor,
        surface: surfaceColor,
        onSurface: primaryTextColor,
        error: expenseColor,
      ),
      cardColor: cardColor,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: primaryTextColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: primaryTextColor),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: mutedTextColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withAlpha(42),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? primaryTextColor
                : secondaryTextColor,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? primaryColor
                : secondaryTextColor,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: primaryTextColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        showDragHandle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: inputBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        labelStyle: const TextStyle(color: secondaryTextColor),
        hintStyle: const TextStyle(color: mutedTextColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: primaryTextColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: primaryColor.withAlpha(77),
        labelStyle: const TextStyle(color: primaryTextColor),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class AppConstants {
  static const List<String> accountIcons = [
    'cash',
    'bank',
    'card',
    'atm',
    r'$money',
    'coin',
    'chart',
  ];

  static const List<String> categoryIcons = [
    'restaurant',
    'pizza',
    'coffee',
    'car',
    'flight',
    'home',
    'shopping',
    'utilities',
    'medical',
    'gaming',
    'books',
    'work',
    'computer',
    'gift',
    'cash',
    'trending_up',
    'music',
    'fitness',
    'beauty',
    'pets',
    'fuel',
    'phone',
    'bar',
    'movie',
    'internet',
    'box',
  ];

  static const List<int> colorOptions = [
    0xFF7B6BFF,
    0xFF3EE184,
    0xFFFFD95A,
    0xFFFF7070,
    0xFF6AA5FF,
    0xFFB0B0B8,
    0xFF5B47F2,
    0xFF27C46B,
  ];
}
