// lib/utils/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';

class AppTheme {
  // Original Brand Colors
  static const Color primaryBlue = Color(0xFF80C7F2);
  static const Color accentYellow = Color(0xFFFFD100);
  static const Color accentOrange = Color(0xFFF37021);
  static const Color darkText = Color(0xFF231F20);
  static const Color offWhite = Color(0xFFF8F9FA);

  // Functional Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFE53935);
  static const Color pending = Color(0xFF2196F3);

  // Compatibility Aliases
  static const Color primary = primaryBlue;
  static const Color secondary = Color(0xFF6AB7E2); // Slightly darker blue
  static const Color accent = accentOrange;
  static const Color accentGold = accentYellow;
  static const Color surface = Colors.white;
  static const Color cardBg = Colors.white;
  static const Color textPrimary = darkText;
  static const Color textSecondary = Color(0x99231F20);

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: accentOrange,
        tertiary: accentYellow,
        surface: Colors.white,
        onSurface: darkText,
        error: error,
      ),
      scaffoldBackgroundColor: offWhite,
      dividerTheme: DividerThemeData(color: primaryBlue.withValues(alpha: 0.1), thickness: 1),
      dividerColor: primaryBlue.withValues(alpha: 0.1),
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.dmSans(
            color: darkText, fontWeight: FontWeight.w900, fontSize: 32),
        displayMedium: GoogleFonts.dmSans(
            color: darkText, fontWeight: FontWeight.w800, fontSize: 28),
        displaySmall: GoogleFonts.dmSans(
            color: darkText, fontWeight: FontWeight.w800, fontSize: 24),
        titleLarge: GoogleFonts.dmSans(
            color: darkText, fontWeight: FontWeight.w700, fontSize: 20),
        titleMedium: GoogleFonts.dmSans(
            color: darkText, fontWeight: FontWeight.w700, fontSize: 16),
        titleSmall: GoogleFonts.dmSans(
            color: darkText, fontWeight: FontWeight.w600, fontSize: 14),
        bodyLarge: GoogleFonts.dmSans(color: darkText, fontSize: 16),
        bodyMedium: GoogleFonts.dmSans(color: darkText, fontSize: 14),
        bodySmall: GoogleFonts.dmSans(color: textSecondary, fontSize: 12),
        labelLarge: GoogleFonts.dmSans(
            color: darkText, fontWeight: FontWeight.w700, fontSize: 14),
        labelSmall: GoogleFonts.dmSans(
            color: textSecondary, fontWeight: FontWeight.w500, fontSize: 10),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.dmSans(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: primaryBlue.withValues(alpha: 0.1)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle:
              GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: primaryBlue.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: primaryBlue.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: darkText, fontSize: 14),
        hintStyle: TextStyle(color: darkText.withValues(alpha: 0.4), fontSize: 14),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    const darkBg = Color(0xFF0D0D0D); // Even darker
    const cardBgDark = Color(0xFF161616);

    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: accentOrange,
        tertiary: accentYellow,
        surface: cardBgDark,
        onSurface: Colors.white,
        error: error,
      ),
      scaffoldBackgroundColor: darkBg,
      dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.05), thickness: 1),
      dividerColor: Colors.white.withValues(alpha: 0.1),
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w900, fontSize: 32),
        displayMedium: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28),
        displaySmall: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24),
        titleLarge: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
        titleMedium: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
        titleSmall: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        bodyLarge: GoogleFonts.dmSans(color: Colors.white, fontSize: 16),
        bodyMedium: GoogleFonts.dmSans(color: Colors.white70, fontSize: 14),
        bodySmall: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12),
        labelLarge: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
        labelSmall: GoogleFonts.dmSans(
            color: Colors.white54, fontWeight: FontWeight.w500, fontSize: 10),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.dmSans(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: cardBgDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle:
              GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBgDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
        hintStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
      ),
    );
  }
}

extension StatusColor on OrderStatus {
  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return AppTheme.pending;
      case OrderStatus.waitingApproval:
        return AppTheme.warning;
      case OrderStatus.approved:
        return AppTheme.success;
      case OrderStatus.rejected:
        return AppTheme.error;
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.waitingApproval:
        return 'Waiting Approval';
      case OrderStatus.approved:
        return 'Approved';
      case OrderStatus.rejected:
        return 'Rejected';
    }
  }
}

extension PaymentStatusExt on PaymentStatus {
  Color get color {
    switch (this) {
      case PaymentStatus.pending:
        return AppTheme.warning;
      case PaymentStatus.approved:
        return AppTheme.success;
      case PaymentStatus.rejected:
        return AppTheme.error;
    }
  }

  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.approved:
        return 'Approved';
      case PaymentStatus.rejected:
        return 'Rejected';
    }
  }
}

extension DeliveryStatusExt on DeliveryStatus {
  Color get color {
    switch (this) {
      case DeliveryStatus.pending:
        return AppTheme.pending;
      case DeliveryStatus.inTransit:
        return AppTheme.accent;
      case DeliveryStatus.delivered:
        return AppTheme.success;
      case DeliveryStatus.canceled:
        return AppTheme.error;
    }
  }
}

extension ReceivingStatusExt on ReceivingStatus {
  Color get color {
    switch (this) {
      case ReceivingStatus.received:
        return AppTheme.success;
      case ReceivingStatus.damaged:
        return AppTheme.error;
      case ReceivingStatus.returned:
        return AppTheme.accent;
      case ReceivingStatus.pending:
        return AppTheme.warning;
    }
  }
}
