// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(articleDetail)
final articleDetailProvider = ArticleDetailFamily._();

final class ArticleDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<articles_pb.Article>,
          articles_pb.Article,
          FutureOr<articles_pb.Article>
        >
    with
        $FutureModifier<articles_pb.Article>,
        $FutureProvider<articles_pb.Article> {
  ArticleDetailProvider._({
    required ArticleDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'articleDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$articleDetailHash();

  @override
  String toString() {
    return r'articleDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<articles_pb.Article> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<articles_pb.Article> create(Ref ref) {
    final argument = this.argument as String;
    return articleDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ArticleDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$articleDetailHash() => r'7919b80fcfb25e13550f44a7af31dfe8017dc42b';

final class ArticleDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<articles_pb.Article>, String> {
  ArticleDetailFamily._()
    : super(
        retry: null,
        name: r'articleDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ArticleDetailProvider call(String id) =>
      ArticleDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'articleDetailProvider';
}
