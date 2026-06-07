//
//  Generated code. Do not modify.
//  source: articles/v1/articles_service.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Which list an article lives in. inbox and archive are mutually exclusive;
/// favorite is an orthogonal flag (see is_favorite), not part of this enum.
class ArticleListState extends $pb.ProtobufEnum {
  static const ArticleListState ARTICLE_LIST_STATE_UNSPECIFIED =
      ArticleListState._(
          0, _omitEnumNames ? '' : 'ARTICLE_LIST_STATE_UNSPECIFIED');
  static const ArticleListState ARTICLE_LIST_STATE_INBOX =
      ArticleListState._(1, _omitEnumNames ? '' : 'ARTICLE_LIST_STATE_INBOX');
  static const ArticleListState ARTICLE_LIST_STATE_ARCHIVE =
      ArticleListState._(2, _omitEnumNames ? '' : 'ARTICLE_LIST_STATE_ARCHIVE');

  static const $core.List<ArticleListState> values = <ArticleListState>[
    ARTICLE_LIST_STATE_UNSPECIFIED,
    ARTICLE_LIST_STATE_INBOX,
    ARTICLE_LIST_STATE_ARCHIVE,
  ];

  static final $core.Map<$core.int, ArticleListState> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static ArticleListState? valueOf($core.int value) => _byValue[value];

  const ArticleListState._($core.int v, $core.String n) : super(v, n);
}

/// The view a GetArticles call is filtering for. favorite spans both inbox and
/// archive (any article with is_favorite set).
class ArticleView extends $pb.ProtobufEnum {
  static const ArticleView ARTICLE_VIEW_UNSPECIFIED =
      ArticleView._(0, _omitEnumNames ? '' : 'ARTICLE_VIEW_UNSPECIFIED');
  static const ArticleView ARTICLE_VIEW_INBOX =
      ArticleView._(1, _omitEnumNames ? '' : 'ARTICLE_VIEW_INBOX');
  static const ArticleView ARTICLE_VIEW_FAVORITE =
      ArticleView._(2, _omitEnumNames ? '' : 'ARTICLE_VIEW_FAVORITE');
  static const ArticleView ARTICLE_VIEW_ARCHIVE =
      ArticleView._(3, _omitEnumNames ? '' : 'ARTICLE_VIEW_ARCHIVE');

  static const $core.List<ArticleView> values = <ArticleView>[
    ARTICLE_VIEW_UNSPECIFIED,
    ARTICLE_VIEW_INBOX,
    ARTICLE_VIEW_FAVORITE,
    ARTICLE_VIEW_ARCHIVE,
  ];

  static final $core.Map<$core.int, ArticleView> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static ArticleView? valueOf($core.int value) => _byValue[value];

  const ArticleView._($core.int v, $core.String n) : super(v, n);
}

const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
