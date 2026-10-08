import 'package:element_x/features/linknewdevice/cubit/linknewdevice_state.dart';
export 'package:element_x/features/linknewdevice/cubit/linknewdevice_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:flutter/foundation.dart';
import 'package:element_x/core/matrix/matrix_error.dart';
import 'package:element_x/features/linknewdevice/repo/linknewdevice_repo.dart';

class LinkNewDeviceCubit extends Cubit<LinkNewDeviceState> {
  LinkNewDeviceCubit(this._repo, this._store)
    : super(LinkNewDeviceState(devices: _repo.devices())) {
    _listener = load;
    _store.addListener(_listener);
  }

  final LinkNewDeviceRepo _repo;
  final MatrixStore _store;
  late final VoidCallback _listener;

  void load() {
    emit(
      LinkNewDeviceState(
        devices: _repo.devices(),
        emojis: _repo.verificationEmojis,
        status: _repo.verificationStatus,
      ),
    );
  }

  Future<void> verify(String deviceId) async {
    try {
      await _repo.verify(deviceId);
      load();
    } catch (error) {
      if (!isClosed) {
        emit(
          LinkNewDeviceState(
            devices: _repo.devices(),
            error: matrixError(error),
          ),
        );
      }
    }
  }

  Future<void> confirm() async {
    try {
      await _repo.confirm();
      load();
    } catch (error) {
      if (!isClosed) {
        emit(
          LinkNewDeviceState(
            devices: _repo.devices(),
            emojis: _repo.verificationEmojis,
            error: matrixError(error),
          ),
        );
      }
    }
  }

  void cancel() {
    _repo.cancel();
    load();
  }

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    return super.close();
  }
}
