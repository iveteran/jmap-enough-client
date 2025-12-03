import 'jmap_base.dart';

class JmapContact extends JmapBase {

  JmapContact({ required super.session });

  Future<List<dynamic>> getContacts() async {
    final methods = [
      [
        "ContactCard/get",
        {"accountId": session.accountId},
        "c"
      ]
    ];
    final results  = await jmapContactsCall(methods);
    final list = results[0][1]['list'];
    return list;
  }
}
