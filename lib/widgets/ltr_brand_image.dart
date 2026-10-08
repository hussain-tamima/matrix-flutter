import 'package:flutter/material.dart';

/// Brand marks must not mirror in RTL.
class LtrBrandImage extends StatelessWidget {
  const LtrBrandImage({
    super.key,
    required this.asset,
    this.height,
    this.width,
    this.fit,
    this.alignment = Alignment.center,
  });

  final String asset;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      height: height,
      width: width,
      fit: fit,
      alignment: alignment,
      matchTextDirection: false,
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: fit == BoxFit.cover && width == null && height == null
          ? SizedBox.expand(child: image)
          : image,
    );
  }
}
