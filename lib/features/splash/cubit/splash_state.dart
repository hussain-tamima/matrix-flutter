import 'package:equatable/equatable.dart';

class SplashState extends Equatable {
  const SplashState({this.route});

  final String? route;

  @override
  List<Object?> get props => [route];
}
