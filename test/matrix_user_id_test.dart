import 'package:element_x/core/config/app_config.dart';
import 'package:element_x/core/utils/matrix_user_ids.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const hs = AppConfig.defaultHomeserver;

  group('resolveMatrixUserId', () {
    test('bare localpart', () {
      expect(
        resolveMatrixUserId('alice', defaultHomeserver: hs),
        '@alice:st1rop.eko.bz',
      );
    });

    test('localpart with @', () {
      expect(
        resolveMatrixUserId('@alice', defaultHomeserver: hs),
        '@alice:st1rop.eko.bz',
      );
    });

    test('localpart:server without @', () {
      expect(
        resolveMatrixUserId('alice:st1rop.eko.bz', defaultHomeserver: hs),
        '@alice:st1rop.eko.bz',
      );
    });

    test('full id unchanged', () {
      const full = '@alice:st1rop.eko.bz';
      expect(resolveMatrixUserId(full, defaultHomeserver: hs), full);
    });

    test('explicit other server', () {
      const full = '@alice:other.tld';
      expect(resolveMatrixUserId(full, defaultHomeserver: hs), full);
      expect(
        resolveMatrixUserId('alice:other.tld', defaultHomeserver: hs),
        full,
      );
    });

    test('rejects room alias and id', () {
      expect(resolveMatrixUserId('#ops:hs', defaultHomeserver: hs), isNull);
      expect(resolveMatrixUserId('!room:hs', defaultHomeserver: hs), isNull);
    });

    test('rejects empty and server-only', () {
      expect(resolveMatrixUserId('', defaultHomeserver: hs), isNull);
      expect(
        resolveMatrixUserId(':st1rop.eko.bz', defaultHomeserver: hs),
        isNull,
      );
    });

    test('does not double suffix', () {
      expect(
        resolveMatrixUserId('@alice:st1rop.eko.bz', defaultHomeserver: hs),
        '@alice:st1rop.eko.bz',
      );
    });
  });

  group('matrixUserLocalpart', () {
    test('extracts localpart', () {
      expect(matrixUserLocalpart('@alice:st1rop.eko.bz'), 'alice');
    });
  });
}
