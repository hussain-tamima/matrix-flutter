import 'package:element_x/core/matrix/matrix_models.dart';

abstract class SecurityAndPrivacyRepo {
  MatrixPreferences get preferences;
  List<MatrixDevice> devices();
}
