import 'package:equatable/equatable.dart';

class VerifySessionState extends Equatable {
  const VerifySessionState({required this.verified, required this.emoji});

  final bool verified;
  final List<int> emoji;

  @override
  List<Object?> get props => [verified, emoji];
}
