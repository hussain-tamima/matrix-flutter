/// Keys shared by screens and the smoke test.
abstract final class TestKeys {
  static const signIn = 'sign-in';
  static const continueProvider = 'continue-provider';
  static const confirmProvider = 'confirm-provider';
  static const homeserver = 'homeserver-field';
  static const username = 'username-field';
  static const password = 'password-field';
  static const loginSubmit = 'login-submit';
  static const composer = 'composer-field';
  static const send = 'send-button';
  static const settings = 'open-settings';
  static const signOut = 'sign-out';

  static String roomTile(String id) => 'room-tile-$id';
  static String acceptInvite(String id) => 'accept-invite-$id';
  static String declineInvite(String id) => 'decline-invite-$id';
}
