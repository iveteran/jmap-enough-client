import 'jmap_base.dart';

// JMAP documents:
//   https://jmap.io/

class JmapEmail extends JmapBase {

  JmapEmail({required super.session});

  /// 获取 mailbox 列表
  Future<List<dynamic>> listMailboxes() async {
    final methods = [
      [
        "Mailbox/query",
        {"accountId": session.accountId},
        "c1"
      ],
      [
        "Mailbox/get",
        {
          "accountId": session.accountId,
          "#ids": {
            "resultOf": "c1",
            "name": "Mailbox/query",
            "path": "/ids"
          }
        },
        "c2"
      ]
    ];
    final results = await jmapMailCall(methods);
    final mailboxes = results[1][1]["list"];
    return mailboxes;
  }

  /// ----------------------------
  /// 获取 邮箱 ID
  /// 可用邮箱role: 'inbox', 'sent', 'trash', 'drafts', 'junk'
  /// ----------------------------
  Future<String> getMailboxIdByRole({
    required String mailboxRole,
  }) async {
    final methods = [
      [
        "Mailbox/query",
        {
          "accountId": session.accountId,
          "filter": {"role": mailboxRole}
        },
        "c1"
      ]
    ];

    final results = await jmapMailCall(methods);

    final ids = results[0][1]["ids"];
    if (ids == null || ids.isEmpty) {
      throw Exception("Not found: $mailboxRole");
    }

    return ids[0];
  }

  Future<String> getMailboxIdByName({
    required String mailboxName,
  }) async {
    final methods = [
      [
        "Mailbox/query",
        {
          "accountId": session.accountId,
          "filter": {"name": mailboxName}
        },
        "c1"
      ]
    ];

    final results = await jmapMailCall(methods);

    final ids = results[0][1]["ids"];
    if (ids == null || ids.isEmpty) {
      throw Exception("Not found: $mailboxName");
    }

    return ids[0];
  }

  Future<dynamic> getIdentityId() async {
    final methods = [
      [
        "Identity/get",
        {
          "accountId": session.accountId,
        },
        "c1"
      ]
    ];

    final results = await jmapMailCall(methods);
    final ids = results[0][1]["list"];
    return ids[0]["id"];
  }

  /// 获取邮件列表
  Future<List<Map<String, dynamic>>> listEmails(String mailboxId, {
    List<String> selectFields = const [
      "id", "subject", "from", "to", "receivedAt", "header:Message-ID"
    ],
    String orderBy = "receivedAt",
    bool isAscending = false,
    int limit = 20,
  }) async {
    final methods = [
      [
        "Email/query",
        {
          "accountId": session.accountId,
          "filter": {"inMailbox": mailboxId},
          "sort": [
            {"property": orderBy, "isAscending": isAscending}
          ],
          "limit": limit
        },
        "q1"
      ],
      [
        "Email/get",
        {
          "accountId": session.accountId,
          "#ids": {
            "resultOf": "q1",
            "name": "Email/query",
            "path": "/ids"
          },
          "properties": selectFields
        },
        "q2"
      ]
    ];
    final results = await jmapMailCall(methods);
    session.lastEmailState = results[1][1]["state"];

    final emails = results[1][1]["list"] as List;
    return emails.map((item) => {
      "id": item["id"],
      "messageId": item["header:Message-ID"].trim(),
      "subject": item["subject"],
      "from": item["from"],
      "to": item["to"],
      "cc": item["cc"],
      "bcc": item["bcc"],
      "receivedAt": item["receivedAt"],
    }).toList();
  }

  /// 获取邮件全文内容（含标题、正文、地址等）
  /// 返回结构化 Map
  Future<Map<String, dynamic>> getFullEmail({
    required String emailId,
  }) async {
    final methods = [
      [
        "Email/get",
        {
          "accountId": session.accountId,
          "ids": [emailId],
          "properties": [
            "id",
            "header:Message-ID",
            "subject",
            "from",
            "to",
            "cc",
            "bcc",
            "receivedAt",
            "htmlBody",
            "textBody",
            "bodyValues",
            "attachments"
          ],
          "fetchBodyValues": true
        },
        "c1"
      ]
    ];
    final results = await jmapMailCall(methods);
    session.lastEmailState = results[0][1]["state"];
    final emails = results[0][1]["list"];

    if (emails.isEmpty) {
      throw Exception("邮件不存在: $emailId");
    }

    final email = emails.first;
    final bodyValues = email["bodyValues"] ?? {};

    // 自动选择正文：优先 html，其次 text
    String? html;
    String? text;

    if (email["htmlBody"] != null && email["htmlBody"].isNotEmpty) {
      final partId = email["htmlBody"][0]["partId"];
      html = bodyValues[partId]?["value"];
    }

    if (email["textBody"] != null && email["textBody"].isNotEmpty) {
      final partId = email["textBody"][0]["partId"];
      text = bodyValues[partId]?["value"];
    }

    return {
      "id": email["id"],
      "messageId": email["header:Message-ID"].trim(),
      "subject": email["subject"],
      "from": email["from"],
      "to": email["to"],
      "cc": email["cc"],
      "bcc": email["bcc"],
      "receivedAt": email["receivedAt"],
      "html": html,
      "text": text,
      "attachments": email["attachments"],
    };
  }

