import 'package:easy_localization/easy_localization.dart';
import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/core/utils/test_keys.dart';
import 'package:element_x/features/login/cubit/login_cubit.dart';
import 'package:element_x/theme/rop_assets.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:element_x/widgets/ltr_brand_image.dart';
import 'package:element_x/widgets/rop_crest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginPasswordScreen extends StatefulWidget {
  const LoginPasswordScreen({super.key});

  @override
  State<LoginPasswordScreen> createState() => _LoginPasswordScreenState();
}

class _LoginPasswordScreenState extends State<LoginPasswordScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rop = RopTheme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('sign_in'.tr())),
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
          BlocBuilder<LoginCubit, LoginState>(
            builder: (context, state) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
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
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const RopCrest(size: 56),
                              const SizedBox(height: 16),
                              Text('Server ${state.homeserver}'),
                              const SizedBox(height: 16),
                              TextField(
                                key: const Key(TestKeys.username),
                                controller: _username,
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  errorText: state.usernameError,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                key: const Key(TestKeys.password),
                                controller: _password,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  errorText: state.passwordError,
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  key: const Key(TestKeys.loginSubmit),
                                  onPressed: state.submitting
                                      ? null
                                      : () async {
                                          final opened = await context
                                              .read<LoginCubit>()
                                              .login(
                                                username: _username.text,
                                                password: _password.text,
                                              );
                                          if (opened && context.mounted) {
                                            context.go(RoutePaths.home);
                                          }
                                        },
                                  child: Text('sign_in'.tr()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
