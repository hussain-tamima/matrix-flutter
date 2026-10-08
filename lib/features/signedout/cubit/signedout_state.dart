import 'package:equatable/equatable.dart';

class SignedOutState extends Equatable {
  const SignedOutState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
