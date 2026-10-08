import 'package:element_x/theme/rop_spacing.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:flutter/material.dart';

/// Inline failure the user can act on. Announced when it appears.
class FormNotice extends StatelessWidget {
  const FormNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final rop = RopTheme.of(context);
    final text = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: rop.critical, height: 1.35);
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: rop.critical.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(RopSpacing.controlRadius),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            RopSpacing.sm,
            RopSpacing.sm,
            RopSpacing.md,
            RopSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(Icons.error_outline, color: rop.critical, size: 22),
              ),
              const SizedBox(width: RopSpacing.sm),
              Expanded(child: Text(message, style: text)),
            ],
          ),
        ),
      ),
    );
  }
}
