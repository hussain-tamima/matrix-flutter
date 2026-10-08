import 'package:flutter/material.dart';
import 'package:element_x/theme/rop_spacing.dart';

class SectionScreen extends StatelessWidget {
  const SectionScreen({
    super.key,
    required this.title,
    required this.children,
    this.actions = const [],
    this.floatingActionButton,
  });

  final String title;
  final List<Widget> children;
  final List<Widget> actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      floatingActionButton: floatingActionButton,
      body: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: RopSpacing.contentMaxWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: RopSpacing.md,
              vertical: RopSpacing.sm,
            ),
            children: children,
          ),
        ),
      ),
    );
  }
}
