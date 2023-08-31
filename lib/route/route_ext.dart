import '../includes.dart';

extension OffPage on String {
  ///跳转下一页并关闭当前页
  void pageOff({
    dynamic arguments,
    int? id,
    Map<String, String>? parameters,
  }) {
    Get.offNamed(this, arguments: arguments, id: id, parameters: parameters);
  }

  ///跳转下一页并关闭前面所有页面
  void pageOffAll({
    RoutePredicate? predicate,
    dynamic arguments,
    int? id,
    Map<String, String>? parameters,
  }) {
    Get.offAllNamed(this,
        predicate: predicate,
        arguments: arguments,
        id: id,
        parameters: parameters);
  }

  ///跳转下一页，不关闭当前页
  void pagePush({
    dynamic arguments,
    dynamic id,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
  }) {
    Get.toNamed(this,
        arguments: arguments,
        id: id,
        preventDuplicates: preventDuplicates,
        parameters: parameters);
  }
}
