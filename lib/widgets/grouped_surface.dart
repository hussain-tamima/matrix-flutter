import 'package:element_x/theme/rop_spacing.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:flutter/material.dart';

/// One related group of rows on the page surface.
class GroupedSurface extends StatelessWidget {
  const GroupedSurface({
    super.key,
    required this.children,
    this.dividerStart = RopSpacing.md,
  });

  final List<Widget> children;
  final double dividerStart;

  @override
  Widget build(BuildContext context) {
    final rop = RopTheme.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          Padding(
            padding: EdgeInsetsDirectional.only(start: dividerStart),
            child: Divider(height: 1, thickness: 1, color: rop.separatorSubtle),
          ),
        );
      }
      rows.add(children[i]);
    }
    return Material(
      color: rop.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RopSpacing.cardRadius),
        side: BorderSide(color: rop.separatorSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }
}
