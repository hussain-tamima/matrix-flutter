import 'package:equatable/equatable.dart';

class FtueState extends Equatable {
  const FtueState({required this.page, required this.done});

  final int page;
  final bool done;

  @override
  List<Object?> get props => [page, done];
}
