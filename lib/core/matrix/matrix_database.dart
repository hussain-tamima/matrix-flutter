import 'package:element_x/core/matrix/matrix_client_handle.dart';
import 'package:element_x/core/matrix/open_matrix_client_stub.dart'
    if (dart.library.io) 'package:element_x/core/matrix/open_matrix_client_io.dart'
    as opener;

export 'package:element_x/core/matrix/matrix_client_handle.dart';

Future<MatrixClientHandle> openMatrixClient({bool inMemory = false}) {
  return opener.openMatrixClient(inMemory: inMemory);
}

int databaseSize(String? path) => opener.databaseSize(path);
