import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../includes.dart';

extension StringExt on String {
  void showToast() {
    if (trim().isNotEmpty) {
      SmartDialog.showToast(this, alignment: Alignment.center);
    }
  }
}
