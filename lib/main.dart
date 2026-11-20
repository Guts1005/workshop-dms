import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ui_kit/tokens/app_tokens.dart';
import 'data/supabase/backend_config.dart';
import 'data/supabase/startup_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = BackendConfig.current;
  if (config.isConfigured) {
    await Supabase.initialize(
      url: config.url,
      publishableKey: config.publishableKey,
    );
  }
  runApp(const ProviderScope(child: WorkshopDmsApp()));
}

class WorkshopDmsApp extends StatelessWidget {
  const WorkshopDmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workshop DMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: AppTokens.base,
        colorScheme: const ColorScheme.light(
          primary: AppTokens.inverse,
          surface: AppTokens.surface,
          error: AppTokens.redOrange,
        ),
        // Strict invariant: sharp corners across all components
        cardTheme: const CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: AppTokens.zeroRadius),
          elevation: 0,
        ),
        dialogTheme: const DialogThemeData(
          shape: RoundedRectangleBorder(borderRadius: AppTokens.zeroRadius),
          elevation: 0,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          shape: RoundedRectangleBorder(borderRadius: AppTokens.zeroRadius),
          elevation: 0,
        ),
      ),
      home: BackendConfig.current.isConfigured
          ? const StartupGate()
          : const BackendConfigurationScreen(),
    );
  }
}
