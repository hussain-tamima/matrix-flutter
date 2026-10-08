import 'package:element_x/theme/rop_colors.dart';
import 'package:flutter/material.dart';

/// Semantic ROP roles. Read these from widgets, not [RopColors] hex values.
class RopTheme extends ThemeExtension<RopTheme> {
  const RopTheme({
    required this.textPrimary,
    required this.textSecondary,
    required this.textLink,
    required this.textOnPrimary,
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.separator,
    required this.separatorSubtle,
    required this.primaryButton,
    required this.primaryButtonHover,
    required this.primaryButtonPressed,
    required this.focusRing,
    required this.infoBadge,
    required this.warningSurface,
    required this.warningText,
    required this.critical,
    required this.criticalButton,
    required this.railStart,
    required this.railEnd,
    required this.railText,
    required this.railActiveMarker,
    required this.ownBubble,
    required this.ownBubbleText,
    required this.otherBubble,
    required this.otherBubbleText,
    required this.selectionTint,
    required this.hoverTint,
    required this.sendGradientStart,
    required this.sendGradientEnd,
    required this.pageWashStart,
    required this.pageWashEnd,
    required this.fortWashStart,
    required this.fortWashEnd,
    required this.chatWash,
    required this.homeCard,
    required this.signInCard,
    required this.signInCardBorder,
    required this.cardShadow,
    required this.bubbleShadow,
    required this.signInWashStart,
    required this.signInWashMid,
    required this.signInWashEnd,
    required this.statusBar,
  });

  factory RopTheme.fromBrightness(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return RopTheme(
      textPrimary: dark ? RopColors.textPrimaryDark : RopColors.textMain,
      textSecondary: dark
          ? RopColors.textSecondaryDark
          : RopColors.textSecondary,
      textLink: dark ? RopColors.darkBlue1000 : RopColors.blue900,
      textOnPrimary: RopColors.white,
      canvas: dark ? RopColors.canvasDark : RopColors.white,
      surface: dark ? RopColors.surfaceDark : RopColors.bgSoft,
      surfaceRaised: dark
          ? RopColors.surfaceRaisedDark
          : RopColors.surfaceRaisedLight,
      separator: dark ? RopColors.separatorDark : RopColors.border,
      separatorSubtle: dark
          ? RopColors.separatorSubtleDark
          : RopColors.separatorSubtleLight,
      primaryButton: dark ? RopColors.darkBlue700 : RopColors.blue900,
      primaryButtonHover: dark ? RopColors.darkBlue800 : RopColors.blue1000,
      primaryButtonPressed: dark ? RopColors.darkBlue500 : RopColors.blue1100,
      focusRing: dark ? RopColors.darkBlue1000 : RopColors.blue800,
      infoBadge: dark ? RopColors.darkBlue300 : RopColors.blue300,
      warningSurface: dark ? const Color(0xFF352D1C) : const Color(0xFFFFF6DC),
      warningText: dark ? const Color(0xFFF3D98B) : RopColors.blue1100,
      critical: dark ? RopColors.criticalDark : RopColors.red,
      criticalButton: RopColors.red,
      railStart: dark ? const Color(0xFF0A1D3A) : RopColors.blue1000,
      railEnd: dark ? const Color(0xFF050E1E) : RopColors.blue1100,
      railText: Color.fromRGBO(255, 255, 255, dark ? 0.72 : 0.78),
      railActiveMarker: dark ? RopColors.darkBlue700 : RopColors.gold,
      ownBubble: dark ? RopColors.blue900 : RopColors.blue400,
      ownBubbleText: dark ? RopColors.white : RopColors.textMain,
      otherBubble: dark ? RopColors.surfaceRaisedDark : RopColors.white,
      otherBubbleText: dark ? RopColors.textPrimaryDark : RopColors.textMain,
      selectionTint: dark
          ? const Color.fromRGBO(127, 178, 229, 0.16)
          : const Color.fromRGBO(18, 63, 122, 0.10),
      hoverTint: dark
          ? const Color.fromRGBO(127, 178, 229, 0.08)
          : const Color.fromRGBO(18, 63, 122, 0.06),
      sendGradientStart: dark ? RopColors.darkBlue600 : RopColors.blue800,
      sendGradientEnd: dark ? RopColors.darkBlue900 : RopColors.blue900,
      pageWashStart: dark ? RopColors.shellCanvas1Dark : RopColors.shellCanvas1,
      pageWashEnd: dark ? RopColors.shellCanvas2Dark : RopColors.shellCanvas2,
      fortWashStart: dark
          ? const Color.fromRGBO(10, 17, 32, 0.92)
          : const Color.fromRGBO(230, 239, 248, 0.84),
      fortWashEnd: dark
          ? const Color.fromRGBO(10, 17, 32, 0.58)
          : const Color.fromRGBO(246, 248, 252, 0.22),
      chatWash: dark
          ? const Color.fromRGBO(10, 17, 32, 0.78)
          : Colors.transparent,
      homeCard: dark
          ? const Color.fromRGBO(19, 27, 43, 0.88)
          : const Color.fromRGBO(255, 255, 255, 0.90),
      signInCard: dark
          ? const Color.fromRGBO(14, 20, 32, 0.72)
          : const Color.fromRGBO(255, 255, 255, 0.82),
      signInCardBorder: Color.fromRGBO(255, 255, 255, dark ? 0.16 : 0.35),
      cardShadow: dark
          ? const Color.fromRGBO(0, 0, 0, 0.35)
          : const Color.fromRGBO(11, 47, 99, 0.10),
      bubbleShadow: dark
          ? const Color.fromRGBO(0, 0, 0, 0.30)
          : const Color.fromRGBO(11, 47, 99, 0.10),
      signInWashStart: const Color.fromRGBO(8, 37, 79, 0.94),
      signInWashMid: const Color.fromRGBO(11, 47, 99, 0.80),
      signInWashEnd: const Color.fromRGBO(18, 63, 122, 0.45),
      statusBar: dark ? RopColors.canvasDark : RopColors.blue1000,
    );
  }

