import 'package:dio/dio.dart';
import 'package:element_x/core/auth/session_manager.dart';
import 'package:element_x/core/config/app_config.dart';
import 'package:element_x/core/local_storage/hive_boxes.dart';
import 'package:element_x/core/local_storage/session_store.dart';
import 'package:element_x/core/matrix/matrix_database.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/network/api_client.dart';
import 'package:element_x/core/network/dio_config.dart';
import 'package:element_x/core/network/interceptors/auth_interceptor.dart';
import 'package:element_x/core/qr_login/qr_login_service.dart';
import 'package:element_x/features/push/repo/push_repo.dart';
import 'package:element_x/features/push/repo/push_repo_impl.dart';
import 'package:element_x/core/routes/app_router.dart';
import 'package:element_x/core/settings/app_settings_cubit.dart';
import 'package:element_x/features/analytics/cubit/analytics_cubit.dart';
import 'package:element_x/features/analytics/repo/analytics_repo.dart';
import 'package:element_x/features/analytics/repo/analytics_repo_impl.dart';
import 'package:element_x/features/announcement/cubit/announcement_cubit.dart';
import 'package:element_x/features/announcement/repo/announcement_repo.dart';
import 'package:element_x/features/announcement/repo/announcement_repo_impl.dart';
import 'package:element_x/features/cachecleaner/cubit/cachecleaner_cubit.dart';
import 'package:element_x/features/cachecleaner/repo/cachecleaner_repo.dart';
import 'package:element_x/features/cachecleaner/repo/cachecleaner_repo_impl.dart';
import 'package:element_x/features/call/cubit/call_cubit.dart';
import 'package:element_x/features/call/repo/call_repo.dart';
import 'package:element_x/features/call/repo/call_repo_impl.dart';
import 'package:element_x/features/contentscanner/cubit/contentscanner_cubit.dart';
import 'package:element_x/features/contentscanner/repo/contentscanner_repo.dart';
import 'package:element_x/features/contentscanner/repo/contentscanner_repo_impl.dart';
import 'package:element_x/features/createroom/cubit/createroom_cubit.dart';
import 'package:element_x/features/createroom/repo/createroom_repo.dart';
import 'package:element_x/features/createroom/repo/createroom_repo_impl.dart';
import 'package:element_x/features/deactivation/cubit/deactivation_cubit.dart';
import 'package:element_x/features/deactivation/repo/deactivation_repo.dart';
import 'package:element_x/features/deactivation/repo/deactivation_repo_impl.dart';
import 'package:element_x/features/enterprise/cubit/enterprise_cubit.dart';
import 'package:element_x/features/enterprise/repo/enterprise_repo.dart';
import 'package:element_x/features/enterprise/repo/enterprise_repo_impl.dart';
import 'package:element_x/features/forward/cubit/forward_cubit.dart';
import 'package:element_x/features/forward/repo/forward_repo.dart';
import 'package:element_x/features/forward/repo/forward_repo_impl.dart';
import 'package:element_x/features/ftue/cubit/ftue_cubit.dart';
import 'package:element_x/features/ftue/repo/ftue_repo.dart';
import 'package:element_x/features/ftue/repo/ftue_repo_impl.dart';
import 'package:element_x/features/home/cubit/home_cubit.dart';
import 'package:element_x/features/home/repo/home_repo.dart';
import 'package:element_x/features/home/repo/home_repo_impl.dart';
import 'package:element_x/features/invite/cubit/invite_cubit.dart';
import 'package:element_x/features/invite/repo/invite_repo.dart';
import 'package:element_x/features/invite/repo/invite_repo_impl.dart';
import 'package:element_x/features/invitepeople/cubit/invitepeople_cubit.dart';
import 'package:element_x/features/invitepeople/repo/invitepeople_repo.dart';
import 'package:element_x/features/invitepeople/repo/invitepeople_repo_impl.dart';
import 'package:element_x/features/joinroom/cubit/joinroom_cubit.dart';
import 'package:element_x/features/joinroom/repo/joinroom_repo.dart';
import 'package:element_x/features/joinroom/repo/joinroom_repo_impl.dart';
import 'package:element_x/features/knockrequests/cubit/knockrequests_cubit.dart';
import 'package:element_x/features/knockrequests/repo/knockrequests_repo.dart';
import 'package:element_x/features/knockrequests/repo/knockrequests_repo_impl.dart';
import 'package:element_x/features/leaveroom/cubit/leaveroom_cubit.dart';
import 'package:element_x/features/leaveroom/repo/leaveroom_repo.dart';
import 'package:element_x/features/leaveroom/repo/leaveroom_repo_impl.dart';
import 'package:element_x/features/licenses/cubit/licenses_cubit.dart';
import 'package:element_x/features/licenses/repo/licenses_repo.dart';
import 'package:element_x/features/licenses/repo/licenses_repo_impl.dart';
import 'package:element_x/features/linknewdevice/cubit/linknewdevice_cubit.dart';
import 'package:element_x/features/linknewdevice/repo/linknewdevice_repo.dart';
import 'package:element_x/features/linknewdevice/repo/linknewdevice_repo_impl.dart';
import 'package:element_x/features/location/cubit/location_cubit.dart';
import 'package:element_x/features/location/repo/location_repo.dart';
import 'package:element_x/features/location/repo/location_repo_impl.dart';
import 'package:element_x/features/lockscreen/cubit/lockscreen_cubit.dart';
import 'package:element_x/features/lockscreen/repo/lockscreen_repo.dart';
import 'package:element_x/features/lockscreen/repo/lockscreen_repo_impl.dart';
import 'package:element_x/features/login/cubit/login_cubit.dart';
import 'package:element_x/features/login/repo/login_repo.dart';
import 'package:element_x/features/login/repo/login_repo_impl.dart';
import 'package:element_x/features/logout/cubit/logout_cubit.dart';
import 'package:element_x/features/logout/repo/logout_repo.dart';
import 'package:element_x/features/logout/repo/logout_repo_impl.dart';
import 'package:element_x/features/messages/cubit/messages_cubit.dart';
import 'package:element_x/features/messages/cubit/pins_cubit.dart';
import 'package:element_x/features/messages/cubit/thread_cubit.dart';
import 'package:element_x/features/messages/repo/messages_repo.dart';
import 'package:element_x/features/messages/repo/messages_repo_impl.dart';
import 'package:element_x/features/migration/cubit/migration_cubit.dart';
import 'package:element_x/features/migration/repo/migration_repo.dart';
import 'package:element_x/features/migration/repo/migration_repo_impl.dart';
import 'package:element_x/features/networkmonitor/cubit/networkmonitor_cubit.dart';
import 'package:element_x/features/networkmonitor/repo/networkmonitor_repo.dart';
import 'package:element_x/features/networkmonitor/repo/networkmonitor_repo_impl.dart';
import 'package:element_x/features/poll/cubit/poll_cubit.dart';
import 'package:element_x/features/poll/repo/poll_repo.dart';
import 'package:element_x/features/poll/repo/poll_repo_impl.dart';
import 'package:element_x/features/preferences/cubit/preferences_cubit.dart';
import 'package:element_x/features/preferences/repo/preferences_repo.dart';
import 'package:element_x/features/preferences/repo/preferences_repo_impl.dart';
import 'package:element_x/features/rageshake/cubit/rageshake_cubit.dart';
import 'package:element_x/features/rageshake/repo/rageshake_repo.dart';
import 'package:element_x/features/rageshake/repo/rageshake_repo_impl.dart';
import 'package:element_x/features/reportroom/cubit/reportroom_cubit.dart';
import 'package:element_x/features/reportroom/repo/reportroom_repo.dart';
import 'package:element_x/features/reportroom/repo/reportroom_repo_impl.dart';
import 'package:element_x/features/rolesandpermissions/cubit/rolesandpermissions_cubit.dart';
import 'package:element_x/features/rolesandpermissions/repo/rolesandpermissions_repo.dart';
import 'package:element_x/features/rolesandpermissions/repo/rolesandpermissions_repo_impl.dart';
import 'package:element_x/features/roomaliasresolver/cubit/roomaliasresolver_cubit.dart';
import 'package:element_x/features/roomaliasresolver/repo/roomaliasresolver_repo.dart';
import 'package:element_x/features/roomaliasresolver/repo/roomaliasresolver_repo_impl.dart';
import 'package:element_x/features/roomcall/cubit/roomcall_cubit.dart';
import 'package:element_x/features/roomcall/repo/roomcall_repo.dart';
import 'package:element_x/features/roomcall/repo/roomcall_repo_impl.dart';
import 'package:element_x/features/roomdetails/cubit/roomdetails_cubit.dart';
import 'package:element_x/features/roomdetails/repo/roomdetails_repo.dart';
import 'package:element_x/features/roomdetails/repo/roomdetails_repo_impl.dart';
import 'package:element_x/features/roomdetailsedit/cubit/roomdetailsedit_cubit.dart';
import 'package:element_x/features/roomdetailsedit/repo/roomdetailsedit_repo.dart';
import 'package:element_x/features/roomdetailsedit/repo/roomdetailsedit_repo_impl.dart';
import 'package:element_x/features/roomdirectory/cubit/roomdirectory_cubit.dart';
import 'package:element_x/features/roomdirectory/repo/roomdirectory_repo.dart';
import 'package:element_x/features/roomdirectory/repo/roomdirectory_repo_impl.dart';
import 'package:element_x/features/roommembermoderation/cubit/roommembermoderation_cubit.dart';
import 'package:element_x/features/roommembermoderation/repo/roommembermoderation_repo.dart';
import 'package:element_x/features/roommembermoderation/repo/roommembermoderation_repo_impl.dart';
import 'package:element_x/features/securebackup/cubit/securebackup_cubit.dart';
import 'package:element_x/features/securebackup/repo/securebackup_repo.dart';
import 'package:element_x/features/securebackup/repo/securebackup_repo_impl.dart';
import 'package:element_x/features/securityandprivacy/cubit/securityandprivacy_cubit.dart';
import 'package:element_x/features/securityandprivacy/repo/securityandprivacy_repo.dart';
import 'package:element_x/features/securityandprivacy/repo/securityandprivacy_repo_impl.dart';
import 'package:element_x/features/share/cubit/share_cubit.dart';
import 'package:element_x/features/share/repo/share_repo.dart';
import 'package:element_x/features/share/repo/share_repo_impl.dart';
import 'package:element_x/features/signedout/cubit/signedout_cubit.dart';
import 'package:element_x/features/signedout/repo/signedout_repo.dart';
import 'package:element_x/features/signedout/repo/signedout_repo_impl.dart';
import 'package:element_x/features/space/cubit/space_cubit.dart';
import 'package:element_x/features/space/repo/space_repo.dart';
import 'package:element_x/features/space/repo/space_repo_impl.dart';
import 'package:element_x/features/splash/cubit/splash_cubit.dart';
import 'package:element_x/features/splash/repo/splash_repo.dart';
import 'package:element_x/features/splash/repo/splash_repo_impl.dart';
import 'package:element_x/features/startchat/cubit/startchat_cubit.dart';
import 'package:element_x/features/startchat/repo/startchat_repo.dart';
import 'package:element_x/features/startchat/repo/startchat_repo_impl.dart';
import 'package:element_x/features/userprofile/cubit/userprofile_cubit.dart';
import 'package:element_x/features/userprofile/repo/userprofile_repo.dart';
import 'package:element_x/features/userprofile/repo/userprofile_repo_impl.dart';
import 'package:element_x/features/verifysession/cubit/verifysession_cubit.dart';
import 'package:element_x/features/verifysession/repo/verifysession_repo.dart';
import 'package:element_x/features/verifysession/repo/verifysession_repo_impl.dart';
import 'package:element_x/features/viewfolder/cubit/viewfolder_cubit.dart';
import 'package:element_x/features/viewfolder/repo/viewfolder_repo.dart';
import 'package:element_x/features/viewfolder/repo/viewfolder_repo_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

