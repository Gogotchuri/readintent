//
//  Generated code. Do not modify.
//  source: articles/v1/articles_service.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'articles_service.pb.dart' as $0;
import 'articles_service.pbjson.dart';

export 'articles_service.pb.dart';

abstract class ArticlesServiceBase extends $pb.GeneratedService {
  $async.Future<$0.ParseArticleResponse> parseArticle($pb.ServerContext ctx, $0.ParseArticleRequest request);
  $async.Future<$0.GetArticlesResponse> getArticles($pb.ServerContext ctx, $0.GetArticlesRequest request);
  $async.Future<$0.GetArticleResponse> getArticle($pb.ServerContext ctx, $0.GetArticleRequest request);
  $async.Future<$0.DeleteArticleResponse> deleteArticle($pb.ServerContext ctx, $0.DeleteArticleRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'ParseArticle': return $0.ParseArticleRequest();
      case 'GetArticles': return $0.GetArticlesRequest();
      case 'GetArticle': return $0.GetArticleRequest();
      case 'DeleteArticle': return $0.DeleteArticleRequest();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'ParseArticle': return this.parseArticle(ctx, request as $0.ParseArticleRequest);
      case 'GetArticles': return this.getArticles(ctx, request as $0.GetArticlesRequest);
      case 'GetArticle': return this.getArticle(ctx, request as $0.GetArticleRequest);
      case 'DeleteArticle': return this.deleteArticle(ctx, request as $0.DeleteArticleRequest);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => ArticlesServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => ArticlesServiceBase$messageJson;
}

