import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'jmap_base.dart';

class JmapWsPush extends JmapBase {
  late IOWebSocketChannel _channel;

  Function(Map)? onPushMessage;

  JmapWsPush({required super.session});

  Future<void> setup() async {
    if (session.wsUrl == null) {
      throw Exception('Websocket failed: The server does not support.');
    }
    print("wsUrl: ${session.wsUrl}");

    _channel = IOWebSocketChannel.connect(
      Uri.parse(session.wsUrl!),
      headers: session.authHeaders,
      protocols: ['jmap'],   // ★ 必须，否则 Stalwart 400
    );

    // 监听服务器推送
    _channel.stream.listen((event) {
      final data = jsonDecode(event);
      print("listen data: $data");

      if (data["type"] == "StateChange") {
        final newState = data["changed"]["c"]["Email"]["newState"];
        print("newState: $newState");
        if (onPushMessage != null) {
          onPushMessage!(newState);
        }
      }
      if (data["type"] == "StateChange" ||
        data["type"] == "PushMessage" ||
        data["type"] == "StateChangeNotification") {
        // TODO
      }
    },
    onError: (error) {
      print('WebSocket Error: $error');
      // 重新连接逻辑可以在这里实现
    },
    onDone: () {
      print('WebSocket disconnected.');
      // 重新连接逻辑可以在这里实现
    },
    cancelOnError: false, // 不因为错误而停止监听
    );

    //setupJmapWebsocket();
    echo();
  }

  void setupJmapWebsocket() {
    // WebSocketConnect
    final connectMsg = {
      "using": ["urn:ietf:params:jmap:websocket"],
      "type": "WebSocketConnect",
      "arguments": {"extensions": []}
    };
    _sendRequest(connectMsg);
  }

  void echo() {
    // Stalwart wrapped reqeust, Stalwart不能处理请求中的换行符
    final request = { "@type":"Request", "requestId":"c1", "using": ["urn:ietf:params:jmap:core"], "methodCalls": [ ["Core/echo", {"hello": "world"}, "c1"] ] };
    _sendRequest(request);
  }

  void subscribeEmailChanges() {
    final subCall = [
      "PushSubscription/set",
      {
        "create": {
          "sub1": {
            "deviceClientId": "incontrol_mail",
            "types": ["Email"]
          }
        }
      },
      "0"
    ];

    _sendRequest(subCall);
  }

  void _sendRequest(Object obj) {
    print("send request: $obj");
    _channel.sink.add(jsonEncode(obj));
  }

  void dispose() {
    _channel.sink.close();
  }
}
