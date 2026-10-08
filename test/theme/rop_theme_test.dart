import 'package:element_x/theme/app_theme.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ROP themes expose complete semantic roles', () {
    final light = RopTheme.fromBrightness(Brightness.light);
    final dark = RopTheme.fromBrightness(Brightness.dark);

    expect(light.homeCard.a, greaterThan(0.85));
    expect(light.warningSurface, isNot(light.critical));
    expect(dark.canvas, isNot(light.canvas));
    expect(dark.warningText, isNot(dark.warningSurface));
  });

  test('Material themes use ROP component styling', () {
    final light = AppTheme.light(useInter: false);
    final dark = AppTheme.dark(useInter: false);

    expect(light.useMaterial3, isTrue);
    expect(light.chipTheme.selectedColor, isNotNull);
    expect(light.bottomSheetTheme.showDragHandle, isTrue);
    expect(light.navigationRailTheme.backgroundColor, isNotNull);
    expect(dark.colorScheme.brightness, Brightness.dark);
  });
}
