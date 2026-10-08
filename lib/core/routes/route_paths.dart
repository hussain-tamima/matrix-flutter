/// Route locations for the ROP messenger flows.
abstract final class RoutePaths {
  static const splash = '/';
  static const login = '/login';
  static const loginProvider = '/login/provider';
  static const loginConfirm = '/login/confirm';
  static const loginPassword = '/login/password';
  static const loginQr = '/login/qr';
  static const createAccount = '/login/create-account';
  static const signedOut = '/signed-out';
  static const logout = '/logout';
  static const lock = '/lock';
  static const ftue = '/ftue';
  static const migration = '/migration';
  static const linkDevice = '/link-device';
  static const linkDeviceSignInQr = '/link-device/sign-in-qr';
  static const home = '/home';
  static const homeSearch = '/home/search';
  static const startChat = '/start-chat';
  static const createRoom = '/create-room';
  static const joinRoom = '/join';
  static const directory = '/directory';
  static const resolveAlias = '/resolve-alias';
  static const secureBackup = '/secure-backup';
  static const verify = '/verify';
  static const share = '/share';
  static const bugReport = '/bug-report';
  static const licenses = '/licenses';
  static const settings = '/settings';
  static const settingsAccount = '/settings/account';
  static const settingsNotifications = '/settings/notifications';
  static const settingsLabs = '/settings/labs';
  static const settingsDeveloper = '/settings/developer';
  static const settingsBlocked = '/settings/blocked-users';
  static const settingsAnalytics = '/settings/analytics';
  static const settingsAbout = '/settings/about';
  static const settingsMedia = '/settings/media';
  static const settingsLocation = '/settings/location';
  static const settingsModeration = '/settings/moderation';
  static const settingsSecurity = '/settings/security';
  static const settingsDeactivate = '/settings/deactivate';
  static const settingsCache = '/settings/cache';
  static const settingsScanner = '/settings/content-scanner';
  static const settingsEnterprise = '/settings/enterprise';
  static const network = '/network';
  static const call = '/call';

  static String room(String id) => '/rooms/${Uri.encodeComponent(id)}';
  static String roomDetails(String id) => '${room(id)}/details';
  static String roomEdit(String id) => '${room(id)}/edit';
  static String roomMembers(String id) => '${room(id)}/members';
  static String roomMember(String roomId, String userId) =>
      '${room(roomId)}/members/${Uri.encodeComponent(userId)}';
  static String roomRoles(String id) => '${room(id)}/roles';
  static String roomReport(String id) => '${room(id)}/report';
  static String roomLeave(String id) => '${room(id)}/leave';
  static String roomNotifications(String id) => '${room(id)}/notifications';
  static String roomPins(String id) => '${room(id)}/pins';
  static String roomFiles(String id) => '${room(id)}/files';
  static String roomInvite(String id) => '${room(id)}/invite';
  static String invitePeople(String id) => '${room(id)}/people';
  static String roomKnocks(String id) => '${room(id)}/knocks';
  static String roomCall(String id) => '${room(id)}/call';
  static String roomLocation(String id) => '${room(id)}/location';
  static String roomPoll(String id) => '${room(id)}/poll';
  static String thread(String roomId, String eventId) =>
      '${room(roomId)}/threads/${Uri.encodeComponent(eventId)}';
  static String forward(String roomId, String eventId) =>
      '/forward?roomId=${Uri.encodeQueryComponent(roomId)}&eventId=${Uri.encodeQueryComponent(eventId)}';
  static String user(String id) => '/users/${Uri.encodeComponent(id)}';
  static String space(String id) => '/spaces/${Uri.encodeComponent(id)}';
  static String moderate(String roomId, String userId) =>
      '${room(roomId)}/moderate/${Uri.encodeComponent(userId)}';
}
