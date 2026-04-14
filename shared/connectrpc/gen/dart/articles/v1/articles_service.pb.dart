//
//  Generated code. Do not modify.
//  source: articles/v1/articles_service.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class PhonemizerTokenMeta extends $pb.GeneratedMessage {
  factory PhonemizerTokenMeta({
    $core.String? text,
    $core.int? phonemeLen,
    $core.bool? hasWhitespace,
  }) {
    final $result = create();
    if (text != null) {
      $result.text = text;
    }
    if (phonemeLen != null) {
      $result.phonemeLen = phonemeLen;
    }
    if (hasWhitespace != null) {
      $result.hasWhitespace = hasWhitespace;
    }
    return $result;
  }
  PhonemizerTokenMeta._() : super();
  factory PhonemizerTokenMeta.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PhonemizerTokenMeta.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PhonemizerTokenMeta', package: const $pb.PackageName(_omitMessageNames ? '' : 'articles.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'phonemeLen', $pb.PbFieldType.OU3)
    ..aOB(3, _omitFieldNames ? '' : 'hasWhitespace')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PhonemizerTokenMeta clone() => PhonemizerTokenMeta()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PhonemizerTokenMeta copyWith(void Function(PhonemizerTokenMeta) updates) => super.copyWith((message) => updates(message as PhonemizerTokenMeta)) as PhonemizerTokenMeta;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PhonemizerTokenMeta create() => PhonemizerTokenMeta._();
  PhonemizerTokenMeta createEmptyInstance() => create();
  static $pb.PbList<PhonemizerTokenMeta> createRepeated() => $pb.PbList<PhonemizerTokenMeta>();
  @$core.pragma('dart2js:noInline')
  static PhonemizerTokenMeta getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PhonemizerTokenMeta>(create);
  static PhonemizerTokenMeta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get phonemeLen => $_getIZ(1);
  @$pb.TagNumber(2)
  set phonemeLen($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPhonemeLen() => $_has(1);
  @$pb.TagNumber(2)
  void clearPhonemeLen() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get hasWhitespace => $_getBF(2);
  @$pb.TagNumber(3)
  set hasWhitespace($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasHasWhitespace() => $_has(2);
  @$pb.TagNumber(3)
  void clearHasWhitespace() => clearField(3);
}

class PhonemizerData extends $pb.GeneratedMessage {
  factory PhonemizerData({
    $core.String? graphemes,
    $core.String? phonemes,
    $core.Iterable<$fixnum.Int64>? tokenIds,
    $core.Iterable<PhonemizerTokenMeta>? tokenMeta,
  }) {
    final $result = create();
    if (graphemes != null) {
      $result.graphemes = graphemes;
    }
    if (phonemes != null) {
      $result.phonemes = phonemes;
    }
    if (tokenIds != null) {
      $result.tokenIds.addAll(tokenIds);
    }
    if (tokenMeta != null) {
      $result.tokenMeta.addAll(tokenMeta);
    }
    return $result;
  }
  PhonemizerData._() : super();
  factory PhonemizerData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PhonemizerData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PhonemizerData', package: const $pb.PackageName(_omitMessageNames ? '' : 'articles.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'graphemes')
    ..aOS(2, _omitFieldNames ? '' : 'phonemes')
    ..p<$fixnum.Int64>(3, _omitFieldNames ? '' : 'tokenIds', $pb.PbFieldType.K6)
    ..pc<PhonemizerTokenMeta>(4, _omitFieldNames ? '' : 'tokenMeta', $pb.PbFieldType.PM, subBuilder: PhonemizerTokenMeta.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PhonemizerData clone() => PhonemizerData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PhonemizerData copyWith(void Function(PhonemizerData) updates) => super.copyWith((message) => updates(message as PhonemizerData)) as PhonemizerData;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PhonemizerData create() => PhonemizerData._();
  PhonemizerData createEmptyInstance() => create();
  static $pb.PbList<PhonemizerData> createRepeated() => $pb.PbList<PhonemizerData>();
  @$core.pragma('dart2js:noInline')
  static PhonemizerData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PhonemizerData>(create);
  static PhonemizerData? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get graphemes => $_getSZ(0);
  @$pb.TagNumber(1)
  set graphemes($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGraphemes() => $_has(0);
  @$pb.TagNumber(1)
  void clearGraphemes() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get phonemes => $_getSZ(1);
  @$pb.TagNumber(2)
  set phonemes($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPhonemes() => $_has(1);
  @$pb.TagNumber(2)
  void clearPhonemes() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$fixnum.Int64> get tokenIds => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<PhonemizerTokenMeta> get tokenMeta => $_getList(3);
}

class ArticlePreview extends $pb.GeneratedMessage {
  factory ArticlePreview({
    $core.String? id,
    $core.String? status,
    $core.String? title,
    $core.String? author,
    $core.String? date,
    $core.String? url,
    $core.Iterable<$core.String>? categories,
    $core.String? description,
    $core.String? image,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (status != null) {
      $result.status = status;
    }
    if (title != null) {
      $result.title = title;
    }
    if (author != null) {
      $result.author = author;
    }
    if (date != null) {
      $result.date = date;
    }
    if (url != null) {
      $result.url = url;
    }
    if (categories != null) {
      $result.categories.addAll(categories);
    }
    if (description != null) {
      $result.description = description;
    }
    if (image != null) {
      $result.image = image;
    }
    return $result;
  }
  ArticlePreview._() : super();
  factory ArticlePreview.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ArticlePreview.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ArticlePreview', package: const $pb.PackageName(_omitMessageNames ? '' : 'articles.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'status')
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aOS(4, _omitFieldNames ? '' : 'author')
    ..aOS(5, _omitFieldNames ? '' : 'date')
    ..aOS(6, _omitFieldNames ? '' : 'url')
    ..pPS(7, _omitFieldNames ? '' : 'categories')
    ..aOS(8, _omitFieldNames ? '' : 'description')
    ..aOS(9, _omitFieldNames ? '' : 'image')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ArticlePreview clone() => ArticlePreview()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ArticlePreview copyWith(void Function(ArticlePreview) updates) => super.copyWith((message) => updates(message as ArticlePreview)) as ArticlePreview;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArticlePreview create() => ArticlePreview._();
  ArticlePreview createEmptyInstance() => create();
  static $pb.PbList<ArticlePreview> createRepeated() => $pb.PbList<ArticlePreview>();
  @$core.pragma('dart2js:noInline')
  static ArticlePreview getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ArticlePreview>(create);
  static ArticlePreview? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  /// failed, started_gathering, text_ready, ready
  @$pb.TagNumber(2)
  $core.String get status => $_getSZ(1);
  @$pb.TagNumber(2)
  set status($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(2);
  @$pb.TagNumber(3)
  set title($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitle() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get author => $_getSZ(3);
  @$pb.TagNumber(4)
  set author($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasAuthor() => $_has(3);
  @$pb.TagNumber(4)
  void clearAuthor() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get date => $_getSZ(4);
  @$pb.TagNumber(5)
  set date($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasDate() => $_has(4);
  @$pb.TagNumber(5)
  void clearDate() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get url => $_getSZ(5);
  @$pb.TagNumber(6)
  set url($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasUrl() => $_has(5);
  @$pb.TagNumber(6)
  void clearUrl() => clearField(6);

  @$pb.TagNumber(7)
  $core.List<$core.String> get categories => $_getList(6);

  /// If the description failed to be extracted from the metadata,
  /// we should add put the first few hundred characters in
  @$pb.TagNumber(8)
  $core.String get description => $_getSZ(7);
  @$pb.TagNumber(8)
  set description($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasDescription() => $_has(7);
  @$pb.TagNumber(8)
  void clearDescription() => clearField(8);

  @$pb.TagNumber(9)
  $core.String get image => $_getSZ(8);
  @$pb.TagNumber(9)
  set image($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasImage() => $_has(8);
  @$pb.TagNumber(9)
  void clearImage() => clearField(9);
}

/// Full article with all content
class Article extends $pb.GeneratedMessage {
  factory Article({
    $core.String? id,
    $core.String? status,
    $core.String? title,
    $core.String? author,
    $core.String? date,
    $core.String? extractedHtml,
    $core.String? pureText,
    $core.String? url,
    $core.Iterable<$core.String>? categories,
    $core.String? description,
    $core.String? image,
    PhonemizerData? phonemizerData,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (status != null) {
      $result.status = status;
    }
    if (title != null) {
      $result.title = title;
    }
    if (author != null) {
      $result.author = author;
    }
    if (date != null) {
      $result.date = date;
    }
    if (extractedHtml != null) {
      $result.extractedHtml = extractedHtml;
    }
    if (pureText != null) {
      $result.pureText = pureText;
    }
    if (url != null) {
      $result.url = url;
    }
    if (categories != null) {
      $result.categories.addAll(categories);
    }
    if (description != null) {
      $result.description = description;
    }
    if (image != null) {
      $result.image = image;
    }
    if (phonemizerData != null) {
      $result.phonemizerData = phonemizerData;
    }
    return $result;
  }
  Article._() : super();
  factory Article.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Article.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Article', package: const $pb.PackageName(_omitMessageNames ? '' : 'articles.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'status')
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aOS(4, _omitFieldNames ? '' : 'author')
    ..aOS(5, _omitFieldNames ? '' : 'date')
    ..aOS(6, _omitFieldNames ? '' : 'extractedHtml')
    ..aOS(7, _omitFieldNames ? '' : 'pureText')
    ..aOS(8, _omitFieldNames ? '' : 'url')
    ..pPS(9, _omitFieldNames ? '' : 'categories')
    ..aOS(10, _omitFieldNames ? '' : 'description')
    ..aOS(11, _omitFieldNames ? '' : 'image')
    ..aOM<PhonemizerData>(12, _omitFieldNames ? '' : 'phonemizerData', subBuilder: PhonemizerData.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Article clone() => Article()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Article copyWith(void Function(Article) updates) => super.copyWith((message) => updates(message as Article)) as Article;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Article create() => Article._();
  Article createEmptyInstance() => create();
  static $pb.PbList<Article> createRepeated() => $pb.PbList<Article>();
  @$core.pragma('dart2js:noInline')
  static Article getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Article>(create);
  static Article? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  /// failed, started_gathering, text_ready, ready
  @$pb.TagNumber(2)
  $core.String get status => $_getSZ(1);
  @$pb.TagNumber(2)
  set status($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(2);
  @$pb.TagNumber(3)
  set title($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitle() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get author => $_getSZ(3);
  @$pb.TagNumber(4)
  set author($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasAuthor() => $_has(3);
  @$pb.TagNumber(4)
  void clearAuthor() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get date => $_getSZ(4);
  @$pb.TagNumber(5)
  set date($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasDate() => $_has(4);
  @$pb.TagNumber(5)
  void clearDate() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get extractedHtml => $_getSZ(5);
  @$pb.TagNumber(6)
  set extractedHtml($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasExtractedHtml() => $_has(5);
  @$pb.TagNumber(6)
  void clearExtractedHtml() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get pureText => $_getSZ(6);
  @$pb.TagNumber(7)
  set pureText($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasPureText() => $_has(6);
  @$pb.TagNumber(7)
  void clearPureText() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get url => $_getSZ(7);
  @$pb.TagNumber(8)
  set url($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasUrl() => $_has(7);
  @$pb.TagNumber(8)
  void clearUrl() => clearField(8);

  @$pb.TagNumber(9)
  $core.List<$core.String> get categories => $_getList(8);

  @$pb.TagNumber(10)
  $core.String get description => $_getSZ(9);
  @$pb.TagNumber(10)
  set description($core.String v) { $_setString(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasDescription() => $_has(9);
  @$pb.TagNumber(10)
  void clearDescription() => clearField(10);

  @$pb.TagNumber(11)
  $core.String get image => $_getSZ(10);
  @$pb.TagNumber(11)
  set image($core.String v) { $_setString(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasImage() => $_has(10);
  @$pb.TagNumber(11)
  void clearImage() => clearField(11);

  @$pb.TagNumber(12)
  PhonemizerData get phonemizerData => $_getN(11);
  @$pb.TagNumber(12)
  set phonemizerData(PhonemizerData v) { setField(12, v); }
  @$pb.TagNumber(12)
  $core.bool hasPhonemizerData() => $_has(11);
  @$pb.TagNumber(12)
  void clearPhonemizerData() => clearField(12);
  @$pb.TagNumber(12)
  PhonemizerData ensurePhonemizerData() => $_ensure(11);
}

class GetArticlesRequest extends $pb.GeneratedMessage {
  factory GetArticlesRequest({
    $core.int? pageSize,
    $core.String? pageToken,
    $core.Iterable<$core.String>? categories,
    $core.String? searchQuery,
    $core.String? author,
  }) {
    final $result = create();
    if (pageSize != null) {
      $result.pageSize = pageSize;
    }
    if (pageToken != null) {
      $result.pageToken = pageToken;
    }
    if (categories != null) {
      $result.categories.addAll(categories);
    }
    if (searchQuery != null) {
      $result.searchQuery = searchQuery;
    }
    if (author != null) {
      $result.author = author;
    }
    return $result;
  }
  GetArticlesRequest._() : super();
  factory GetArticlesRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetArticlesRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetArticlesRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'articles.v1'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'pageSize', $pb.PbFieldType.O3)
    ..aOS(2, _omitFieldNames ? '' : 'pageToken')
    ..pPS(3, _omitFieldNames ? '' : 'categories')
    ..aOS(4, _omitFieldNames ? '' : 'searchQuery')
    ..aOS(5, _omitFieldNames ? '' : 'author')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetArticlesRequest clone() => GetArticlesRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetArticlesRequest copyWith(void Function(GetArticlesRequest) updates) => super.copyWith((message) => updates(message as GetArticlesRequest)) as GetArticlesRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetArticlesRequest create() => GetArticlesRequest._();
  GetArticlesRequest createEmptyInstance() => create();
  static $pb.PbList<GetArticlesRequest> createRepeated() => $pb.PbList<GetArticlesRequest>();
  @$core.pragma('dart2js:noInline')
  static GetArticlesRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetArticlesRequest>(create);
  static GetArticlesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get pageSize => $_getIZ(0);
  @$pb.TagNumber(1)
  set pageSize($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPageSize() => $_has(0);
  @$pb.TagNumber(1)
  void clearPageSize() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get pageToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set pageToken($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPageToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearPageToken() => clearField(2);

  /// Optional filters
  @$pb.TagNumber(3)
  $core.List<$core.String> get categories => $_getList(2);

  @$pb.TagNumber(4)
  $core.String get searchQuery => $_getSZ(3);
  @$pb.TagNumber(4)
  set searchQuery($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasSearchQuery() => $_has(3);
  @$pb.TagNumber(4)
  void clearSearchQuery() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get author => $_getSZ(4);
  @$pb.TagNumber(5)
  set author($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasAuthor() => $_has(4);
  @$pb.TagNumber(5)
  void clearAuthor() => clearField(5);
}

class GetArticlesResponse extends $pb.GeneratedMessage {
  factory GetArticlesResponse({
    $core.Iterable<ArticlePreview>? articles,
    $core.String? nextPageToken,
    $core.int? totalCount,
  }) {
    final $result = create();
    if (articles != null) {
      $result.articles.addAll(articles);
    }
    if (nextPageToken != null) {
      $result.nextPageToken = nextPageToken;
    }
    if (totalCount != null) {
      $result.totalCount = totalCount;
    }
    return $result;
  }
  GetArticlesResponse._() : super();
  factory GetArticlesResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetArticlesResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetArticlesResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'articles.v1'), createEmptyInstance: create)
    ..pc<ArticlePreview>(1, _omitFieldNames ? '' : 'articles', $pb.PbFieldType.PM, subBuilder: ArticlePreview.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'totalCount', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetArticlesResponse clone() => GetArticlesResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetArticlesResponse copyWith(void Function(GetArticlesResponse) updates) => super.copyWith((message) => updates(message as GetArticlesResponse)) as GetArticlesResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetArticlesResponse create() => GetArticlesResponse._();
  GetArticlesResponse createEmptyInstance() => create();
  static $pb.PbList<GetArticlesResponse> createRepeated() => $pb.PbList<GetArticlesResponse>();
  @$core.pragma('dart2js:noInline')
  static GetArticlesResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetArticlesResponse>(create);
  static GetArticlesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<ArticlePreview> get articles => $_getList(0);

  /// Token for the cursor based pagination
  @$pb.TagNumber(2)
  $core.String get nextPageToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextPageToken($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasNextPageToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextPageToken() => clearField(2);

  /// Total number of articles matching the query
  @$pb.TagNumber(3)
  $core.int get totalCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set totalCount($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTotalCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotalCount() => clearField(3);
}

class GetArticleRequest extends $pb.GeneratedMessage {
  factory GetArticleRequest({
    $core.String? id,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    return $result;
  }
  GetArticleRequest._() : super();
  factory GetArticleRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetArticleRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetArticleRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'articles.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetArticleRequest clone() => GetArticleRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetArticleRequest copyWith(void Function(GetArticleRequest) updates) => super.copyWith((message) => updates(message as GetArticleRequest)) as GetArticleRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetArticleRequest create() => GetArticleRequest._();
  GetArticleRequest createEmptyInstance() => create();
  static $pb.PbList<GetArticleRequest> createRepeated() => $pb.PbList<GetArticleRequest>();
  @$core.pragma('dart2js:noInline')
  static GetArticleRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetArticleRequest>(create);
  static GetArticleRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);
}

class GetArticleResponse extends $pb.GeneratedMessage {
  factory GetArticleResponse({
    Article? article,
  }) {
    final $result = create();
    if (article != null) {
      $result.article = article;
    }
    return $result;
  }
  GetArticleResponse._() : super();
  factory GetArticleResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetArticleResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetArticleResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'articles.v1'), createEmptyInstance: create)
    ..aOM<Article>(1, _omitFieldNames ? '' : 'article', subBuilder: Article.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetArticleResponse clone() => GetArticleResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetArticleResponse copyWith(void Function(GetArticleResponse) updates) => super.copyWith((message) => updates(message as GetArticleResponse)) as GetArticleResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetArticleResponse create() => GetArticleResponse._();
  GetArticleResponse createEmptyInstance() => create();
  static $pb.PbList<GetArticleResponse> createRepeated() => $pb.PbList<GetArticleResponse>();
  @$core.pragma('dart2js:noInline')
  static GetArticleResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetArticleResponse>(create);
  static GetArticleResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Article get article => $_getN(0);
  @$pb.TagNumber(1)
  set article(Article v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasArticle() => $_has(0);
  @$pb.TagNumber(1)
  void clearArticle() => clearField(1);
  @$pb.TagNumber(1)
  Article ensureArticle() => $_ensure(0);
}

class ParseArticleRequest extends $pb.GeneratedMessage {
  factory ParseArticleRequest({
    $core.String? url,
  }) {
    final $result = create();
    if (url != null) {
      $result.url = url;
    }
    return $result;
  }
  ParseArticleRequest._() : super();
  factory ParseArticleRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ParseArticleRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ParseArticleRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'articles.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'url')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ParseArticleRequest clone() => ParseArticleRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ParseArticleRequest copyWith(void Function(ParseArticleRequest) updates) => super.copyWith((message) => updates(message as ParseArticleRequest)) as ParseArticleRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ParseArticleRequest create() => ParseArticleRequest._();
  ParseArticleRequest createEmptyInstance() => create();
  static $pb.PbList<ParseArticleRequest> createRepeated() => $pb.PbList<ParseArticleRequest>();
  @$core.pragma('dart2js:noInline')
  static ParseArticleRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ParseArticleRequest>(create);
  static ParseArticleRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get url => $_getSZ(0);
  @$pb.TagNumber(1)
  set url($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearUrl() => clearField(1);
}

class ParseArticleResponse extends $pb.GeneratedMessage {
  factory ParseArticleResponse() => create();
  ParseArticleResponse._() : super();
  factory ParseArticleResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ParseArticleResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ParseArticleResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'articles.v1'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ParseArticleResponse clone() => ParseArticleResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ParseArticleResponse copyWith(void Function(ParseArticleResponse) updates) => super.copyWith((message) => updates(message as ParseArticleResponse)) as ParseArticleResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ParseArticleResponse create() => ParseArticleResponse._();
  ParseArticleResponse createEmptyInstance() => create();
  static $pb.PbList<ParseArticleResponse> createRepeated() => $pb.PbList<ParseArticleResponse>();
  @$core.pragma('dart2js:noInline')
  static ParseArticleResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ParseArticleResponse>(create);
  static ParseArticleResponse? _defaultInstance;
}

class DeleteArticleRequest extends $pb.GeneratedMessage {
  factory DeleteArticleRequest({
    $core.String? id,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    return $result;
  }
  DeleteArticleRequest._() : super();
  factory DeleteArticleRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeleteArticleRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeleteArticleRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'articles.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeleteArticleRequest clone() => DeleteArticleRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeleteArticleRequest copyWith(void Function(DeleteArticleRequest) updates) => super.copyWith((message) => updates(message as DeleteArticleRequest)) as DeleteArticleRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteArticleRequest create() => DeleteArticleRequest._();
  DeleteArticleRequest createEmptyInstance() => create();
  static $pb.PbList<DeleteArticleRequest> createRepeated() => $pb.PbList<DeleteArticleRequest>();
  @$core.pragma('dart2js:noInline')
  static DeleteArticleRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeleteArticleRequest>(create);
  static DeleteArticleRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);
}

class DeleteArticleResponse extends $pb.GeneratedMessage {
  factory DeleteArticleResponse() => create();
  DeleteArticleResponse._() : super();
  factory DeleteArticleResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeleteArticleResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeleteArticleResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'articles.v1'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeleteArticleResponse clone() => DeleteArticleResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeleteArticleResponse copyWith(void Function(DeleteArticleResponse) updates) => super.copyWith((message) => updates(message as DeleteArticleResponse)) as DeleteArticleResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteArticleResponse create() => DeleteArticleResponse._();
  DeleteArticleResponse createEmptyInstance() => create();
  static $pb.PbList<DeleteArticleResponse> createRepeated() => $pb.PbList<DeleteArticleResponse>();
  @$core.pragma('dart2js:noInline')
  static DeleteArticleResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeleteArticleResponse>(create);
  static DeleteArticleResponse? _defaultInstance;
}

class ArticlesServiceApi {
  $pb.RpcClient _client;
  ArticlesServiceApi(this._client);

  $async.Future<ParseArticleResponse> parseArticle($pb.ClientContext? ctx, ParseArticleRequest request) =>
    _client.invoke<ParseArticleResponse>(ctx, 'ArticlesService', 'ParseArticle', request, ParseArticleResponse())
  ;
  $async.Future<GetArticlesResponse> getArticles($pb.ClientContext? ctx, GetArticlesRequest request) =>
    _client.invoke<GetArticlesResponse>(ctx, 'ArticlesService', 'GetArticles', request, GetArticlesResponse())
  ;
  $async.Future<GetArticleResponse> getArticle($pb.ClientContext? ctx, GetArticleRequest request) =>
    _client.invoke<GetArticleResponse>(ctx, 'ArticlesService', 'GetArticle', request, GetArticleResponse())
  ;
  $async.Future<DeleteArticleResponse> deleteArticle($pb.ClientContext? ctx, DeleteArticleRequest request) =>
    _client.invoke<DeleteArticleResponse>(ctx, 'ArticlesService', 'DeleteArticle', request, DeleteArticleResponse())
  ;
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