  final Color textPrimary;
  final Color textSecondary;
  final Color textLink;
  final Color textOnPrimary;
  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color separator;
  final Color separatorSubtle;
  final Color primaryButton;
  final Color primaryButtonHover;
  final Color primaryButtonPressed;
  final Color focusRing;
  final Color infoBadge;
  final Color warningSurface;
  final Color warningText;
  final Color critical;
  final Color criticalButton;
  final Color railStart;
  final Color railEnd;
  final Color railText;
  final Color railActiveMarker;
  final Color ownBubble;
  final Color ownBubbleText;
  final Color otherBubble;
  final Color otherBubbleText;
  final Color selectionTint;
  final Color hoverTint;
  final Color sendGradientStart;
  final Color sendGradientEnd;
  final Color pageWashStart;
  final Color pageWashEnd;
  final Color fortWashStart;
  final Color fortWashEnd;
  final Color chatWash;
  final Color homeCard;
  final Color signInCard;
  final Color signInCardBorder;
  final Color cardShadow;
  final Color bubbleShadow;
  final Color signInWashStart;
  final Color signInWashMid;
  final Color signInWashEnd;
  final Color statusBar;

  static RopTheme of(BuildContext context) {
    return Theme.of(context).extension<RopTheme>() ??
        RopTheme.fromBrightness(Theme.of(context).brightness);
  }

  @override
  RopTheme copyWith({
    Color? textPrimary,
    Color? textSecondary,
    Color? textLink,
    Color? textOnPrimary,
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? separator,
    Color? separatorSubtle,
    Color? primaryButton,
    Color? primaryButtonHover,
    Color? primaryButtonPressed,
    Color? focusRing,
    Color? infoBadge,
    Color? warningSurface,
    Color? warningText,
    Color? critical,
    Color? criticalButton,
    Color? railStart,
    Color? railEnd,
    Color? railText,
    Color? railActiveMarker,
    Color? ownBubble,
    Color? ownBubbleText,
    Color? otherBubble,
    Color? otherBubbleText,
    Color? selectionTint,
    Color? hoverTint,
    Color? sendGradientStart,
    Color? sendGradientEnd,
    Color? pageWashStart,
    Color? pageWashEnd,
    Color? fortWashStart,
    Color? fortWashEnd,
    Color? chatWash,
    Color? homeCard,
    Color? signInCard,
    Color? signInCardBorder,
    Color? cardShadow,
    Color? bubbleShadow,
    Color? signInWashStart,
    Color? signInWashMid,
    Color? signInWashEnd,
    Color? statusBar,
  }) {
    return RopTheme(
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textLink: textLink ?? this.textLink,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      separator: separator ?? this.separator,
      separatorSubtle: separatorSubtle ?? this.separatorSubtle,
      primaryButton: primaryButton ?? this.primaryButton,
      primaryButtonHover: primaryButtonHover ?? this.primaryButtonHover,
      primaryButtonPressed: primaryButtonPressed ?? this.primaryButtonPressed,
      focusRing: focusRing ?? this.focusRing,
      infoBadge: infoBadge ?? this.infoBadge,
      warningSurface: warningSurface ?? this.warningSurface,
      warningText: warningText ?? this.warningText,
      critical: critical ?? this.critical,
      criticalButton: criticalButton ?? this.criticalButton,
      railStart: railStart ?? this.railStart,
      railEnd: railEnd ?? this.railEnd,
      railText: railText ?? this.railText,
      railActiveMarker: railActiveMarker ?? this.railActiveMarker,
      ownBubble: ownBubble ?? this.ownBubble,
      ownBubbleText: ownBubbleText ?? this.ownBubbleText,
      otherBubble: otherBubble ?? this.otherBubble,
      otherBubbleText: otherBubbleText ?? this.otherBubbleText,
      selectionTint: selectionTint ?? this.selectionTint,
      hoverTint: hoverTint ?? this.hoverTint,
      sendGradientStart: sendGradientStart ?? this.sendGradientStart,
      sendGradientEnd: sendGradientEnd ?? this.sendGradientEnd,
      pageWashStart: pageWashStart ?? this.pageWashStart,
      pageWashEnd: pageWashEnd ?? this.pageWashEnd,
      fortWashStart: fortWashStart ?? this.fortWashStart,
      fortWashEnd: fortWashEnd ?? this.fortWashEnd,
      chatWash: chatWash ?? this.chatWash,
      homeCard: homeCard ?? this.homeCard,
      signInCard: signInCard ?? this.signInCard,
      signInCardBorder: signInCardBorder ?? this.signInCardBorder,
      cardShadow: cardShadow ?? this.cardShadow,
      bubbleShadow: bubbleShadow ?? this.bubbleShadow,
      signInWashStart: signInWashStart ?? this.signInWashStart,
      signInWashMid: signInWashMid ?? this.signInWashMid,
      signInWashEnd: signInWashEnd ?? this.signInWashEnd,
      statusBar: statusBar ?? this.statusBar,
    );
  }