final sl = GetIt.instance;

/// Registers the session, Matrix client, repositories, and cubits.
Future<void> initDependencies({
  String? hivePath,
  SessionStore? sessionStore,
  bool inMemoryDatabase = false,
}) async {
  if (sl.isRegistered<SessionManager>()) {
    return;
  }

  final SessionStore store;
  if (sessionStore != null) {
    store = sessionStore;
  } else {
    if (hivePath == null) {
      await Hive.initFlutter();
    } else {
      Hive.init(hivePath);
    }
    final box = await Hive.openBox<dynamic>(HiveBoxes.session);
    sl.registerSingleton<Box<dynamic>>(box);
    store = HiveSessionStore(box);
  }

  sl.registerSingleton<SessionStore>(store);
  sl.registerLazySingleton<AppSettingsCubit>(
    () => AppSettingsCubit(store),
    dispose: (cubit) => cubit.close(),
  );
  final session = SessionManager(store);
  sl.registerSingleton<SessionManager>(
    session,
    dispose: (manager) => manager.dispose(),
  );

  final handle = await openMatrixClient(
    inMemory: inMemoryDatabase || sessionStore != null,
  );
  final matrix = MatrixStore(
    handle.client,
    store,
    databasePath: handle.databasePath,
  );
  if (handle.client.isLogged()) {
    await session.saveSession(
      userId: handle.client.userID ?? '',
      homeserver: handle.client.homeserver?.host ?? '',
      displayName: handle.client.userID ?? '',
      deviceId: handle.client.deviceID ?? '',
      accessToken: handle.client.accessToken,
    );
  }
  sl.registerSingleton<MatrixStore>(
    matrix,
    dispose: (store) => store.dispose(),
  );

  final dio = Dio(BaseOptions(baseUrl: AppConfig.matrixBaseUrl));
  dio.interceptors.add(AuthInterceptor(session));
  configureDioHomeserver(dio, session);
  sl.registerSingleton<Dio>(dio);
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl()));

  _registerRepos();
  _registerCubits();
  sl.registerLazySingleton<GoRouter>(
    () => buildRouter(sl()),
    dispose: (router) => router.dispose(),
  );
}

