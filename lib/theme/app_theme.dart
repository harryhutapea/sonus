import 'package:flutter/material.dart';

import 'package:sonus/theme/app_colors.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,

  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    brightness: Brightness.dark,
    primary: AppColors.brand,
    onPrimary: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainer: AppColors.surfaceContainer,
    onSurfaceVariant: AppColors.onSurfaceVariant,
  ),

  scaffoldBackgroundColor: AppColors.surface,

  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.surface,
    elevation: 0,
    centerTitle: false,
    iconTheme: IconThemeData(color: AppColors.onSurface),
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.surfaceDim,
    selectedItemColor: AppColors.brand,
    unselectedItemColor: AppColors.onSurfaceVariant,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
    selectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    unselectedLabelStyle: TextStyle(fontSize: 14),
    enableFeedback: false,
  ),

  splashFactory: NoSplash.splashFactory,

  cardTheme: CardThemeData(
    color: AppColors.surfaceContainer,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);
