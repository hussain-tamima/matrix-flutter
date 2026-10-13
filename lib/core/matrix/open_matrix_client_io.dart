import 'dart:io';

import 'package:element_x/core/config/app_config.dart';
import 'package:element_x/core/matrix/group_call_events.dart';
import 'package:element_x/core/matrix/matrix_client_handle.dart';
import 'package:element_x/core/matrix/stale_room.dart';
import 'package:element_x/core/utils/test_env_stub.dart'
    if (dart.library.io) 'package:element_x/core/utils/test_env_io.dart';
import 'package:flutter_vodozemac/flutter_vodozemac.dart' as flutter_vod;
import 'package:matrix/matrix.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as mobile;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

Future<MatrixClientHandle> openMatrixClient({bool inMemory = false}) async {
  if (!vod.isInitialized()) {
    try {
      await flutter_vod.init();
    } catch (error) {
      if (!isFlutterTest) {
        rethrow;
      }
    }
  }

  final useFfi = Platform.isWindows || Platform.isLinux;
  if (useFfi) {
    sqfliteFfiInit();
  }
  final factory = useFfi ? databaseFactoryFfi : mobile.databaseFactory;
  final path = inMemory
      ? inMemoryDatabasePath
      : p.join(
          (await getApplicationSupportDirectory()).path,
          'element_x.sqlite',
        );
  final database = await factory.openDatabase(path);
  final sdkDatabase = await MatrixSdkDatabase.init(
    'element_x',
    database: database,
    sqfliteFactory: factory,
  );
  final client = Client(AppConfig.deviceDisplayName, database: sdkDatabase);
  client.importantStateEvents.addAll([
    groupCallEventType,
    groupCallMemberEventType,
    matrixRtcMemberEventType,
  ]);
  await client.init(waitForFirstSync: false);
  attachStaleRoomCleanup(client);
  return MatrixClientHandle(client, databasePath: inMemory ? null : path);
}

int databaseSize(String? path) {
  if (path == null) {
    return 0;
  }
  final file = File(path);
  if (!file.existsSync()) {
    return 0;
  }
  return file.lengthSync();
}
