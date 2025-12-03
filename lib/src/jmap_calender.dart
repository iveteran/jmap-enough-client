import 'jmap_base.dart';

class JmapCalender extends JmapBase {

  JmapCalender({ required super.session });

  Future<List<dynamic>> getCalendars() async {
    final methods = [
      [
        "Calendar/get",
        {"accountId": session.accountId},
        "c"
      ]
    ];
    final results  = await jmapCalendarsCall(methods);
    final list = results[0][1]['list'];
    return list;
  }
}
