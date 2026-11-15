import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui_kit/tokens/app_tokens.dart';
import 'routing/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: WorkshopDmsApp(),
    ),
  );
}

class WorkshopDmsApp extends StatelessWidget {
  const WorkshopDmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Workshop DMS',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
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
    );
  }
}
