import 'package:element_x/core/auth/session_manager.dart';
import 'package:element_x/core/di/di.dart';
import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/analytics/cubit/analytics_cubit.dart';
import 'package:element_x/features/analytics/view/analytics_settings_screen.dart';
import 'package:element_x/features/announcement/cubit/announcement_cubit.dart';
import 'package:element_x/features/cachecleaner/cubit/cachecleaner_cubit.dart';
import 'package:element_x/features/cachecleaner/view/cachecleaner_screen.dart';
import 'package:element_x/features/call/cubit/call_cubit.dart';
import 'package:element_x/features/call/view/call_screen.dart';
import 'package:element_x/features/contentscanner/cubit/contentscanner_cubit.dart';
import 'package:element_x/features/contentscanner/view/contentscanner_screen.dart';
import 'package:element_x/features/createroom/cubit/createroom_cubit.dart';
import 'package:element_x/features/createroom/view/createroom_screen.dart';
import 'package:element_x/features/deactivation/cubit/deactivation_cubit.dart';
import 'package:element_x/features/deactivation/view/deactivation_screen.dart';
import 'package:element_x/features/enterprise/cubit/enterprise_cubit.dart';
import 'package:element_x/features/enterprise/view/enterprise_screen.dart';
import 'package:element_x/features/forward/cubit/forward_cubit.dart';
import 'package:element_x/features/forward/view/forward_screen.dart';
import 'package:element_x/features/ftue/cubit/ftue_cubit.dart';
import 'package:element_x/features/ftue/view/ftue_screen.dart';
import 'package:element_x/features/home/cubit/home_cubit.dart';
import 'package:element_x/features/home/view/home_screen.dart';
import 'package:element_x/features/home/view/home_search_screen.dart';
import 'package:element_x/features/invite/cubit/invite_cubit.dart';
import 'package:element_x/features/invite/view/invite_screen.dart';
import 'package:element_x/features/invitepeople/cubit/invitepeople_cubit.dart';
import 'package:element_x/features/invitepeople/view/invitepeople_screen.dart';
import 'package:element_x/features/joinroom/cubit/joinroom_cubit.dart';
import 'package:element_x/features/joinroom/view/joinroom_screen.dart';
import 'package:element_x/features/knockrequests/cubit/knockrequests_cubit.dart';
import 'package:element_x/features/knockrequests/view/knockrequests_screen.dart';
import 'package:element_x/features/leaveroom/cubit/leaveroom_cubit.dart';
import 'package:element_x/features/leaveroom/view/leaveroom_screen.dart';
import 'package:element_x/features/licenses/cubit/licenses_cubit.dart';
import 'package:element_x/features/licenses/view/licenses_screen.dart';
import 'package:element_x/features/linknewdevice/cubit/linknewdevice_cubit.dart';
import 'package:element_x/features/linknewdevice/view/linknewdevice_screen.dart';
import 'package:element_x/features/linknewdevice/view/linknewdevice_sign_in_qr_screen.dart';
import 'package:element_x/features/location/cubit/location_cubit.dart';
import 'package:element_x/features/location/view/location_screen.dart';
import 'package:element_x/features/lockscreen/cubit/lockscreen_cubit.dart';
import 'package:element_x/features/lockscreen/view/lockscreen_screen.dart';
import 'package:element_x/features/login/cubit/login_cubit.dart';
import 'package:element_x/features/login/view/choose_account_provider_screen.dart';
import 'package:element_x/features/login/view/confirm_account_provider_screen.dart';
import 'package:element_x/features/login/view/create_account_screen.dart';
import 'package:element_x/features/login/view/login_password_screen.dart';
import 'package:element_x/features/login/view/onboarding_screen.dart';
import 'package:element_x/features/login/view/qr_login_screen.dart';
import 'package:element_x/features/logout/cubit/logout_cubit.dart';
import 'package:element_x/features/logout/view/logout_screen.dart';
import 'package:element_x/features/messages/cubit/messages_cubit.dart';
import 'package:element_x/features/messages/cubit/pins_cubit.dart';
import 'package:element_x/features/messages/cubit/thread_cubit.dart';
import 'package:element_x/features/messages/view/messages_screen.dart';
import 'package:element_x/features/messages/view/pins_screen.dart';
import 'package:element_x/features/messages/view/thread_screen.dart';
import 'package:element_x/features/migration/cubit/migration_cubit.dart';
import 'package:element_x/features/migration/view/migration_screen.dart';
import 'package:element_x/features/networkmonitor/cubit/networkmonitor_cubit.dart';
import 'package:element_x/features/networkmonitor/view/networkmonitor_screen.dart';
import 'package:element_x/features/poll/cubit/poll_cubit.dart';
import 'package:element_x/features/poll/view/poll_screen.dart';
import 'package:element_x/features/preferences/cubit/preferences_cubit.dart';
import 'package:element_x/features/preferences/view/about_screen.dart';
import 'package:element_x/features/preferences/view/account_settings_screen.dart';
import 'package:element_x/features/preferences/view/blocked_users_screen.dart';
import 'package:element_x/features/preferences/view/developer_settings_screen.dart';
import 'package:element_x/features/preferences/view/labs_settings_screen.dart';
import 'package:element_x/features/preferences/view/location_settings_screen.dart';
import 'package:element_x/features/preferences/view/media_settings_screen.dart';
import 'package:element_x/features/preferences/view/moderation_settings_screen.dart';
import 'package:element_x/features/preferences/view/notification_settings_screen.dart';
import 'package:element_x/features/preferences/view/settings_screen.dart';
import 'package:element_x/features/rageshake/cubit/rageshake_cubit.dart';
import 'package:element_x/features/rageshake/view/rageshake_screen.dart';
import 'package:element_x/features/reportroom/cubit/reportroom_cubit.dart';
import 'package:element_x/features/reportroom/view/reportroom_screen.dart';
import 'package:element_x/features/rolesandpermissions/cubit/rolesandpermissions_cubit.dart';
import 'package:element_x/features/rolesandpermissions/view/rolesandpermissions_screen.dart';
import 'package:element_x/features/roomaliasresolver/cubit/roomaliasresolver_cubit.dart';
import 'package:element_x/features/roomaliasresolver/view/roomaliasresolver_screen.dart';
import 'package:element_x/features/roomcall/cubit/roomcall_cubit.dart';
import 'package:element_x/features/roomcall/view/roomcall_screen.dart';
import 'package:element_x/features/roomdetails/cubit/roomdetails_cubit.dart';
import 'package:element_x/features/roomdetails/view/room_notification_screen.dart';
import 'package:element_x/features/roomdetails/view/roomdetails_screen.dart';
import 'package:element_x/features/roomdetailsedit/cubit/roomdetailsedit_cubit.dart';
import 'package:element_x/features/roomdetailsedit/view/roomdetailsedit_screen.dart';
import 'package:element_x/features/roomdirectory/cubit/roomdirectory_cubit.dart';
import 'package:element_x/features/roomdirectory/view/roomdirectory_screen.dart';
import 'package:element_x/features/roommembermoderation/cubit/roommembermoderation_cubit.dart';
import 'package:element_x/features/roommembermoderation/view/roommembermoderation_screen.dart';
import 'package:element_x/features/securebackup/cubit/securebackup_cubit.dart';
import 'package:element_x/features/securebackup/view/securebackup_screen.dart';
import 'package:element_x/features/securityandprivacy/cubit/securityandprivacy_cubit.dart';
import 'package:element_x/features/securityandprivacy/view/securityandprivacy_screen.dart';
import 'package:element_x/features/share/cubit/share_cubit.dart';
import 'package:element_x/features/share/view/share_screen.dart';
import 'package:element_x/features/signedout/cubit/signedout_cubit.dart';
import 'package:element_x/features/signedout/view/signedout_screen.dart';
import 'package:element_x/features/space/cubit/space_cubit.dart';
import 'package:element_x/features/space/view/space_screen.dart';
import 'package:element_x/features/splash/cubit/splash_cubit.dart';
import 'package:element_x/features/splash/view/splash_screen.dart';
import 'package:element_x/features/startchat/cubit/startchat_cubit.dart';
import 'package:element_x/features/startchat/view/startchat_screen.dart';
import 'package:element_x/features/userprofile/cubit/userprofile_cubit.dart';
import 'package:element_x/features/userprofile/view/userprofile_screen.dart';
import 'package:element_x/features/verifysession/cubit/verifysession_cubit.dart';
import 'package:element_x/features/verifysession/view/verifysession_screen.dart';
import 'package:element_x/features/viewfolder/cubit/viewfolder_cubit.dart';
import 'package:element_x/features/viewfolder/view/viewfolder_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

