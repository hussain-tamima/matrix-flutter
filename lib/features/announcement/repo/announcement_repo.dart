import 'package:element_x/core/matrix/matrix_models.dart';

abstract class AnnouncementRepo {
  MatrixAnnouncement? current();
  void dismiss();
}
