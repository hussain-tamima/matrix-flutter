import 'package:equatable/equatable.dart';

class ContentScannerState extends Equatable {
  const ContentScannerState({required this.enabled});

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}
