import 'package:element_x/core/matrix/matrix_models.dart';

abstract class ViewFolderRepo {
  List<TimelineEvent> files(String roomId);
}
