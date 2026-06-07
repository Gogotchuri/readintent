import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart"
    as articles_pb;
import "package:readintent_flutter/proto/articles/v1/articles_service.pbenum.dart"
    as pb;

enum ArticleListState {
  inbox,
  archive;

  static const dbInbox = "inbox";
  static const dbArchive = "archive";

  String get db => this == ArticleListState.archive ? dbArchive : dbInbox;

  pb.ArticleListState get proto => this == ArticleListState.archive
      ? pb.ArticleListState.ARTICLE_LIST_STATE_ARCHIVE
      : pb.ArticleListState.ARTICLE_LIST_STATE_INBOX;

  static ArticleListState fromProto(pb.ArticleListState v) =>
      v == pb.ArticleListState.ARTICLE_LIST_STATE_ARCHIVE
      ? ArticleListState.archive
      : ArticleListState.inbox;

  static ArticleListState fromDb(String v) =>
      v == dbArchive ? ArticleListState.archive : ArticleListState.inbox;
}

/// One of the three article lists shown as a bottom-nav destination. Inbox and
/// Archive map to [ArticleListState]; Favorite spans both lists.
enum ArticleView {
  inbox,
  favorite,
  archive;

  pb.ArticleView get proto => switch (this) {
    ArticleView.inbox => pb.ArticleView.ARTICLE_VIEW_INBOX,
    ArticleView.favorite => pb.ArticleView.ARTICLE_VIEW_FAVORITE,
    ArticleView.archive => pb.ArticleView.ARTICLE_VIEW_ARCHIVE,
  };

  bool contains(articles_pb.ArticlePreview preview) => switch (this) {
    ArticleView.inbox =>
      preview.listState != pb.ArticleListState.ARTICLE_LIST_STATE_ARCHIVE,
    ArticleView.archive =>
      preview.listState == pb.ArticleListState.ARTICLE_LIST_STATE_ARCHIVE,
    ArticleView.favorite => preview.isFavorite,
  };
}