  @override
  RopTheme lerp(ThemeExtension<RopTheme>? other, double t) {
    if (other is! RopTheme) {
      return this;
    }
    return RopTheme(
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textLink: Color.lerp(textLink, other.textLink, t)!,
      textOnPrimary: Color.lerp(textOnPrimary, other.textOnPrimary, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      separator: Color.lerp(separator, other.separator, t)!,
      separatorSubtle: Color.lerp(separatorSubtle, other.separatorSubtle, t)!,
      primaryButton: Color.lerp(primaryButton, other.primaryButton, t)!,
      primaryButtonHover: Color.lerp(
        primaryButtonHover,
        other.primaryButtonHover,
        t,
      )!,
      primaryButtonPressed: Color.lerp(
        primaryButtonPressed,
        other.primaryButtonPressed,
        t,
      )!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      infoBadge: Color.lerp(infoBadge, other.infoBadge, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      critical: Color.lerp(critical, other.critical, t)!,
      criticalButton: Color.lerp(criticalButton, other.criticalButton, t)!,
      railStart: Color.lerp(railStart, other.railStart, t)!,
      railEnd: Color.lerp(railEnd, other.railEnd, t)!,
      railText: Color.lerp(railText, other.railText, t)!,
      railActiveMarker: Color.lerp(
        railActiveMarker,
        other.railActiveMarker,
        t,
      )!,
      ownBubble: Color.lerp(ownBubble, other.ownBubble, t)!,
      ownBubbleText: Color.lerp(ownBubbleText, other.ownBubbleText, t)!,
      otherBubble: Color.lerp(otherBubble, other.otherBubble, t)!,
      otherBubbleText: Color.lerp(otherBubbleText, other.otherBubbleText, t)!,
      selectionTint: Color.lerp(selectionTint, other.selectionTint, t)!,
      hoverTint: Color.lerp(hoverTint, other.hoverTint, t)!,
      sendGradientStart: Color.lerp(
        sendGradientStart,
        other.sendGradientStart,
        t,
      )!,
      sendGradientEnd: Color.lerp(sendGradientEnd, other.sendGradientEnd, t)!,
      pageWashStart: Color.lerp(pageWashStart, other.pageWashStart, t)!,
      pageWashEnd: Color.lerp(pageWashEnd, other.pageWashEnd, t)!,
      fortWashStart: Color.lerp(fortWashStart, other.fortWashStart, t)!,
      fortWashEnd: Color.lerp(fortWashEnd, other.fortWashEnd, t)!,
      chatWash: Color.lerp(chatWash, other.chatWash, t)!,
      homeCard: Color.lerp(homeCard, other.homeCard, t)!,
      signInCard: Color.lerp(signInCard, other.signInCard, t)!,
      signInCardBorder: Color.lerp(
        signInCardBorder,
        other.signInCardBorder,
        t,
      )!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      bubbleShadow: Color.lerp(bubbleShadow, other.bubbleShadow, t)!,
      signInWashStart: Color.lerp(signInWashStart, other.signInWashStart, t)!,
      signInWashMid: Color.lerp(signInWashMid, other.signInWashMid, t)!,
      signInWashEnd: Color.lerp(signInWashEnd, other.signInWashEnd, t)!,
      statusBar: Color.lerp(statusBar, other.statusBar, t)!,
    );
  }
}
