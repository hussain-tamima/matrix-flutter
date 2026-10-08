import 'package:flutter/material.dart';

/// Raw ROP brand colours. Widgets should use [RopTheme] roles, not these, except
/// where a role does not exist (for example the EKO mark, which is an image).
abstract final class RopColors {
  static const bluePrimary = Color(0xFF123F7A);
  static const blueDark = Color(0xFF0B2F63);
  static const blueSecondary = Color(0xFF1D5A9B);
  static const blueLight = Color(0xFFEAF3FA);
  static const blueDarker = Color(0xFF08254F);
  static const white = Color(0xFFFFFFFF);
  static const bgSoft = Color(0xFFF7F8FA);
  static const textMain = Color(0xFF263238);
  static const textSecondary = Color(0xFF6B7280);
  static const border = Color(0xFFD9E0E7);
  static const red = Color(0xFFC8102E);
  static const redDark = Color(0xFFA50D26);
  static const gold = Color(0xFFC8A24D);

  /// Light blue scale. 900 is the primary blue.
  static const blue100 = Color(0xFFF7FAFD);
  static const blue200 = Color(0xFFEFF5FB);
  static const blue300 = Color(0xFFEAF3FA);
  static const blue400 = Color(0xFFD6E4F2);
  static const blue500 = Color(0xFFB7CFE7);
  static const blue600 = Color(0xFF93B5D9);
  static const blue700 = Color(0xFF5F8FC3);
  static const blue800 = Color(0xFF1D5A9B);
  static const blue900 = Color(0xFF123F7A);
  static const blue1000 = Color(0xFF0B2F63);
  static const blue1100 = Color(0xFF08254F);
  static const blue1200 = Color(0xFF061B3B);
  static const blue1300 = Color(0xFF04132B);
  static const blue1400 = Color(0xFF020B1C);

  /// Dark blue scale. 900 is the accent and is light enough to read on navy.
  static const darkBlue100 = Color(0xFF050F1F);
  static const darkBlue200 = Color(0xFF07142A);
  static const darkBlue300 = Color(0xFF0A1C38);
  static const darkBlue400 = Color(0xFF0E2649);
  static const darkBlue500 = Color(0xFF123F7A);
  static const darkBlue600 = Color(0xFF17518F);
  static const darkBlue700 = Color(0xFF1D5A9B);
  static const darkBlue800 = Color(0xFF3A78B8);
  static const darkBlue900 = Color(0xFF5F97CF);
  static const darkBlue1000 = Color(0xFF7FB2E5);
  static const darkBlue1100 = Color(0xFF9DC3EC);
  static const darkBlue1200 = Color(0xFFBDD8F3);
  static const darkBlue1300 = Color(0xFFD9E8F8);
  static const darkBlue1400 = Color(0xFFEDF4FB);

  static const canvasDark = Color(0xFF0E1420);
  static const surfaceDark = Color(0xFF131B2B);
  static const surfaceRaisedDark = Color(0xFF1A2436);
  static const separatorDark = Color(0xFF26324A);
  static const separatorSubtleDark = Color(0xFF1D2739);
  static const textPrimaryDark = Color(0xFFE6ECF3);
  static const textSecondaryDark = Color(0xFFA8B3C4);
  static const criticalDark = Color(0xFFFF7A8A);
  static const criticalHoverDark = Color(0xFFE0213F);
  static const surfaceRaisedLight = Color(0xFFEEF1F5);
  static const separatorSubtleLight = Color(0xFFE9EEF3);
  static const shellCanvas1 = Color(0xFFE6EEF8);
  static const shellCanvas2 = Color(0xFFF6F8FC);
  static const shellCanvas1Dark = Color(0xFF0A1120);
  static const shellCanvas2Dark = Color(0xFF0F1828);
  static const railActive = Color(0xFF2A6FC0);
  static const success = Color(0xFF12B76A);
}
