import 'package:element_x/core/utils/test_env_stub.dart'
    if (dart.library.io) 'package:element_x/core/utils/test_env_io.dart';
import 'package:element_x/theme/rop_colors.dart';
import 'package:element_x/theme/rop_spacing.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const online = RopColors.success;

  static ThemeData light({bool useInter = true}) =>
      _build(Brightness.light, useInter: useInter);

  static ThemeData dark({bool useInter = true}) =>
      _build(Brightness.dark, useInter: useInter);

  static ThemeData _build(Brightness brightness, {required bool useInter}) {
    final dark = brightness == Brightness.dark;
    final roles = RopTheme.fromBrightness(brightness);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: dark ? RopColors.darkBlue700 : RopColors.blue900,
      onPrimary: RopColors.white,
      primaryContainer: dark ? RopColors.darkBlue400 : RopColors.blue300,
      onPrimaryContainer: dark ? RopColors.darkBlue1300 : RopColors.blue1100,
      secondary: dark ? RopColors.darkBlue800 : RopColors.blue800,
      onSecondary: RopColors.white,
      secondaryContainer: dark
          ? RopColors.darkBlue300
          : const Color(0xFFF6EEDB),
      onSecondaryContainer: dark ? RopColors.darkBlue1300 : RopColors.blue1100,
      error: dark ? RopColors.criticalDark : RopColors.red,
      onError: RopColors.white,
      surface: dark ? RopColors.canvasDark : RopColors.white,
      onSurface: dark ? RopColors.textPrimaryDark : RopColors.textMain,
      surfaceContainerLowest: dark ? RopColors.canvasDark : RopColors.white,
      surfaceContainerLow: roles.surface,
      surfaceContainer: roles.surfaceRaised,
      surfaceContainerHigh: dark ? RopColors.darkBlue300 : RopColors.blue200,
      outline: roles.separator,
      outlineVariant: roles.separatorSubtle,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkRipple.splashFactory,
    );
    final textTheme =
        (isFlutterTest || !useInter
                ? base.textTheme
                : GoogleFonts.interTextTheme(base.textTheme))
            .apply(
              bodyColor: roles.textPrimary,
              displayColor: roles.textPrimary,
            );
    return base.copyWith(
      textTheme: textTheme,
      extensions: [roles],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: roles.railStart,
        foregroundColor: RopColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: roles.statusBar,
          systemNavigationBarColor: dark
              ? RopColors.canvasDark
              : roles.pageWashEnd,
          systemNavigationBarIconBrightness: dark
              ? Brightness.light
              : Brightness.dark,
        ),
        iconTheme: const IconThemeData(color: RopColors.white),
        actionsIconTheme: const IconThemeData(color: RopColors.white),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: roles.railStart,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.horizontal(
            end: Radius.circular(RopSpacing.sheetRadius),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: roles.primaryButton,
        foregroundColor: roles.textOnPrimary,
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RopSpacing.md),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: roles.primaryButton,
          foregroundColor: roles.textOnPrimary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: RopSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RopSpacing.controlRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: roles.textLink,
          minimumSize: const Size(48, 48),
          side: BorderSide(color: roles.separator),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RopSpacing.controlRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: roles.textLink,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RopSpacing.controlRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: roles.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RopSpacing.md,
          vertical: RopSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RopSpacing.controlRadius),
          borderSide: BorderSide(color: roles.separator),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RopSpacing.controlRadius),
          borderSide: BorderSide(color: roles.separator),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RopSpacing.controlRadius),
          borderSide: BorderSide(color: roles.focusRing, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: roles.canvas,
        margin: const EdgeInsets.symmetric(
          horizontal: RopSpacing.md,
          vertical: RopSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RopSpacing.cardRadius),
          side: BorderSide(color: roles.separatorSubtle),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: roles.surface,
        selectedColor: roles.primaryButton,
        secondarySelectedColor: roles.primaryButton,
        disabledColor: roles.surfaceRaised,
        labelStyle: textTheme.labelLarge?.copyWith(color: roles.textPrimary),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: roles.textOnPrimary,
        ),
        checkmarkColor: dark ? RopColors.darkBlue1300 : RopColors.gold,
        side: BorderSide(color: roles.separator),
        padding: const EdgeInsets.symmetric(
          horizontal: RopSpacing.sm,
          vertical: RopSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RopSpacing.controlRadius),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: RopSpacing.md),
        minTileHeight: 56,
        iconColor: roles.textLink,
        textColor: roles.textPrimary,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: roles.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RopSpacing.controlRadius),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: roles.separatorSubtle,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: roles.canvas,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(RopSpacing.sheetRadius),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: roles.canvas,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RopSpacing.cardRadius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? RopColors.darkBlue400 : RopColors.blue1100,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: RopColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RopSpacing.controlRadius),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: roles.railStart,
        indicatorColor: roles.selectionTint,
        selectedIconTheme: IconThemeData(color: roles.railActiveMarker),
        unselectedIconTheme: IconThemeData(color: roles.railText),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: roles.textOnPrimary,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: roles.railText,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? roles.textOnPrimary
              : roles.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? roles.primaryButton
              : roles.surfaceRaised,
        ),
      ),
      dividerColor: roles.separator,
    );
  }
}
