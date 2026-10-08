import 'package:element_x/theme/rop_assets.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:element_x/widgets/ltr_brand_image.dart';
import 'package:flutter/material.dart';

class RopCrest extends StatelessWidget {
  const RopCrest({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final rop = RopTheme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: rop.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.14),
      child: LtrBrandImage(asset: RopAssets.logo, fit: BoxFit.contain),
    );
  }
}