  Future<Map<String, String?>> getEmailHeaders({
    required String emailId,
    required List<String> headers, // 例如 ["Message-ID", "In-Reply-To"]
  }) async {
    // 转换为 JMAP 属性：header:<Name>
    final headerProps = headers.map((h) => "header:$h").toList();
    final methods = [
      [
        "Email/get",
        {
          "accountId": session.accountId,
          "ids": [emailId],
          "properties": headerProps,
        },
        "c1"
      ]
    ];
    final results = await jmapMailCall(methods);
    session.lastEmailState = results[0][1]["state"];
    final list = results[0][1]["list"];

    if (list.isEmpty) {
      throw Exception("Message not found: $emailId");
    }

    final email = list[0];

    // 输出 Map：headerName → value
    final values = <String, String?>{};
    for (final h in headers) {
      values[h] = email["header:$h"];
    }

    return values;
  }

  /// 发送邮件
  Future<void> sendEmail({
    required String from,
    required String to,
    required String subject,
    required String textBody,
  }) async {
    final outboxId = await getMailboxIdByName(mailboxName: "Outbox");
    final identityId = await getIdentityId();
    final methods = [
      /*
      [
        "Mailbox/query",
        {
          "accountId": session.accountId,
          "filter": { "name": "Outbox" }
        },
        "q1"
      ],
      */
      [
        "Email/set",
        {
          "accountId": session.accountId,
          "create": {
            "msg1": {
              //"mailboxIds": { "#q1/ids/0": true },  # Stalwart does not support
              "mailboxIds": { outboxId: true },
              "from": [
                {"email": from}
              ],
              "to": [
                {"email": to}
              ],
              "subject": subject,
              "textBody": [
                {"partId": "text1"}
              ],
              "bodyValues": {
                "text1": {
                  "value": textBody
                }
              }
            }
          }
        },
        "c1"
      ],
      [
        "EmailSubmission/set",
        {
          "accountId": session.accountId,
          "create": {
            "sub1": {
              "emailId": "#msg1",
              "identityId": identityId,
            }
          },
          "onSuccessDestroyEmail": ["msg1"]
        },
        "c2"
      ]
    ];
    await jmapMailSubmissionCall(methods);

    print("邮件发送成功");
  }

  Future<void> deleteEmail({
    required String emailId,
    required String trashMailboxId,
  }) async {
    final methods = [
      [
        "Email/set",
        {
          "accountId": session.accountId,
          "update": {
            emailId: {
              "mailboxIds": {
                trashMailboxId: true
              }
            }
          }
        },
        "c1"
      ]
    ];
    await jmapMailCall(methods);

    print("邮件已移动到垃圾箱");
  }

  Future<void> archiveEmail({
    required String emailId,
    required String archiveMailboxId,
  }) async {
    final methods = [
      [
        "Email/set",
        {
          "accountId": session.accountId,
          "update": {
            emailId: {
              "mailboxIds": {
                archiveMailboxId: true
              }
            }
          }
        },
        "c1"
      ]
    ];
    await jmapMailCall(methods);
    print("邮件已归档");
  }

  Future<void> setEmailSeen({
    required String emailId,
    required bool seen, // true=已读, false=未读
  }) async {
    await markEmail(emailId: emailId, which: "seen", value: seen);
  }

  /// 标记邮件为已读或未读，其它可用的keywords
  /// | keyword     | 含义   |
  /// | ----------- | ---- |
  /// | `$seen`     | 是否已读 |
  /// | `$flagged`  | 星标   |
  /// | `$draft`    | 草稿   |
  /// | `$answered` | 已回复  |
  Future<void> markEmail({
    required String emailId,
    required String which,
    required bool value,
  }) async {
    final methods = [
      [
        "Email/set",
        {
          "accountId": session.accountId,
          "update": {
            emailId: {
              "keywords": {
                "\$$which": value,
              }
            }
          }
        },
        "c1"
      ]
    ];
    await jmapMailCall(methods);
  }

