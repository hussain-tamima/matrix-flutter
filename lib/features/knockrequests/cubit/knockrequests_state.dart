import 'package:equatable/equatable.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class KnockRequestsState extends Equatable {
  const KnockRequestsState({this.requests = const []});

  final List<KnockRequest> requests;

  @override
  List<Object?> get props => [requests];
}
