import 'package:equatable/equatable.dart';

class CacheCleanerState extends Equatable {
  const CacheCleanerState({required this.bytes});

  final int bytes;

  @override
  List<Object?> get props => [bytes];
}
