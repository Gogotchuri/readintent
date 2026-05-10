import "package:readintent_flutter/features/articles/api/articles_client.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart" as articles_pb;
import "package:riverpod_annotation/riverpod_annotation.dart";

part "article_detail_provider.g.dart";

@riverpod
Future<articles_pb.Article> articleDetail(Ref ref, String id) async {
  final client = ref.read(articlesServiceProvider);
  return client.getArticle(id);
}
