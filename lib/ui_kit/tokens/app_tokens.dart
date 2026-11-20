import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared palette and interaction metrics for the sharp, flat workshop UI.
class AppTokens {
  // --- Canvas & Surfaces ---
  static const Color base = Color(0xFFE4E2DD);
  static const Color surface = Color(0xFFD9D6D0);
  static const Color surfaceSubtle = Color(0xFFCECBC5);
  static const Color inverse = Color(0xFF1E1E1E);
  static const Color raised = Color(0xFFFFFFFF);

  // --- Text & Typography ---
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF444444);
  static const Color textTertiary = Color(0xFF444444);
  static const Color textOnDark = Color(0xFFE4E2DD);

  // --- Borders & Dividers ---
  static const Color borderLight = Color(0x4D1E1E1E);
  static const Color borderSolid = Color(0xFF1E1E1E);
  static const Color dividerPassive = Color(0x4D1E1E1E);

  // --- Automotive Accents ---
  static const Color brandRed = Color(0xFFDB4A2B);
  static const Color redOrange = brandRed;
  static const Color orange = Color(0xFFF8A348);
  static const Color green = Color(0xFF2E6B3F);
  static const Color blue = Color(0xFF003399);
  static const Color pinkPressed = Color(0xFFFF89A9);

  // --- Radii & Invariants ---
  static const BorderRadius cardRadius = BorderRadius.zero;
  static const BorderRadius pillRadius = BorderRadius.zero;
  static const BorderRadius buttonRadius = BorderRadius.zero;
  static const BorderRadius inputRadius = BorderRadius.zero;
  static const BorderRadius zeroRadius = BorderRadius.zero;

  // --- Soft Ambient Shadows ---
  static const List<BoxShadow> softShadow = [];

  static const List<BoxShadow> vehicleGroundShadow = [];

  // --- Metrics, Touch & Table Invariants ---
  static const double minTouchTarget = 48.0;
  static const double minTouchGap = 8.0;
  static const double minTableRowHeight = 56.0;
  static const double minBodyFontSize = 16.0;

  // --- Focus Rings ---
  static const double focusRingWidth = 3.0;
  static const double focusRingOffset = 2.0;

  // --- Typography Styles ---
  static TextStyle fontMonospace({
    double fontSize = 16.0,
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
