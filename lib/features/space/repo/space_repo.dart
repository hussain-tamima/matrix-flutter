import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/space/models/space_summary.dart';

abstract class SpaceRepo {
  SpaceSummary? summary(String spaceId);
  List<MatrixRoom> children(String spaceId);
}