void _registerRepos() {
  sl.registerLazySingleton<QrLoginService>(() => QrLoginService(sl(), sl()));
  sl.registerLazySingleton<LoginRepo>(() => LoginRepoImpl(sl(), sl(), sl()));
  sl.registerLazySingleton<PushRepo>(() => PushRepoImpl(sl()));
  sl.registerLazySingleton<SplashRepo>(() => SplashRepoImpl(sl()));
  sl.registerLazySingleton<SignedOutRepo>(SignedOutRepoImpl.new);
  sl.registerLazySingleton<LockscreenRepo>(() => LockscreenRepoImpl(sl()));
  sl.registerLazySingleton<LogoutRepo>(() => LogoutRepoImpl(sl(), sl()));
  sl.registerLazySingleton<FtueRepo>(() => FtueRepoImpl(sl()));
  sl.registerLazySingleton<MigrationRepo>(MigrationRepoImpl.new);
  sl.registerLazySingleton<LinkNewDeviceRepo>(
    () => LinkNewDeviceRepoImpl(sl()),
  );
  sl.registerLazySingleton<HomeRepo>(() => HomeRepoImpl(sl(), sl()));
  sl.registerLazySingleton<AnnouncementRepo>(() => AnnouncementRepoImpl(sl()));
  sl.registerLazySingleton<MessagesRepo>(() => MessagesRepoImpl(sl()));
  sl.registerLazySingleton<SpaceRepo>(() => SpaceRepoImpl(sl()));
  sl.registerLazySingleton<StartChatRepo>(() => StartChatRepoImpl(sl()));
  sl.registerLazySingleton<CreateRoomRepo>(() => CreateRoomRepoImpl(sl()));
  sl.registerLazySingleton<JoinRoomRepo>(() => JoinRoomRepoImpl(sl()));
  sl.registerLazySingleton<RoomDirectoryRepo>(
    () => RoomDirectoryRepoImpl(sl()),
  );
  sl.registerLazySingleton<RoomAliasResolverRepo>(
    () => RoomAliasResolverRepoImpl(sl()),
  );
  sl.registerLazySingleton<InviteRepo>(() => InviteRepoImpl(sl()));
  sl.registerLazySingleton<InvitePeopleRepo>(() => InvitePeopleRepoImpl(sl()));
  sl.registerLazySingleton<KnockRequestsRepo>(
    () => KnockRequestsRepoImpl(sl()),
  );
  sl.registerLazySingleton<ForwardRepo>(() => ForwardRepoImpl(sl()));
  sl.registerLazySingleton<ShareRepo>(() => ShareRepoImpl(sl()));
  sl.registerLazySingleton<ViewFolderRepo>(() => ViewFolderRepoImpl(sl()));
  sl.registerLazySingleton<RoomDetailsRepo>(() => RoomDetailsRepoImpl(sl()));
  sl.registerLazySingleton<RoomDetailsEditRepo>(
    () => RoomDetailsEditRepoImpl(sl()),
  );
  sl.registerLazySingleton<RoomMemberModerationRepo>(
    () => RoomMemberModerationRepoImpl(sl()),
  );
  sl.registerLazySingleton<RolesAndPermissionsRepo>(
    () => RolesAndPermissionsRepoImpl(sl()),
  );
  sl.registerLazySingleton<ReportRoomRepo>(() => ReportRoomRepoImpl(sl()));
  sl.registerLazySingleton<LeaveRoomRepo>(() => LeaveRoomRepoImpl(sl()));
  sl.registerLazySingleton<UserProfileRepo>(() => UserProfileRepoImpl(sl()));
  sl.registerLazySingleton<SecureBackupRepo>(() => SecureBackupRepoImpl(sl()));
  sl.registerLazySingleton<VerifySessionRepo>(
    () => VerifySessionRepoImpl(sl()),
  );
  sl.registerLazySingleton<SecurityAndPrivacyRepo>(
    () => SecurityAndPrivacyRepoImpl(sl()),
  );
  sl.registerLazySingleton<CallRepo>(() => CallRepoImpl(sl()));
  sl.registerLazySingleton<RoomCallRepo>(() => RoomCallRepoImpl(sl()));
  sl.registerLazySingleton<PollRepo>(() => PollRepoImpl(sl()));
  sl.registerLazySingleton<LocationRepo>(() => LocationRepoImpl(sl()));
  sl.registerLazySingleton<PreferencesRepo>(
    () => PreferencesRepoImpl(sl(), sl()),
  );
  sl.registerLazySingleton<AnalyticsRepo>(() => AnalyticsRepoImpl(sl()));
  sl.registerLazySingleton<RageshakeRepo>(RageshakeRepoImpl.new);
  sl.registerLazySingleton<LicensesRepo>(LicensesRepoImpl.new);
  sl.registerLazySingleton<ContentScannerRepo>(
    () => ContentScannerRepoImpl(sl()),
  );
  sl.registerLazySingleton<CacheCleanerRepo>(() => CacheCleanerRepoImpl(sl()));
  sl.registerLazySingleton<NetworkMonitorRepo>(
    () => NetworkMonitorRepoImpl(sl()),
  );
  sl.registerLazySingleton<DeactivationRepo>(
    () => DeactivationRepoImpl(sl(), sl()),
  );
  sl.registerLazySingleton<EnterpriseRepo>(EnterpriseRepoImpl.new);
}

