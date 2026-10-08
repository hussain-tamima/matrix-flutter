import 'package:equatable/equatable.dart';
import 'package:element_x/features/roomaliasresolver/models/alias_resolution.dart';

class RoomAliasResolverState extends Equatable {
  const RoomAliasResolverState({this.resolution, this.submitting = false});

  final AliasResolution? resolution;
  final bool submitting;

  @override
  List<Object?> get props => [resolution, submitting];
}