  /// 保存草稿邮件
  Future<String> saveDraft({
    required String draftMailboxId,   // 草稿箱的 mailbox ID
    required String subject,
    String? textBody,
    String? htmlBody,
    List<Map<String, String>>? to,   // [{ "name": "A", "email": "a@xx.com" }]
    List<Map<String, String>>? cc,
    List<Map<String, String>>? bcc,
  }) async {
    // 构建 JMAP Email 对象（草稿）
    final emailObject = {
      "mailboxIds": {draftMailboxId: true},
      "subject": subject,
      "keywords": {"\$draft": true},
      "to": to?.map((e) => {"name": e["name"], "email": e["email"]}).toList(),
      "cc": cc?.map((e) => {"name": e["name"], "email": e["email"]}).toList(),
      "bcc": bcc?.map((e) => {"name": e["name"], "email": e["email"]}).toList(),
      "bodyValues": {},
      "textBody": [],
      "htmlBody": [],
    };

    // 添加正文（text / html）
    if (textBody != null) {
      emailObject["bodyValues"] = {
        "textBody": {"value": textBody}
      };
      emailObject["textBody"] = [
        {"partId": "textBody"}
      ];
    }

    if (htmlBody != null) {
      emailObject["bodyValues"] ??= {};
      //emailObject["bodyValues"]["htmlBody"] = {"value": htmlBody};
      emailObject["htmlBody"] = [
        {"partId": "htmlBody"}
      ];
    }

    final methods = [
      [
        "Email/set",
        {
          "accountId": session.accountId,
          "create": {
            "draft1": emailObject
          }
        },
        "c1"
      ]
    ];

    final results = await jmapMailCall(methods);
    final created = results[0][1]["created"];

    if (created == null || created.isEmpty) {
      throw Exception("创建草稿失败：服务器未返回草稿 id");
    }

    // 返回草稿邮件的真实 emailId
    final emailId = created.values.first["id"];
    return emailId;
  }

  /// 更新草稿邮件
  Future<void> updateDraft({
    required String emailId,     // 要更新的草稿 ID
    String? subject,             // 新标题
    String? textBody,            // 文本正文
    String? htmlBody,            // HTML 正文
    List<String>? to,            // 收件人
    List<String>? cc,
    List<String>? bcc,
  }) async {
    // 组织更新内容
    final Map<String, dynamic> updateFields = {};

    if (subject != null) {
      updateFields["subject"] = subject;
    }

    if (to != null) {
      updateFields["to"] = to.map((e) => {"email": e}).toList();
    }
    if (cc != null) {
      updateFields["cc"] = cc.map((e) => {"email": e}).toList();
    }
    if (bcc != null) {
      updateFields["bcc"] = bcc.map((e) => {"email": e}).toList();
    }

    // 处理正文（text 或 html）
    if (textBody != null || htmlBody != null) {
      updateFields["bodyValues"] = {
        "body": {
          "value": htmlBody ?? textBody,
          "isTruncated": false
        }
      };

      if (textBody != null) {
        updateFields["textBody"] = [
          {"partId": "body"}
        ];
      }

      if (htmlBody != null) {
        updateFields["htmlBody"] = [
          {"partId": "body"}
        ];
      }
    }

    final methods = [
      [
        "Email/set",
        {
          "accountId": session.accountId,
          "update": {
            emailId: updateFields
          }
        },
        "c1"
      ]
    ];
    await jmapMailCall(methods);
  }

  Future<String> getInitialEmailState({ bool needCache = true }) async {
    /*
    final methods = [
      [
        "Email/get",
        {
          "ids": null,
          "properties": ["id"],
          "sort": [{ "property": "receivedAt", "isAscending": false }]
        },
        "c1"
      ]
    ];
    */
    final methods = [
      [
        "Email/query",
        {
          "accountId": session.accountId,
          "sort": [{ "property": "receivedAt", "isAscending": false }],
          "limit": 1
        },
        "c1"
      ],
      [
        "Email/get",
        {
          "accountId": session.accountId,
          "#ids": {
            "resultOf": "c1",
            "name": "Email/query",
            "path": "/ids/0"
          },
          "properties": [
            "id"
          ]
        },
        "c2"
      ]
    ];

    final results = await jmapMailCall(methods);
    //final emailState = results[0][1]["state"];
    final emailState = results[1][1]["state"];
    if (needCache && emailState != null) {
      session.lastEmailState = emailState;
    }
    return emailState;
  }

  Future<List<String>> checkNewMessages() async {
    if (session.lastEmailState == null) {
      await getInitialEmailState();
    }
    final methods = [
      [
        "Email/changes",
        {
          "accountId": session.accountId,
          "sinceState": session.lastEmailState
        },
        "c1"
      ]
    ];
    final results = await jmapMailCall(methods);
    //final methodName = results[0][0];
    final methodResult = results[0][1];
    session.lastEmailState = methodResult["newState"];
    final newEmailIds = methodResult["created"];
    return (newEmailIds as List?)?.map((e) => e.toString()).toList() ?? [];
  }
}