void _registerCubits() {
  sl.registerLazySingleton<LoginCubit>(
    () => LoginCubit(sl()),
    dispose: (cubit) => cubit.close(),
  );
  sl.registerFactory(() => SplashCubit(sl()));
  sl.registerFactory(() => SignedOutCubit(sl()));
  sl.registerFactory(() => LockscreenCubit(sl()));
  sl.registerFactory(() => LogoutCubit(sl()));
  sl.registerFactory(() => FtueCubit(sl()));
  sl.registerFactory(() => MigrationCubit(sl()));
  sl.registerFactory(() => LinkNewDeviceCubit(sl(), sl()));
  sl.registerFactory(() => HomeCubit(sl(), sl()));
  sl.registerFactory(() => AnnouncementCubit(sl(), sl()));
  sl.registerFactoryParam<MessagesCubit, String, Object?>(
    (roomId, _) => MessagesCubit(sl(), sl(), roomId),
  );
  sl.registerFactoryParam<ThreadCubit, String, String>(
    (roomId, eventId) => ThreadCubit(sl(), sl(), roomId, eventId),
  );
  sl.registerFactoryParam<PinsCubit, String, Object?>(
    (roomId, _) => PinsCubit(sl(), sl(), roomId),
  );
  sl.registerFactoryParam<SpaceCubit, String, Object?>(
    (spaceId, _) => SpaceCubit(sl(), spaceId),
  );
  sl.registerFactory(() => StartChatCubit(sl()));
  sl.registerFactory(() => CreateRoomCubit(sl()));
  sl.registerFactory(() => JoinRoomCubit(sl()));
  sl.registerFactory(() => RoomDirectoryCubit(sl(), sl()));
  sl.registerFactory(() => RoomAliasResolverCubit(sl()));
  sl.registerFactoryParam<InviteCubit, String, Object?>(
    (roomId, _) => InviteCubit(sl(), roomId),
  );
  sl.registerFactoryParam<InvitePeopleCubit, String, Object?>(
    (roomId, _) => InvitePeopleCubit(sl(), sl(), roomId),
  );
  sl.registerFactoryParam<KnockRequestsCubit, String, Object?>(
    (roomId, _) => KnockRequestsCubit(sl(), sl(), roomId),
  );
  sl.registerFactoryParam<ForwardCubit, String, String>(
    (roomId, eventId) => ForwardCubit(sl(), roomId, eventId),
  );
  sl.registerFactoryParam<ShareCubit, String, Object?>(
    (text, _) => ShareCubit(sl(), text: text),
  );
  sl.registerFactoryParam<ViewFolderCubit, String, Object?>(
    (roomId, _) => ViewFolderCubit(sl(), roomId),
  );
  sl.registerFactoryParam<RoomDetailsCubit, String, Object?>(
    (roomId, _) => RoomDetailsCubit(sl(), sl(), roomId),
  );
  sl.registerFactoryParam<RoomDetailsEditCubit, String, Object?>(
    (roomId, _) => RoomDetailsEditCubit(sl(), roomId),
  );
  sl.registerFactoryParam<RoomMemberModerationCubit, String, String>(
    (roomId, userId) => RoomMemberModerationCubit(sl(), sl(), roomId, userId),
  );
  sl.registerFactoryParam<RolesAndPermissionsCubit, String, Object?>(
    (roomId, _) => RolesAndPermissionsCubit(sl(), sl(), roomId),
  );
  sl.registerFactoryParam<ReportRoomCubit, String, Object?>(
    (roomId, _) => ReportRoomCubit(sl(), roomId),
  );
  sl.registerFactoryParam<LeaveRoomCubit, String, Object?>(
    (roomId, _) => LeaveRoomCubit(sl(), roomId),
  );
  sl.registerFactoryParam<UserProfileCubit, String, Object?>(
    (userId, _) => UserProfileCubit(sl(), sl(), userId),
  );
  sl.registerFactory(() => SecureBackupCubit(sl(), sl()));
  sl.registerFactory(() => VerifySessionCubit(sl(), sl()));
  sl.registerFactory(() => SecurityAndPrivacyCubit(sl(), sl()));
  sl.registerLazySingleton(() => CallCubit(sl(), sl()));
  sl.registerFactoryParam<RoomCallCubit, String, Object?>(
    (roomId, _) => RoomCallCubit(sl(), roomId),
  );
  sl.registerFactoryParam<PollCubit, String, Object?>(
    (roomId, _) => PollCubit(sl(), roomId),
  );
  sl.registerFactoryParam<LocationCubit, String, Object?>(
    (roomId, _) => LocationCubit(sl(), roomId),
  );
  sl.registerFactory(() => PreferencesCubit(sl(), sl()));
  sl.registerFactory(() => AnalyticsCubit(sl(), sl()));
  sl.registerFactory(() => RageshakeCubit(sl()));
  sl.registerFactory(() => LicensesCubit(sl()));
  sl.registerFactory(() => ContentScannerCubit(sl(), sl()));
  sl.registerFactory(() => CacheCleanerCubit(sl(), sl()));
  sl.registerFactory(() => NetworkMonitorCubit(sl(), sl()));
  sl.registerFactory(() => DeactivationCubit(sl()));
  sl.registerFactory(() => EnterpriseCubit(sl()));
}

/// Visible for tests that need a fresh graph. Not used by the running app.
@visibleForTesting
Future<void> resetDependencies() async {
  await sl.reset();
  if (Hive.isBoxOpen(HiveBoxes.session)) {
    await Hive.close();
  }
}
