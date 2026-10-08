import 'package:element_x/core/config/environment.dart';

/// Homeserver and product constants. Fake repositories do not call these URLs.
class AppConfig {
  const AppConfig._();

  static const appName = 'Royal Oman Police';
  static const shortName = 'ROP';
  static const productMark = 'EKO';
  static const tagline = 'Secure communication platform for Royal Oman Police';
  static const shortTagline = 'Secure communication';
  static const deviceDisplayName = 'ROP';
  static const defaultHomeserver = 'st1rop.eko.bz';
  static const footerRopUrl = 'https://www.rop.gov.om';
  static const footerPartnerUrl = 'https://ttct.net/';

  static String get matrixBaseUrl => switch (currentEnvironment) {
    Environment.dev => 'http://localhost:8008',
    Environment.prod => 'https://st1rop.eko.bz',
  };
}
