import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../includes.dart';
import 'pages.dart';
import 'routes.dart';

class RouterHelper {
  RouterHelper._internal();

  factory RouterHelper() => _instance;

  static final RouterHelper _instance = RouterHelper._internal();

  static const String appName = 'Watch Together';

  static Widget init() {
    return GetMaterialApp(
      title: appName,
      initialRoute: Routes.root,
      getPages: Pages.pages,
      builder: (context, child) {
        return FlutterSmartDialog(
          child: child ??
              const Center(
                child: Text('$appName Error'),
              ),
        );
      },
    );
  }
}
