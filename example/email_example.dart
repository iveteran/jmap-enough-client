import "dart:async";
import "package:jmap_enough_client/jmap_enough_client.dart";

void main() async {
  const sessionUrl = 'https://mail.incontrol.chat/jmap/session';
  const username = 'yu@incontrol.chat';
  const password = 'YourPassword'; 

  print('Starting ...');

  try {
    // 1. 登录和初始化
    final session = JmapSession(
      sessionUrl: sessionUrl,
      username: username,
      password: password,
    );
    await session.initialize();

    final mailService = JmapEmail(session: session);
    final contactService = JmapContact(session: session);
    final calenderService = JmapCalender(session: session);

    final mailboxes = await mailService.listMailboxes();
    print('--- Mailboxes number: ${mailboxes.length} ---');
    for (final mailbox in mailboxes) {
      print("mailbox: $mailbox");
    }

    final mailboxId = await mailService.getMailboxIdByRole(mailboxRole: "inbox");
    print("inbox mailbox id : $mailboxId");

    final messages = await mailService.listEmails(mailboxId);
    print('--- messages number: ${messages.length} ---');
    for (final message in messages) {
      print("message: $message");
      //final subject = message["subject"] ?? "(No Subject)";
      //final from = message["from"]?[0]?["email"] ?? "";
      //final date = message["receivedAt"] ?? "";
      //print("> message: $subject, $from, $date");
    }

    if (messages.isNotEmpty) {
      final firstMessage = messages.first;
      final firstFullMessage = await mailService.getFullEmail(emailId: firstMessage["id"]);
      print("first full message; $firstFullMessage");

      final lastMessage = messages.last;
      final lastFullMessage = await mailService.getFullEmail(emailId: lastMessage["id"]);
      print("last full message; $lastFullMessage");
    }

    final contacts = await contactService.getContacts();
    print('--- contacts number: ${contacts.length} ---');

    final calendars = await calenderService.getCalendars();
    print('--- calendars number: ${calendars.length} ---');

    //final tasks = await taskService.getTasks();
    //print('--- tasks number: ${tasks.length} ---');

    //final principals = await sharingService.getPrincipals();
    //print('--- principals number: ${principals.length} ---');

    //await mailService.sendEmail(from: username, to: "test001@matrix.works", subject: "test jmap with raw protocol", textBody: "just a test");

    final newMessageIds = await mailService.checkNewMessages();
    print('newMessageIds: $newMessageIds');

    // Subscribe new messages with websocket push
    final mailPush = JmapWsPush(session: session);
    mailPush.setup();
    //mailPush.subscribeEmailChanges();
    mailPush.onPushMessage = (msg) {
      print("收到推送: $msg");
    };

    // Polling new messages periodically
    Timer.periodic(Duration(seconds: 10), (_) async {
      final newIds = await mailService.checkNewMessages();
      for (final id in newIds) {
        final email = await mailService.getFullEmail(emailId: id);
        print("Received new mail: $email");
      }
    });

    print('--- 等待新邮件推送(5分钟) ---');
    await Future.delayed(Duration(minutes: 5));

  } catch (e, s) {
    print('\n--- An Error Occurred ---');
    print(e);
    print(s);
  }
}
