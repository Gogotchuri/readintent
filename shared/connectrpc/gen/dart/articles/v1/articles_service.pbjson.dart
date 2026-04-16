//
//  Generated code. Do not modify.
//  source: articles/v1/articles_service.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use phonemizerTokenMetaDescriptor instead')
const PhonemizerTokenMeta$json = {
  '1': 'PhonemizerTokenMeta',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {'1': 'phoneme_len', '3': 2, '4': 1, '5': 13, '10': 'phonemeLen'},
    {'1': 'has_whitespace', '3': 3, '4': 1, '5': 8, '10': 'hasWhitespace'},
  ],
};

/// Descriptor for `PhonemizerTokenMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List phonemizerTokenMetaDescriptor = $convert.base64Decode(
    'ChNQaG9uZW1pemVyVG9rZW5NZXRhEhIKBHRleHQYASABKAlSBHRleHQSHwoLcGhvbmVtZV9sZW'
    '4YAiABKA1SCnBob25lbWVMZW4SJQoOaGFzX3doaXRlc3BhY2UYAyABKAhSDWhhc1doaXRlc3Bh'
    'Y2U=');

@$core.Deprecated('Use phonemizerDataDescriptor instead')
const PhonemizerData$json = {
  '1': 'PhonemizerData',
  '2': [
    {'1': 'graphemes', '3': 1, '4': 1, '5': 9, '10': 'graphemes'},
    {'1': 'phonemes', '3': 2, '4': 1, '5': 9, '10': 'phonemes'},
    {'1': 'token_ids', '3': 3, '4': 3, '5': 3, '10': 'tokenIds'},
    {'1': 'token_meta', '3': 4, '4': 3, '5': 11, '6': '.articles.v1.PhonemizerTokenMeta', '10': 'tokenMeta'},
  ],
};

/// Descriptor for `PhonemizerData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List phonemizerDataDescriptor = $convert.base64Decode(
    'Cg5QaG9uZW1pemVyRGF0YRIcCglncmFwaGVtZXMYASABKAlSCWdyYXBoZW1lcxIaCghwaG9uZW'
    '1lcxgCIAEoCVIIcGhvbmVtZXMSGwoJdG9rZW5faWRzGAMgAygDUgh0b2tlbklkcxI/Cgp0b2tl'
    'bl9tZXRhGAQgAygLMiAuYXJ0aWNsZXMudjEuUGhvbmVtaXplclRva2VuTWV0YVIJdG9rZW5NZX'
    'Rh');

@$core.Deprecated('Use articlePreviewDescriptor instead')
const ArticlePreview$json = {
  '1': 'ArticlePreview',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'status', '3': 2, '4': 1, '5': 9, '10': 'status'},
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'author', '3': 4, '4': 1, '5': 9, '10': 'author'},
    {'1': 'date', '3': 5, '4': 1, '5': 9, '10': 'date'},
    {'1': 'url', '3': 6, '4': 1, '5': 9, '10': 'url'},
    {'1': 'categories', '3': 7, '4': 3, '5': 9, '10': 'categories'},
    {'1': 'description', '3': 8, '4': 1, '5': 9, '9': 0, '10': 'description', '17': true},
    {'1': 'image', '3': 9, '4': 1, '5': 9, '9': 1, '10': 'image', '17': true},
  ],
  '8': [
    {'1': '_description'},
    {'1': '_image'},
  ],
};

/// Descriptor for `ArticlePreview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List articlePreviewDescriptor = $convert.base64Decode(
    'Cg5BcnRpY2xlUHJldmlldxIOCgJpZBgBIAEoA1ICaWQSFgoGc3RhdHVzGAIgASgJUgZzdGF0dX'
    'MSFAoFdGl0bGUYAyABKAlSBXRpdGxlEhYKBmF1dGhvchgEIAEoCVIGYXV0aG9yEhIKBGRhdGUY'
    'BSABKAlSBGRhdGUSEAoDdXJsGAYgASgJUgN1cmwSHgoKY2F0ZWdvcmllcxgHIAMoCVIKY2F0ZW'
    'dvcmllcxIlCgtkZXNjcmlwdGlvbhgIIAEoCUgAUgtkZXNjcmlwdGlvbogBARIZCgVpbWFnZRgJ'
    'IAEoCUgBUgVpbWFnZYgBAUIOCgxfZGVzY3JpcHRpb25CCAoGX2ltYWdl');

@$core.Deprecated('Use articleDescriptor instead')
const Article$json = {
  '1': 'Article',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'status', '3': 2, '4': 1, '5': 9, '10': 'status'},
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'author', '3': 4, '4': 1, '5': 9, '10': 'author'},
    {'1': 'date', '3': 5, '4': 1, '5': 9, '10': 'date'},
    {'1': 'extracted_html', '3': 6, '4': 1, '5': 9, '10': 'extractedHtml'},
    {'1': 'pure_text', '3': 7, '4': 1, '5': 9, '10': 'pureText'},
    {'1': 'url', '3': 8, '4': 1, '5': 9, '10': 'url'},
    {'1': 'categories', '3': 9, '4': 3, '5': 9, '10': 'categories'},
    {'1': 'description', '3': 10, '4': 1, '5': 9, '9': 0, '10': 'description', '17': true},
    {'1': 'image', '3': 11, '4': 1, '5': 9, '9': 1, '10': 'image', '17': true},
    {'1': 'phonemizer_data', '3': 12, '4': 1, '5': 11, '6': '.articles.v1.PhonemizerData', '9': 2, '10': 'phonemizerData', '17': true},
  ],
  '8': [
    {'1': '_description'},
    {'1': '_image'},
    {'1': '_phonemizer_data'},
  ],
};