GoRouter buildRouter(SessionManager session) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: session,
    redirect: (context, state) => _redirect(session, state.matchedLocation),
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) =>
            _bloc(() => sl<SplashCubit>()..decide(), const SplashScreen()),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => _login(const OnboardingScreen()),
      ),
      GoRoute(
        path: RoutePaths.loginProvider,
        builder: (context, state) =>
            _login(const ChooseAccountProviderScreen()),
      ),
      GoRoute(
        path: RoutePaths.loginConfirm,
        builder: (context, state) =>
            _login(const ConfirmAccountProviderScreen()),
      ),
      GoRoute(
        path: RoutePaths.loginPassword,
        builder: (context, state) => _login(const LoginPasswordScreen()),
      ),
      GoRoute(
        path: RoutePaths.loginQr,
        builder: (context, state) => _login(const QrLoginScreen()),
      ),
      GoRoute(
        path: RoutePaths.createAccount,
        builder: (context, state) => _login(const CreateAccountScreen()),
      ),
      GoRoute(
        path: RoutePaths.signedOut,
        builder: (context, state) =>
            _bloc(() => sl<SignedOutCubit>(), const SignedOutScreen()),
      ),
      GoRoute(
        path: RoutePaths.lock,
        builder: (context, state) =>
            _bloc(() => sl<LockscreenCubit>(), const LockscreenScreen()),
      ),
      GoRoute(
        path: RoutePaths.ftue,
        builder: (context, state) =>
            _bloc(() => sl<FtueCubit>(), const FtueScreen()),
      ),
      GoRoute(
        path: RoutePaths.migration,
        builder: (context, state) =>
            _bloc(() => sl<MigrationCubit>(), const MigrationScreen()),
      ),
      GoRoute(
        path: RoutePaths.linkDevice,
        builder: (context, state) =>
            _bloc(() => sl<LinkNewDeviceCubit>(), const LinkNewDeviceScreen()),
      ),
      GoRoute(
        path: RoutePaths.linkDeviceSignInQr,
        builder: (context, state) => const LinkNewDeviceSignInQrScreen(),
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<HomeCubit>()),
            BlocProvider(create: (_) => sl<AnnouncementCubit>()),
          ],
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.homeSearch,
        builder: (context, state) =>
            _bloc(() => sl<HomeCubit>(), const HomeSearchScreen()),
      ),
      GoRoute(
        path: RoutePaths.startChat,
        builder: (context, state) =>
            _bloc(() => sl<StartChatCubit>(), const StartChatScreen()),
      ),
      GoRoute(
        path: RoutePaths.createRoom,
        builder: (context, state) =>
            _bloc(() => sl<CreateRoomCubit>(), const CreateRoomScreen()),
      ),
      GoRoute(
        path: RoutePaths.joinRoom,
        builder: (context, state) => _bloc(
          () => sl<JoinRoomCubit>(),
          JoinRoomScreen(
            initialAddress: state.extra is String
                ? state.extra as String
                : null,
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.directory,
        builder: (context, state) =>
            _bloc(() => sl<RoomDirectoryCubit>(), const RoomDirectoryScreen()),
      ),
      GoRoute(
        path: RoutePaths.resolveAlias,
        builder: (context, state) => _bloc(
          () => sl<RoomAliasResolverCubit>(),
          const RoomAliasResolverScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.secureBackup,
        builder: (context, state) =>
            _bloc(() => sl<SecureBackupCubit>(), const SecureBackupScreen()),
      ),
      GoRoute(
        path: RoutePaths.verify,
        builder: (context, state) =>
            _bloc(() => sl<VerifySessionCubit>(), const VerifySessionScreen()),
      ),
      GoRoute(
        path: '/share',
        builder: (context, state) => _bloc(
          () => sl<ShareCubit>(param1: state.uri.queryParameters['text'] ?? ''),
          const ShareScreen(),
        ),
      ),
      GoRoute(
        path: '/forward',
        builder: (context, state) => _bloc(
          () => sl<ForwardCubit>(
            param1: state.uri.queryParameters['roomId'] ?? '',
            param2: state.uri.queryParameters['eventId'] ?? '',
          ),
          const ForwardScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.bugReport,
        builder: (context, state) =>
            _bloc(() => sl<RageshakeCubit>(), const RageshakeScreen()),
      ),
      GoRoute(
        path: RoutePaths.licenses,
        builder: (context, state) =>
            _bloc(() => sl<LicensesCubit>(), const LicensesScreen()),
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.settingsAccount,
        builder: (context, state) => _prefs(const AccountSettingsScreen()),
      ),
      GoRoute(
        path: RoutePaths.settingsNotifications,
        builder: (context, state) => _prefs(const NotificationSettingsScreen()),
      ),
      GoRoute(
        path: RoutePaths.settingsLabs,
        builder: (context, state) => _prefs(const LabsSettingsScreen()),
      ),
      GoRoute(
        path: RoutePaths.settingsDeveloper,
        builder: (context, state) => _prefs(const DeveloperSettingsScreen()),
      ),
      GoRoute(
        path: RoutePaths.settingsBlocked,
        builder: (context, state) => _prefs(const BlockedUsersScreen()),
      ),
      GoRoute(
        path: RoutePaths.settingsAnalytics,
        builder: (context, state) =>
            _bloc(() => sl<AnalyticsCubit>(), const AnalyticsSettingsScreen()),
      ),
      GoRoute(
        path: RoutePaths.settingsAbout,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: RoutePaths.settingsMedia,
        builder: (context, state) => _prefs(const MediaSettingsScreen()),
      ),
      GoRoute(
        path: RoutePaths.settingsLocation,
        builder: (context, state) => _prefs(const LocationSettingsScreen()),
      ),
      GoRoute(
        path: RoutePaths.settingsModeration,
        builder: (context, state) => const ModerationSettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.settingsSecurity,
        builder: (context, state) => _bloc(
          () => sl<SecurityAndPrivacyCubit>(),
          const SecurityAndPrivacyScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.settingsDeactivate,
        builder: (context, state) =>
            _bloc(() => sl<DeactivationCubit>(), const DeactivationScreen()),
      ),
      GoRoute(
        path: RoutePaths.settingsCache,
        builder: (context, state) =>
            _bloc(() => sl<CacheCleanerCubit>(), const CacheCleanerScreen()),
      ),
      GoRoute(
        path: RoutePaths.settingsScanner,
        builder: (context, state) => _bloc(
          () => sl<ContentScannerCubit>(),
          const ContentScannerScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.settingsEnterprise,
        builder: (context, state) =>
            _bloc(() => sl<EnterpriseCubit>(), const EnterpriseScreen()),
      ),
      GoRoute(
        path: RoutePaths.network,
        builder: (context, state) => _bloc(
          () => sl<NetworkMonitorCubit>(),
          const NetworkMonitorScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.call,
        builder: (context, state) =>
            _bloc(() => sl<CallCubit>(), const CallScreen()),
      ),
      GoRoute(
        path: RoutePaths.logout,
        builder: (context, state) =>
            _bloc(() => sl<LogoutCubit>(), const LogoutScreen()),
      ),
      GoRoute(
        path: '/users/:userId',
        builder: (context, state) => _bloc(
          () => sl<UserProfileCubit>(param1: state.pathParameters['userId']!),
          const UserProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/spaces/:spaceId',
        builder: (context, state) => _bloc(
          () => sl<SpaceCubit>(param1: state.pathParameters['spaceId']!),
          const SpaceScreen(),
        ),
      ),
      GoRoute(
        path: '/rooms/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return _bloc(
            () => sl<MessagesCubit>(param1: roomId),
            MessagesScreen(roomId: roomId),
          );
        },
        routes: [
          GoRoute(
            path: 'details',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId']!;
              return _bloc(
                () => sl<RoomDetailsCubit>(param1: roomId),
                RoomDetailsScreen(roomId: roomId),
              );
            },
          ),
          GoRoute(
            path: 'edit',
            builder: (context, state) => _bloc(
              () => sl<RoomDetailsEditCubit>(
                param1: state.pathParameters['roomId']!,
              ),
              const RoomDetailsEditScreen(),
            ),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => _bloc(
              () =>
                  sl<RoomDetailsCubit>(param1: state.pathParameters['roomId']!),
              const RoomNotificationScreen(),
            ),
          ),
          GoRoute(
            path: 'roles',
            builder: (context, state) => _bloc(
              () => sl<RolesAndPermissionsCubit>(
                param1: state.pathParameters['roomId']!,
              ),
              const RolesAndPermissionsScreen(),
            ),
          ),
          GoRoute(
            path: 'report',
            builder: (context, state) => _bloc(
              () =>
                  sl<ReportRoomCubit>(param1: state.pathParameters['roomId']!),
              const ReportRoomScreen(),
            ),
          ),
          GoRoute(
            path: 'leave',
            builder: (context, state) => _bloc(
              () => sl<LeaveRoomCubit>(param1: state.pathParameters['roomId']!),
              const LeaveRoomScreen(),
            ),
          ),
          GoRoute(
            path: 'pins',
            builder: (context, state) => _bloc(
              () => sl<PinsCubit>(param1: state.pathParameters['roomId']!),
              const PinsScreen(),
            ),
          ),
          GoRoute(
            path: 'files',
            builder: (context, state) => _bloc(
              () =>
                  sl<ViewFolderCubit>(param1: state.pathParameters['roomId']!),
              const ViewFolderScreen(),
            ),
          ),
          GoRoute(
            path: 'invite',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId']!;
              return _bloc(
                () => sl<InviteCubit>(param1: roomId),
                InviteScreen(roomId: roomId),
              );
            },
          ),
          GoRoute(
            path: 'people',
            builder: (context, state) => _bloc(
              () => sl<InvitePeopleCubit>(
                param1: state.pathParameters['roomId']!,
              ),
              const InvitePeopleScreen(),
            ),
          ),
          GoRoute(
            path: 'knocks',
            builder: (context, state) => _bloc(
              () => sl<KnockRequestsCubit>(
                param1: state.pathParameters['roomId']!,
              ),
              const KnockRequestsScreen(),
            ),
          ),
          GoRoute(
            path: 'call',
            builder: (context, state) => _bloc(
              () => sl<RoomCallCubit>(param1: state.pathParameters['roomId']!),
              const RoomCallScreen(),
            ),
          ),
          GoRoute(
            path: 'location',
            builder: (context, state) => _bloc(
              () => sl<LocationCubit>(param1: state.pathParameters['roomId']!),
              const LocationScreen(),
            ),
          ),
          GoRoute(
            path: 'poll',
            builder: (context, state) => _bloc(
              () => sl<PollCubit>(param1: state.pathParameters['roomId']!),
              const PollScreen(),
            ),
          ),
          GoRoute(
            path: 'threads/:eventId',
            builder: (context, state) => _bloc(
              () => sl<ThreadCubit>(
                param1: state.pathParameters['roomId']!,
                param2: state.pathParameters['eventId']!,
              ),
              const ThreadScreen(),
            ),
          ),
          GoRoute(
            path: 'moderate/:userId',
            builder: (context, state) => _bloc(
              () => sl<RoomMemberModerationCubit>(
                param1: state.pathParameters['roomId']!,
                param2: state.pathParameters['userId']!,
              ),
              const RoomMemberModerationScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

String? _redirect(SessionManager session, String location) {
  final loggedIn = session.isLoggedIn;
  final isPublic =
      location == RoutePaths.splash ||
      location == RoutePaths.signedOut ||
      location == RoutePaths.logout ||
      location == RoutePaths.migration ||
      location == RoutePaths.bugReport ||
      location.startsWith('/login');

  if (!loggedIn) {
    return isPublic ? null : RoutePaths.login;
  }

  final locked = session.lockEnabled && !session.unlocked;
  if (locked && location != RoutePaths.lock && location != RoutePaths.splash) {
    return RoutePaths.lock;
  }
  if (!locked && location == RoutePaths.lock) {
    return RoutePaths.home;
  }
  if (location.startsWith('/login') || location == RoutePaths.signedOut) {
    return RoutePaths.home;
  }
  return null;
}

Widget _login(Widget child) {
  return BlocProvider.value(value: sl<LoginCubit>(), child: child);
}

Widget _prefs(Widget child) {
  return BlocProvider(create: (_) => sl<PreferencesCubit>(), child: child);
}

Widget _bloc<C extends StateStreamableSource<Object?>>(
  C Function() create,
  Widget child,
) {
  return BlocProvider<C>(create: (_) => create(), child: child);
}
