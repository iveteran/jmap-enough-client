import 'jmap_base.dart';

class JmapSharing extends JmapBase {

  JmapSharing({ required super.session });

  Future<List<dynamic>> getPrincipals() async {
    final methods = [
      [
        "Principal/get",
        {"accountId": session.accountId},
        "c"
      ]
    ];
    final results  = await jmapPrincipalsCall(methods);
    final list = results[0][1]['list'];
    return list;
  }
}
