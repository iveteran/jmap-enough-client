import 'package:jmap_enough_client/jmap_enough_client.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    const sessionUrl = 'https://mail.incontrol.chat/jmap/session';
    const username = 'yu@incontrol.chat';
    const password = 'YourPassword'; 
    final session = JmapSession(sessionUrl: sessionUrl, username: username, password: password);

    setUp(() {
      // Additional setup goes here.
    });

    test('Initialize session', () async {
      await session.initialize();
      expect(session.apiUrl != null, isTrue);
      expect(session.accountId != null, isTrue);
    });
  });
}
