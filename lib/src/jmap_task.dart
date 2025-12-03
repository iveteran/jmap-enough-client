import 'jmap_base.dart';

class JmapTask extends JmapBase {

  JmapTask({ required super.session });

  Future<List<dynamic>> getTasks() async {
    final methods = [
      [
        "TaskList/get",
        {"accountId": session.accountId},
        "c"
      ]
    ];
    final results  = await jmapTasksCall(methods);
    final list = results[0][1]['list'];
    return list;
  }
}
