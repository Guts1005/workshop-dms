import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern Automotive UI Design Tokens (Rivian + MG i-SMART Aesthetic)
/// Luminous canvas, soft ambient card elevations, rounded pill controls,
/// and high-contrast glanceable automotive typography.
class AppTokens {
  // --- Canvas & Surfaces ---
  static const Color base = Color(0xFFF6F8FA);          // Luminous modern app canvas
  static const Color surface = Color(0xFFFFFFFF);       // Clean white cards & sheets
  static const Color surfaceSubtle = Color(0xFFF1F3F5); // Light tactile grey for pill buttons
  static const Color inverse = Color(0xFF0F141C);       // Sleek carbon/obsidian for top bar & primary pills
  static const Color raised = Color(0xFFFFFFFF);        // Inputs, dialog sheets, white card fill

  // --- Text & Typography ---
  static const Color textPrimary = Color(0xFF0F172A);   // Deep slate for high contrast readability
  static const Color textSecondary = Color(0xFF64748B); // Muted slate for secondary labels
  static const Color textTertiary = Color(0xFF94A3B8);  // Subtle watermark & placeholders
  static const Color textOnDark = Color(0xFFF8FAFC);    // White text on dark elements

  // --- Borders & Dividers ---
  static const Color borderLight = Color(0xFFE2E8F0);   // Hairline card border
  static const Color borderSolid = Color(0xFFCBD5E1);   // Standard input border
  static const Color dividerPassive = Color(0x1A000000); // 10% opacity divider

  // --- Automotive Accents ---
  static const Color brandRed = Color(0xFFE03131);      // MG Passion Red / Critical / Highlight
  static const Color redOrange = Color(0xFFE03131);     // Backward compatibility for existing references
  static const Color orange = Color(0xFFF59E0B);        // Due-soon amber (#1E1E1E text)
  static const Color green = Color(0xFF16A34A);         // Rivian emerald / passed / healthy
  static const Color blue = Color(0xFF2563EB);          // HSRP IND blue / telemetry accent
  static const Color pinkPressed = Color(0xFFFFE4E6);

  // --- Radii & Invariants ---
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(24.0));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(10.0));
  static const BorderRadius zeroRadius = BorderRadius.zero;

  // --- Soft Ambient Shadows ---
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 16.0,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x05000000),
      blurRadius: 4.0,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> vehicleGroundShadow = [
    BoxShadow(
      color: Color(0x28000000),
      blurRadius: 28.0,
      spreadRadius: -4.0,
      offset: Offset(0, 14),
    ),
  ];

  // --- Metrics, Touch & Table Invariants ---
  static const double minTouchTarget = 48.0;
  static const double minTouchGap = 8.0;
  static const double minTableRowHeight = 56.0;
  static const double minBodyFontSize = 16.0;

  // --- Focus Rings ---
  static const double focusRingWidth = 2.0;
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
