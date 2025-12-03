import 'dart:convert';
import 'package:http/http.dart' as http;

class JmapSession {
  static const String capCore = "urn:ietf:params:jmap:core";
  static const String capMail = "urn:ietf:params:jmap:mail";

  final String sessionUrl;
  final String username;
  final String password;

  Map<String, dynamic>? jmapSession;
  String? accountId;
  String? apiUrl;
  String? wsUrl;
  bool? wsSupportsPush;
  String? token;
  Map<String, String>? authHeaders;

  String? lastEmailState;

  JmapSession({required this.sessionUrl, required this.username, required this.password}) {
    generateAuthHeaders();
  }

  /// 如果用户名密码错误，这里会抛出异常 (401 Unauthorized)
  Future<void> initialize() async {
    jmapSession = await sendRequest(sessionUrl);
    //print(JsonEncoder.withIndent('  ').convert(jmapSession));
    apiUrl = jmapSession?['apiUrl'];
    final wsOptions = jmapSession?['capabilities']['urn:ietf:params:jmap:websocket'];
    wsUrl = wsOptions['url'];
    wsSupportsPush = wsOptions['supportsPush'];
    final primaryAccounts = jmapSession?['primaryAccounts'];
    if (primaryAccounts != null && primaryAccounts[capMail] != null) {
      accountId = primaryAccounts[capMail];
    } else {
      accountId = (jmapSession?['accounts'] as Map).keys.first;
    }
    print("[JmapSession.initialize] api url: $apiUrl");
    print("[JmapSession.initialize] ws url: $wsUrl");
    print("[JmapSession.initialize] account id: $accountId");
  }

  /// 生成 HTTP Basic Auth Header
  void generateAuthHeaders() {
    // 格式为 "Basic base64(username:password)"
    String credentials = '$username:$password';
    token = base64Encode(utf8.encode(credentials));
    authHeaders = {
      'Authorization': 'Basic $token',
      'Content-Type': 'application/json',
    };
  }

  Future<dynamic> sendRequest(String url) async {
    final rsp = await http.get(
      Uri.parse(url),
      headers: authHeaders,
    );

    if (rsp.statusCode == 401) {
      throw Exception('Authentication failed: Invalid username or password.');
    }
    return jsonDecode(rsp.body);
  }
}
