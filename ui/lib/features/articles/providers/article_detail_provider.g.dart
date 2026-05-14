// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ArticleDetail)
final articleDetailProvider = ArticleDetailFamily._();

final class ArticleDetailProvider
    extends $AsyncNotifierProvider<ArticleDetail, articles_pb.Article> {
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
  ArticleDetail create() => ArticleDetail();

  @override
  bool operator ==(Object other) {
    return other is ArticleDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$articleDetailHash() => r'298e3ab79690dc3a4b717dd1aa2d674877e158c2';

final class ArticleDetailFamily extends $Family
    with
        $ClassFamilyOverride<
          ArticleDetail,
          AsyncValue<articles_pb.Article>,
          articles_pb.Article,
          FutureOr<articles_pb.Article>,
          String
        > {
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

abstract class _$ArticleDetail extends $AsyncNotifier<articles_pb.Article> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<articles_pb.Article> build(String id);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<articles_pb.Article>, articles_pb.Article>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<articles_pb.Article>, articles_pb.Article>,
              AsyncValue<articles_pb.Article>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
