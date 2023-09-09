import 'dart:async';

typedef TaskCallback = void Function(bool success, dynamic result);
typedef TaskFutureFuc = Future Function();

///队列任务，先进先出，一个个执行
class TaskQueueUtils {
  bool _isTaskRunning = false;
  final List<TaskItem> _taskList = [];

  bool get isTaskRunning => _isTaskRunning;

  Future addTask(TaskFutureFuc futureFunc, {dynamic param}) {
    Completer completer = Completer();
    TaskItem taskItem = TaskItem(
      futureFunc,
          (success, result) {
        if (success) {
          completer.complete(result);
        } else {
          completer.completeError(result);
        }
        _taskList.removeAt(0);
        _isTaskRunning = false;
        //递归任务
        _doTask();
      },
    );
    _taskList.add(taskItem);
    _doTask();
    return completer.future;
  }

  Future<void> _doTask() async {
    if (_isTaskRunning) return;
    if (_taskList.isEmpty) return;

    //获取先进入的任务
    TaskItem task = _taskList[0];
    _isTaskRunning = true;
    try {
      //执行任务
      var result = await task.futureFun();
      //完成任务
      task.callback(true, result);
    } catch (_) {
      task.callback(false, _.toString());
    }
  }
}

///任务封装
class TaskItem {
  final TaskFutureFuc futureFun;
  final TaskCallback callback;

  const TaskItem(
      this.futureFun,
      this.callback,
      );
}
