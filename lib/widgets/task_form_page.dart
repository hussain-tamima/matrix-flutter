import 'package:element_x/theme/rop_spacing.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:flutter/material.dart';

/// A short task: scrollable fields, with the commit action in the thumb zone.
class TaskFormPage extends StatelessWidget {
  const TaskFormPage({
    super.key,
    required this.title,
    required this.children,
    required this.actionLabel,
    required this.onAction,
    this.busy = false,
    this.notice,
  });

  final String title;
  final List<Widget> children;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool busy;
  final Widget? notice;

  @override
  Widget build(BuildContext context) {
    final rop = RopTheme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: RopSpacing.contentMaxWidth,
                ),
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    RopSpacing.md,
                    RopSpacing.lg,
                    RopSpacing.md,
                    RopSpacing.lg,
                  ),
                  children: children,
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: rop.canvas,
              border: Border(top: BorderSide(color: rop.separatorSubtle)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  RopSpacing.md,
                  RopSpacing.sm,
                  RopSpacing.md,
                  RopSpacing.sm,
                ),
                child: Align(
                  alignment: AlignmentDirectional.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: RopSpacing.contentMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (notice != null) ...[
                          notice!,
                          const SizedBox(height: RopSpacing.sm),
                        ],
                        FilledButton(
                          onPressed: onAction == null
                              ? null
                              : () {
                                  if (!busy) onAction!();
                                },
                          child: busy
                              ? _BusyLabel(label: actionLabel)
                              : Text(actionLabel),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusyLabel extends StatelessWidget {
  const _BusyLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final rop = RopTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: rop.textOnPrimary,
          ),
        ),
        const SizedBox(width: RopSpacing.sm),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
