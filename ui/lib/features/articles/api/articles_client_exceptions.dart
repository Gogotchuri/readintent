import "package:connectrpc/connect.dart";

class ArticlesException implements Exception {
  final String message;
  const ArticlesException(this.message);
  @override
  String toString() => message;
}

Never handleArticlesConnectException(ConnectException e, String context) {
  throw ArticlesException("Failed to $context: ${e.message}");
}