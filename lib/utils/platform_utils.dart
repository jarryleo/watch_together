import 'dart:io';

import 'package:flutter/foundation.dart';

class PlatFormUtils {
  static bool isMobile() {
    return Platform.isAndroid || Platform.isIOS;
  }

  static bool isDesktop() {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  static bool isWeb() {
    return kIsWeb ? true : false;
  }
}
