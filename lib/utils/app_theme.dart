import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors extracted directly from Finzo logo
  static const primaryColor = Color(
    0xFF635BFF,
  ); // Electric Iris Purple ("F" and "inzo")
  static const incomeColor = Color(
    0xFF00E676,
  ); // Mint Emerald Green (banknote & right bar)
  static const expenseColor = Color(0xFFFF5252); // Coral Red
  static const warningColor = Color(0xFFFFB800); // Golden Amber Coin
  static const goldColor = Color(0xFFFFB800); // Golden Amber
  static const infoColor = Color(0xFF38BDF8); // Electric Sky Blue
  static const surfaceColor = Color(
    0xFF11131B,
  ); // Obsidian surface with rich indigo undertone
  static const cardColor = Color(0xFF171924); // Obsidian elevated card surface
  static const elevatedSurfaceColor = Color(
    0xFF202333,
  ); // Interactive elevated layers
  static const backgroundColor = Color(
    0xFF08090E,
  ); // Pitch obsidian OLED canvas
  static const borderColor = Color(0xFF25283B);
  static const dividerColor = Color(0xFF1D202F);
  static const inputBorderColor = Color(0xFF2E324A);
  static const primaryTextColor = Color(0xFFF8FAFC);
  static const secondaryTextColor = Color(0xFF94A3B8);
  static const mutedTextColor = Color(0xFF64748B);
  static const disabledTextColor = Color(0xFF475569);
  static const glassColor = Color(0x99171924);

  // Logo dual-accent brand gradients ("BUDGET FOR SUCCESS")
  static const brandGradient = LinearGradient(
    colors: [primaryColor, incomeColor],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF635BFF), Color(0xFF4338CA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const goldGradient = LinearGradient(
    colors: [Color(0xFFFFC107), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
        indicatorColor: primaryColor.withAlpha(46),
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
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: inputBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
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
            borderRadius: BorderRadius.circular(14),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // Distinct, harmonious fintech color palette matching logo
  static const List<int> colorOptions = [
    0xFF635BFF, // Electric Iris Purple
    0xFF00E676, // Mint Emerald Green
    0xFFFFB800, // Golden Amber
    0xFFFF5252, // Coral Red
    0xFF38BDF8, // Sky Blue
    0xFFEC4899, // Pink Rose
    0xFF8B5CF6, // Deep Violet
    0xFF14B8A6, // Cyan Teal
  ];
}
