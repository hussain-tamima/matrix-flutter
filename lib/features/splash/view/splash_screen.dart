import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:element_x/features/splash/cubit/splash_cubit.dart';
import 'package:element_x/theme/rop_assets.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:element_x/widgets/rop_crest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  var _precacheStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precacheStarted) {
      return;
    }
    _precacheStarted = true;
    unawaited(
      Future.wait([
        precacheImage(const AssetImage(RopAssets.homeGlass), context),
        precacheImage(const AssetImage(RopAssets.chatPattern), context),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rop = RopTheme.of(context);
    return BlocListener<SplashCubit, SplashState>(
      listenWhen: (previous, current) =>
          current.route != null && previous.route != current.route,
      listener: (context, state) => context.go(state.route!),
      child: Scaffold(
        backgroundColor: rop.railStart,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const RopCrest(size: 72),
              const SizedBox(height: 16),
              Text(
                'app_name'.tr(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: rop.textOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'short_tagline'.tr(),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: rop.railText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
