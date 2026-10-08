import 'package:element_x/features/signedout/repo/signedout_repo.dart';

class SignedOutRepoImpl implements SignedOutRepo {
  @override
  String message() {
    return 'You are signed out. Sign in again to restore your rooms on this device.';
  }
}
