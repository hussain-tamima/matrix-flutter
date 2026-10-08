import 'package:equatable/equatable.dart';

class RageshakeState extends Equatable {
  const RageshakeState({this.error, this.sent = false});

  final String? error;
  final bool sent;

  @override
  List<Object?> get props => [error, sent];
}