/// Descriptor for `Article`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List articleDescriptor = $convert.base64Decode(
    'CgdBcnRpY2xlEg4KAmlkGAEgASgDUgJpZBIWCgZzdGF0dXMYAiABKAlSBnN0YXR1cxIUCgV0aX'
    'RsZRgDIAEoCVIFdGl0bGUSFgoGYXV0aG9yGAQgASgJUgZhdXRob3ISEgoEZGF0ZRgFIAEoCVIE'
    'ZGF0ZRIlCg5leHRyYWN0ZWRfaHRtbBgGIAEoCVINZXh0cmFjdGVkSHRtbBIbCglwdXJlX3RleH'
    'QYByABKAlSCHB1cmVUZXh0EhAKA3VybBgIIAEoCVIDdXJsEh4KCmNhdGVnb3JpZXMYCSADKAlS'
    'CmNhdGVnb3JpZXMSJQoLZGVzY3JpcHRpb24YCiABKAlIAFILZGVzY3JpcHRpb26IAQESGQoFaW'
    '1hZ2UYCyABKAlIAVIFaW1hZ2WIAQESSQoPcGhvbmVtaXplcl9kYXRhGAwgASgLMhsuYXJ0aWNs'
    'ZXMudjEuUGhvbmVtaXplckRhdGFIAlIOcGhvbmVtaXplckRhdGGIAQFCDgoMX2Rlc2NyaXB0aW'
    '9uQggKBl9pbWFnZUISChBfcGhvbmVtaXplcl9kYXRh');

@$core.Deprecated('Use getArticlesRequestDescriptor instead')
const GetArticlesRequest$json = {
  '1': 'GetArticlesRequest',
  '2': [
    {'1': 'page_size', '3': 1, '4': 1, '5': 5, '10': 'pageSize'},
    {'1': 'page_token', '3': 2, '4': 1, '5': 9, '10': 'pageToken'},
    {'1': 'categories', '3': 3, '4': 3, '5': 9, '10': 'categories'},
    {'1': 'search_query', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'searchQuery', '17': true},
    {'1': 'author', '3': 5, '4': 1, '5': 9, '9': 1, '10': 'author', '17': true},
  ],
  '8': [
    {'1': '_search_query'},
    {'1': '_author'},
  ],
};

/// Descriptor for `GetArticlesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getArticlesRequestDescriptor = $convert.base64Decode(
    'ChJHZXRBcnRpY2xlc1JlcXVlc3QSGwoJcGFnZV9zaXplGAEgASgFUghwYWdlU2l6ZRIdCgpwYW'
    'dlX3Rva2VuGAIgASgJUglwYWdlVG9rZW4SHgoKY2F0ZWdvcmllcxgDIAMoCVIKY2F0ZWdvcmll'
    'cxImCgxzZWFyY2hfcXVlcnkYBCABKAlIAFILc2VhcmNoUXVlcnmIAQESGwoGYXV0aG9yGAUgAS'
    'gJSAFSBmF1dGhvcogBAUIPCg1fc2VhcmNoX3F1ZXJ5QgkKB19hdXRob3I=');

@$core.Deprecated('Use getArticlesResponseDescriptor instead')
const GetArticlesResponse$json = {
  '1': 'GetArticlesResponse',
  '2': [
    {'1': 'articles', '3': 1, '4': 3, '5': 11, '6': '.articles.v1.ArticlePreview', '10': 'articles'},
    {'1': 'next_page_token', '3': 2, '4': 1, '5': 9, '10': 'nextPageToken'},
    {'1': 'total_count', '3': 3, '4': 1, '5': 5, '10': 'totalCount'},
  ],
};

/// Descriptor for `GetArticlesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getArticlesResponseDescriptor = $convert.base64Decode(
    'ChNHZXRBcnRpY2xlc1Jlc3BvbnNlEjcKCGFydGljbGVzGAEgAygLMhsuYXJ0aWNsZXMudjEuQX'
    'J0aWNsZVByZXZpZXdSCGFydGljbGVzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBh'
    'Z2VUb2tlbhIfCgt0b3RhbF9jb3VudBgDIAEoBVIKdG90YWxDb3VudA==');

@$core.Deprecated('Use getArticleRequestDescriptor instead')
const GetArticleRequest$json = {
  '1': 'GetArticleRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `GetArticleRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getArticleRequestDescriptor = $convert.base64Decode(
    'ChFHZXRBcnRpY2xlUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQ=');

