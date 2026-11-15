import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Digital Health Passport UI Kit Design Tokens
/// Rigid 90° Geometry, Zero Border Radius, High-Contrast Industrial Palette.
class AppTokens {
  // --- Background Palette ---
  static const Color base = Color(0xFFE4E2DD);       // App background
  static const Color surface = Color(0xFFD9D6D0);    // Panels, table headers, grouped rows
  static const Color inverse = Color(0xFF1E1E1E);    // Top bar, headers, dark surfaces
  static const Color raised = Color(0xFFFFFFFF);     // Inputs, dialog sheets, white card fill

  // --- Text & Typography ---
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF444444);
  static const Color textOnDark = Color(0xFFE4E2DD);

  // --- Borders & Dividers ---
  static const Color borderSolid = Color(0xFF1E1E1E);
  static const Color dividerPassive = Color(0x4D1E1E1E); // 30% opacity of #1E1E1E

  // --- Accents ---
  static const Color redOrange = Color(0xFFDB4A2B);  // Critical, active tab, damage markers
  static const Color orange = Color(0xFFF8A348);     // Due-soon, progress fill (#1E1E1E text)
  static const Color green = Color(0xFF2E6B3F);      // Paid, passed, healthy (#FFFFFF text)
  static const Color pinkPressed = Color(0xFFFF89A9); // Pressed row tint ONLY with #1E1E1E text

  // --- Metrics, Touch & Radius Invariants ---
  static const BorderRadius zeroRadius = BorderRadius.zero;
  static const double minTouchTarget = 48.0;
  static const double minTouchGap = 8.0;
  static const double minTableRowHeight = 56.0;
  static const double minBodyFontSize = 16.0;

  // --- Focus Rings ---
  static const double focusRingWidth = 3.0;
  static const double focusRingOffset = 2.0;

  // --- Typography Styles ---
  static TextStyle fontMonospace({
    double fontSize = 14.0,
    FontWeight fontWeight = FontWeight.w600,
    Color color = textPrimary,
    double? letterSpacing,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle fontBody({
    double fontSize = 16.0,
    FontWeight fontWeight = FontWeight.w400,
    Color color = textPrimary,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
}
