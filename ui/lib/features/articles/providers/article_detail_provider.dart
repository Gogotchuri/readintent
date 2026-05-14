import "package:readintent_flutter/features/articles/repository/article_repository.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart" as articles_pb;
import "package:riverpod_annotation/riverpod_annotation.dart";

part "article_detail_provider.g.dart";

@riverpod
// Used for fetching article details and keeping it
// updated if ti changes
class ArticleDetail extends _$ArticleDetail {
  @override
  Future<articles_pb.Article> build(String id) async {
    final repository = ref.read(articleRepositoryProvider);
    final article = await repository.getArticle(
      id,
      onUpdated: (updated) {
        // We override the state with the updated article if it was delivered after we have used the cached one
        state = AsyncData(updated);
      },
    );
    if (article == null) {
      throw Exception("Article content not available offline");
    }
    return article;
  }
}
