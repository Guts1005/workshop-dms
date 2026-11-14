import 'package:flutter/material.dart';

/// Digital Health Passport Design System Tokens
/// Pure brutalist, high-density, sharp 90-degree corners, zero gradients, zero shadows.
class AppTokens {
  // --- Background Palette ---
  /// Main application background (#E4E2DD)
  static const Color base = Color(0xFFE4E2DD);

  /// Panels, table header rows, grouped sections (#D9D6D0)
  static const Color surface = Color(0xFFD9D6D0);

  /// Top navigation bar, headers, dark status surfaces, selected rows (#1E1E1E)
  static const Color inverse = Color(0xFF1E1E1E);

  /// Input fields, pressed button states, dialog sheets (#FFFFFF)
  static const Color raised = Color(0xFFFFFFFF);

  // --- Text & Typography ---
  /// High-contrast primary text (#1E1E1E)
  static const Color textPrimary = Color(0xFF1E1E1E);

  /// Secondary metadata, field labels, measurement units (#444444)
  static const Color textSecondary = Color(0xFF444444);

  /// Text rendered over #1E1E1E surfaces (#E4E2DD)
  static const Color textOnDark = Color(0xFFE4E2DD);

  // --- Borders & Dividers ---
  /// 1px solid border on all interactive elements, cards, and inputs
  static const Color borderSolid = Color(0xFF1E1E1E);

  /// Passive row divider inside read-only data blocks (30% opacity)
  static const Color dividerPassive = Color(0x4D1E1E1E);

  // --- Accents & Semantics ---
  /// Active tab indicator, critical alerts, #DB4A2B damage markers
  static const Color redOrange = Color(0xFFDB4A2B);

  /// Due-soon status chip, progress bars (#F8A348)
  static const Color orange = Color(0xFFF8A348);

  /// Paid, passed, healthy component status (#2E6B3F)
  static const Color green = Color(0xFF2E6B3F);

  /// Pressed row tint ONLY with #1E1E1E text (~7.5:1 ratio) (#FF89A9)
  static const Color pinkPressed = Color(0xFFFF89A9);

  // --- Touch & Ergonomics Invariants ---
  /// Minimum touch target size in logical pixels (WCAG AAA)
  static const double minTouchTarget = 48.0;

  /// Minimum gap between adjacent tap targets
  static const double minTouchGap = 8.0;

  /// Minimum table row height for garage tablet legibility
  static const double minTableRowHeight = 56.0;

  /// Minimum body font size for arm's length reading
  static const double minBodyFontSize = 16.0;

  // --- Focus Rings ---
  /// Focus outline width for hybrid laptop keyboard navigation
  static const double focusRingWidth = 3.0;
  static const double focusRingOffset = 2.0;
}
