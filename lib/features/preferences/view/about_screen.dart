import 'package:easy_localization/easy_localization.dart';
import 'package:element_x/core/config/app_config.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:element_x/widgets/rop_crest.dart';
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rop = RopTheme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(child: RopCrest(size: 72)),
          const SizedBox(height: 16),
          Text(
            AppConfig.appName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'tagline'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: rop.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text('Version 1.0.0', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
