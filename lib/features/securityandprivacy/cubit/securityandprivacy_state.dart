import 'package:equatable/equatable.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class SecurityAndPrivacyState extends Equatable {
  const SecurityAndPrivacyState({
    required this.preferences,
    this.devices = const [],
  });

  final MatrixPreferences preferences;
  final List<MatrixDevice> devices;

  @override
  List<Object?> get props => [preferences, devices];
}
