import 'package:equatable/equatable.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class PreferencesState extends Equatable {
  const PreferencesState({
    required this.preferences,
    required this.displayName,
    required this.userId,
    required this.homeserver,
    this.blocked = const [],
  });

  final MatrixPreferences preferences;
  final String displayName;
  final String userId;
  final String homeserver;
  final List<MatrixUser> blocked;

  @override
  List<Object?> get props => [
    preferences,
    displayName,
    userId,
    homeserver,
    blocked,
  ];
}
