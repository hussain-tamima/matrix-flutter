import 'package:easy_localization/easy_localization.dart';
import 'package:element_x/core/config/app_config.dart';
import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/core/utils/test_keys.dart';
import 'package:element_x/theme/rop_assets.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:element_x/widgets/app_preference_controls.dart';
import 'package:element_x/widgets/ltr_brand_image.dart';
import 'package:element_x/widgets/rop_crest.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rop = RopTheme.of(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LtrBrandImage(asset: RopAssets.academy, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: [
                  rop.signInWashStart,
                  rop.signInWashMid,
                  rop.signInWashEnd,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: AppPreferenceControls(compact: true),
                  ),
                  const LtrBrandImage(
                    asset: RopAssets.wordmarkWhite,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: rop.signInCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: rop.signInCardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: rop.cardShadow,
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const RopCrest(size: 56),
                                const SizedBox(height: 16),
                                Text(
                                  'app_name'.tr(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: rop.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'tagline'.tr(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: rop.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                _FeatureLine(text: 'feature_e2ee'.tr()),
                                _FeatureLine(text: 'feature_calls'.tr()),
                                _FeatureLine(text: 'feature_devices'.tr()),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    key: const Key(TestKeys.signIn),
                                    onPressed: () =>
                                        context.push(RoutePaths.loginPassword),
                                    child: Text('sign_in'.tr()),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      context.push(RoutePaths.loginQr),
                                  child: Text('sign_in_qr'.tr()),
                                ),
                                const SizedBox(height: 8),
                                const LtrBrandImage(
                                  asset: RopAssets.eko,
                                  height: 22,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _open(AppConfig.footerRopUrl),
                    child: Text(
                      'footer_rop'.tr(),
                      style: TextStyle(color: rop.textOnPrimary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _open(AppConfig.footerPartnerUrl),
                    child: Text(
                      'footer_partner'.tr(),
                      style: TextStyle(color: rop.textOnPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final rop = RopTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: rop.textLink),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: rop.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
