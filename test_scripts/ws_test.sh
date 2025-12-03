# 1. 运行命令websocat
websocat -H="Authorization: Basic $(echo -n '<user>:<pass>' | base64)" wss://mail.incontrol.chat/jmap/ws

# 2. 在控制台输入如下JMAP请求：
{"@type":"Request","requestId":"c2","using":["urn:ietf:params:jmap:core","urn:ietf:params:jmap:mail"],"methodCalls":[["Email/query",{"limit":5},"c2"]]}
# 3. 控制台将返回如下类似响应：
{"@type":"Response","methodResponses":[["Email/query",{"accountId":"c","queryState":"smq","canCalculateChanges":true,"position":0,"ids":["e2aaaabh","eyaaaabg","euaaaabf","eqaaaabe","emaaaabd"],"limit":5},"c2"]],"sessionState":"3e25b2a0"}

# 邮件订阅请求(Stalwart不支持)
{"@type":"Request", "requestId":"c1","using":["urn:ietf:params:jmap:core"],"methodCalls":[["WebSocket/register",{"caps":["urn:ietf:params:jmap:mail"]},"c1"]]}
{"@type":"Request", "requestId":"c2","using":["urn:ietf:params:jmap:core","urn:ietf:params:jmap:mail"],"methodCalls":[["PushSubscription/set",{"create":{"s1":{"deviceClientId":"dev1","types":["Email"],"verifyCode":"x","url":"ws"}}},"c2"]]}

# Echo (Stalwart tested)
# request:
{ "@type":"Request", "requestId":"c1", "using": ["urn:ietf:params:jmap:core"], "methodCalls": [ ["Core/echo", {"hello": "world"}, "c1"] ] }
# response:
{"@type":"Response","methodResponses":[["Core/echo",{"hello":"world"},"c1"]],"sessionState":"3e25b2a0"}
