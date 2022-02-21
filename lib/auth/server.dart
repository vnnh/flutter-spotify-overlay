import 'dart:io';

Future<HttpServer> startReceiveServer() async {
  var server = await HttpServer.bind(InternetAddress.loopbackIPv4, 3003);
  return server;
}

typedef void SuccessFn(String code);
typedef bool StateCheckFn(String givenState);
typedef Future<void> CloseServerFn();

Future<void> listenToServer(HttpServer server, SuccessFn successFn,
    StateCheckFn stateCheck, CloseServerFn closeServer) async {
  await for (var request in server) {
    final requestUri = request.uri;
    if (requestUri.queryParameters["state"] != null &&
        stateCheck(requestUri.queryParameters["state"]!)) {
      request.response
        ..headers.contentType = ContentType("text", "html", charset: "utf-8")
        ..write("<script>window.close();</script>")
        ..close();

      successFn(requestUri.queryParameters["code"]!);

      closeServer();
    } else {
      request.response
        ..headers.contentType = ContentType("text", "plain", charset: "utf-8")
        ..write("State mismatch!")
        ..close();
    }
  }

  print("Finished listening to server");
}
