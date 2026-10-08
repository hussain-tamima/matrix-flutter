import 'package:equatable/equatable.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class LinkNewDeviceState extends Equatable {
  const LinkNewDeviceState({
    required this.devices,
    this.emojis = const [],
    this.status,
    this.error,
  });

  final List<MatrixDevice> devices;
  final List<String> emojis;
  final String? status;
  final String? error;

  @override
  List<Object?> get props => [devices, emojis, status, error];
}
