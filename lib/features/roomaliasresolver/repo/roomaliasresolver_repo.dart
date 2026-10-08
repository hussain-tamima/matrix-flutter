import 'package:element_x/features/roomaliasresolver/models/alias_resolution.dart';

abstract class RoomAliasResolverRepo {
  Future<AliasResolution> resolve(String alias);
}