@$core.Deprecated('Use getArticleResponseDescriptor instead')
const GetArticleResponse$json = {
  '1': 'GetArticleResponse',
  '2': [
    {'1': 'article', '3': 1, '4': 1, '5': 11, '6': '.articles.v1.Article', '10': 'article'},
  ],
};

/// Descriptor for `GetArticleResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getArticleResponseDescriptor = $convert.base64Decode(
    'ChJHZXRBcnRpY2xlUmVzcG9uc2USLgoHYXJ0aWNsZRgBIAEoCzIULmFydGljbGVzLnYxLkFydG'
    'ljbGVSB2FydGljbGU=');

@$core.Deprecated('Use parseArticleRequestDescriptor instead')
const ParseArticleRequest$json = {
  '1': 'ParseArticleRequest',
  '2': [
    {'1': 'url', '3': 1, '4': 1, '5': 9, '10': 'url'},
  ],
};

/// Descriptor for `ParseArticleRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parseArticleRequestDescriptor = $convert.base64Decode(
    'ChNQYXJzZUFydGljbGVSZXF1ZXN0EhAKA3VybBgBIAEoCVIDdXJs');

@$core.Deprecated('Use parseArticleResponseDescriptor instead')
const ParseArticleResponse$json = {
  '1': 'ParseArticleResponse',
};

/// Descriptor for `ParseArticleResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parseArticleResponseDescriptor = $convert.base64Decode(
    'ChRQYXJzZUFydGljbGVSZXNwb25zZQ==');

@$core.Deprecated('Use deleteArticleRequestDescriptor instead')
const DeleteArticleRequest$json = {
  '1': 'DeleteArticleRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `DeleteArticleRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteArticleRequestDescriptor = $convert.base64Decode(
    'ChREZWxldGVBcnRpY2xlUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQ=');

@$core.Deprecated('Use deleteArticleResponseDescriptor instead')
const DeleteArticleResponse$json = {
  '1': 'DeleteArticleResponse',
};

/// Descriptor for `DeleteArticleResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteArticleResponseDescriptor = $convert.base64Decode(
    'ChVEZWxldGVBcnRpY2xlUmVzcG9uc2U=');

const $core.Map<$core.String, $core.dynamic> ArticlesServiceBase$json = {
  '1': 'ArticlesService',
  '2': [
    {'1': 'ParseArticle', '2': '.articles.v1.ParseArticleRequest', '3': '.articles.v1.ParseArticleResponse'},
    {'1': 'GetArticles', '2': '.articles.v1.GetArticlesRequest', '3': '.articles.v1.GetArticlesResponse'},
    {'1': 'GetArticle', '2': '.articles.v1.GetArticleRequest', '3': '.articles.v1.GetArticleResponse'},
    {'1': 'DeleteArticle', '2': '.articles.v1.DeleteArticleRequest', '3': '.articles.v1.DeleteArticleResponse'},
  ],
};

@$core.Deprecated('Use articlesServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> ArticlesServiceBase$messageJson = {
  '.articles.v1.ParseArticleRequest': ParseArticleRequest$json,
  '.articles.v1.ParseArticleResponse': ParseArticleResponse$json,
  '.articles.v1.GetArticlesRequest': GetArticlesRequest$json,
  '.articles.v1.GetArticlesResponse': GetArticlesResponse$json,
  '.articles.v1.ArticlePreview': ArticlePreview$json,
  '.articles.v1.GetArticleRequest': GetArticleRequest$json,
  '.articles.v1.GetArticleResponse': GetArticleResponse$json,
  '.articles.v1.Article': Article$json,
  '.articles.v1.PhonemizerData': PhonemizerData$json,
  '.articles.v1.PhonemizerTokenMeta': PhonemizerTokenMeta$json,
  '.articles.v1.DeleteArticleRequest': DeleteArticleRequest$json,
  '.articles.v1.DeleteArticleResponse': DeleteArticleResponse$json,
};

/// Descriptor for `ArticlesService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List articlesServiceDescriptor = $convert.base64Decode(
    'Cg9BcnRpY2xlc1NlcnZpY2USUwoMUGFyc2VBcnRpY2xlEiAuYXJ0aWNsZXMudjEuUGFyc2VBcn'
    'RpY2xlUmVxdWVzdBohLmFydGljbGVzLnYxLlBhcnNlQXJ0aWNsZVJlc3BvbnNlElAKC0dldEFy'
    'dGljbGVzEh8uYXJ0aWNsZXMudjEuR2V0QXJ0aWNsZXNSZXF1ZXN0GiAuYXJ0aWNsZXMudjEuR2'
    'V0QXJ0aWNsZXNSZXNwb25zZRJNCgpHZXRBcnRpY2xlEh4uYXJ0aWNsZXMudjEuR2V0QXJ0aWNs'
    'ZVJlcXVlc3QaHy5hcnRpY2xlcy52MS5HZXRBcnRpY2xlUmVzcG9uc2USVgoNRGVsZXRlQXJ0aW'
    'NsZRIhLmFydGljbGVzLnYxLkRlbGV0ZUFydGljbGVSZXF1ZXN0GiIuYXJ0aWNsZXMudjEuRGVs'
    'ZXRlQXJ0aWNsZVJlc3BvbnNl');

