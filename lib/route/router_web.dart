import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:watch_together/route/pages_web.dart';

import '../includes.dart';
import 'routes.dart';

class RouterWeb {
  RouterWeb._internal();

  factory RouterWeb() => _instance;

  static final RouterWeb _instance = RouterWeb._internal();

  static const String appName = 'Watch Together';

  static Widget init() {
    return GetMaterialApp(
      title: appName,
      initialRoute: Routes.root,
      getPages: PagesWeb.pages,
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
