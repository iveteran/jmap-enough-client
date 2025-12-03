import 'dart:convert';
import 'package:http/http.dart' as http;
import 'jmap_session.dart';

class JmapBase {

  static const String capJmap = "urn:ietf:params:jmap";
  static const String capCore = "$capJmap:core";
  static const String capMail = "$capJmap:mail";
  static const String capSubmission = "$capJmap:submission";
  static const String capContacts = "$capJmap:contacts";
  static const String capCalendars = "$capJmap:calendars";
  static const String capTasks = "$capJmap:tasks";
  static const String capPrincipals = "$capJmap:principals";

  JmapSession session;

  JmapBase({required this.session});

  Future<dynamic> postRequest(dynamic requestBody) async {
    print("[postRequest] request: $requestBody");
    final rsp = await http.post(
      Uri.parse(session.apiUrl!),
      headers: session.authHeaders,
      body: jsonEncode(requestBody),
    );

    print("[postRequest] response: ${rsp.body}");
    handleResponseError(rsp);
    return jsonDecode(rsp.body);
  }

  Future<dynamic> sendRequest(String url) async {
    final rsp = await http.get(
      Uri.parse(url),
      headers: session.authHeaders,
    );

    handleResponseError(rsp);
    return jsonDecode(rsp.body);
  }

  void handleResponseError(dynamic rsp) {
    if (rsp.statusCode == 401) {
      throw Exception('Authentication failed: Invalid username or password.');
    } else if (rsp.statusCode != 200) {
      throw Exception("JMAP post reqeust error: ${rsp.body}");
    }
  }

  List<dynamic> genJmapMethod({
    required String type,
    required String method,
    required Map<String, dynamic> params,
    required String position,
  }) {
    return [
      "$type/$method",
      params,
      position,
    ];
  }

  Future<List<dynamic>> jmapCall(List<dynamic> methods, {List<String>? extCaps}) async {
    final capabilities = [
      capCore
    ];
    if (extCaps != null && extCaps.isNotEmpty) {
      capabilities.addAll(extCaps);
    }
    final reqeustBody = {
      "using": capabilities,
      "methodCalls": methods
    };
    final result = await postRequest(reqeustBody);
    return result["methodResponses"];
  }

  Future<List<dynamic>> jmapMailCall(List<dynamic> methods) async {
    return await jmapCall(methods, extCaps: [capMail]);
  }

  Future<List<dynamic>> jmapMailSubmissionCall(methods) async {
    return await jmapCall(methods, extCaps: [capMail, capSubmission]);
  }

  Future<List<dynamic>> jmapContactsCall(List<dynamic> methods) async {
    return await jmapCall(methods, extCaps: [capContacts]);
  }

  Future<List<dynamic>> jmapCalendarsCall(List<dynamic> methods) async {
    return await jmapCall(methods, extCaps: [capCalendars]);
  }

  Future<List<dynamic>> jmapTasksCall(List<dynamic> methods) async {
    return await jmapCall(methods, extCaps: [capTasks]);
  }

  Future<List<dynamic>> jmapPrincipalsCall(List<dynamic> methods) async {
    return await jmapCall(methods, extCaps: [capPrincipals]);
  }
}
