// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ArticlePreviewsTable extends ArticlePreviews
    with TableInfo<$ArticlePreviewsTable, ArticlePreview> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArticlePreviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(""),
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(""),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(""),
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(""),
  );
  static const VerificationMeta _categoriesMeta = const VerificationMeta(
    'categories',
  );
  @override
  late final GeneratedColumn<String> categories = GeneratedColumn<String>(
    'categories',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant("[]"),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(""),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(""),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerPositionMsMeta = const VerificationMeta(
    'playerPositionMs',
  );
  @override
  late final GeneratedColumn<int> playerPositionMs = GeneratedColumn<int>(
    'player_position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scrollPositionMeta = const VerificationMeta(
    'scrollPosition',
  );
  @override
  late final GeneratedColumn<double> scrollPosition = GeneratedColumn<double>(
    'scroll_position',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    status,
    title,
    author,
    date,
    url,
    categories,
    description,
    imageUrl,
    sortOrder,
    cachedAt,
    playerPositionMs,
    scrollPosition,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'article_previews';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArticlePreview> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('categories')) {
      context.handle(
        _categoriesMeta,
        categories.isAcceptableOrUnknown(data['categories']!, _categoriesMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('player_position_ms')) {
      context.handle(
        _playerPositionMsMeta,
        playerPositionMs.isAcceptableOrUnknown(
          data['player_position_ms']!,
          _playerPositionMsMeta,
        ),
      );
    }
    if (data.containsKey('scroll_position')) {
      context.handle(
        _scrollPositionMeta,
        scrollPosition.isAcceptableOrUnknown(
          data['scroll_position']!,
          _scrollPositionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ArticlePreview map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArticlePreview(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      categories: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categories'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
      playerPositionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_position_ms'],
      )!,
      scrollPosition: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}scroll_position'],
      )!,
    );
  }

  @override
  $ArticlePreviewsTable createAlias(String alias) {
    return $ArticlePreviewsTable(attachedDatabase, alias);
  }
}

class ArticlePreview extends DataClass implements Insertable<ArticlePreview> {
  final int id;
  final String status;
  final String title;
  final String author;
  final String date;
  final String url;
  final String categories;
  final String description;
  final String imageUrl;
  final int sortOrder;
  final int cachedAt;
  final int playerPositionMs;
  final double scrollPosition;
  const ArticlePreview({
    required this.id,
    required this.status,
    required this.title,
    required this.author,
    required this.date,
    required this.url,
    required this.categories,
    required this.description,
    required this.imageUrl,
    required this.sortOrder,
    required this.cachedAt,
    required this.playerPositionMs,
    required this.scrollPosition,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['status'] = Variable<String>(status);
    map['title'] = Variable<String>(title);
    map['author'] = Variable<String>(author);
    map['date'] = Variable<String>(date);
    map['url'] = Variable<String>(url);
    map['categories'] = Variable<String>(categories);
    map['description'] = Variable<String>(description);
    map['image_url'] = Variable<String>(imageUrl);
    map['sort_order'] = Variable<int>(sortOrder);
    map['cached_at'] = Variable<int>(cachedAt);
    map['player_position_ms'] = Variable<int>(playerPositionMs);
    map['scroll_position'] = Variable<double>(scrollPosition);
    return map;
  }

  ArticlePreviewsCompanion toCompanion(bool nullToAbsent) {
    return ArticlePreviewsCompanion(
      id: Value(id),
      status: Value(status),
      title: Value(title),
      author: Value(author),
      date: Value(date),
      url: Value(url),
      categories: Value(categories),
      description: Value(description),
      imageUrl: Value(imageUrl),
      sortOrder: Value(sortOrder),
      cachedAt: Value(cachedAt),
      playerPositionMs: Value(playerPositionMs),
      scrollPosition: Value(scrollPosition),
    );
  }

  factory ArticlePreview.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArticlePreview(
      id: serializer.fromJson<int>(json['id']),
      status: serializer.fromJson<String>(json['status']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String>(json['author']),
      date: serializer.fromJson<String>(json['date']),
      url: serializer.fromJson<String>(json['url']),
      categories: serializer.fromJson<String>(json['categories']),
      description: serializer.fromJson<String>(json['description']),
      imageUrl: serializer.fromJson<String>(json['imageUrl']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
      playerPositionMs: serializer.fromJson<int>(json['playerPositionMs']),
      scrollPosition: serializer.fromJson<double>(json['scrollPosition']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'status': serializer.toJson<String>(status),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String>(author),
      'date': serializer.toJson<String>(date),
      'url': serializer.toJson<String>(url),
      'categories': serializer.toJson<String>(categories),
      'description': serializer.toJson<String>(description),
      'imageUrl': serializer.toJson<String>(imageUrl),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'cachedAt': serializer.toJson<int>(cachedAt),
      'playerPositionMs': serializer.toJson<int>(playerPositionMs),
      'scrollPosition': serializer.toJson<double>(scrollPosition),
    };
  }

  ArticlePreview copyWith({
    int? id,
    String? status,
    String? title,
    String? author,
    String? date,
    String? url,
    String? categories,
    String? description,
    String? imageUrl,
    int? sortOrder,
    int? cachedAt,
    int? playerPositionMs,
    double? scrollPosition,
  }) => ArticlePreview(
    id: id ?? this.id,
    status: status ?? this.status,
    title: title ?? this.title,
    author: author ?? this.author,
    date: date ?? this.date,
    url: url ?? this.url,
    categories: categories ?? this.categories,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    sortOrder: sortOrder ?? this.sortOrder,
    cachedAt: cachedAt ?? this.cachedAt,
    playerPositionMs: playerPositionMs ?? this.playerPositionMs,
    scrollPosition: scrollPosition ?? this.scrollPosition,
  );
  ArticlePreview copyWithCompanion(ArticlePreviewsCompanion data) {
    return ArticlePreview(
      id: data.id.present ? data.id.value : this.id,
      status: data.status.present ? data.status.value : this.status,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      date: data.date.present ? data.date.value : this.date,
      url: data.url.present ? data.url.value : this.url,
      categories: data.categories.present
          ? data.categories.value
          : this.categories,
      description: data.description.present
          ? data.description.value
          : this.description,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      playerPositionMs: data.playerPositionMs.present
          ? data.playerPositionMs.value
          : this.playerPositionMs,
      scrollPosition: data.scrollPosition.present
          ? data.scrollPosition.value
          : this.scrollPosition,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArticlePreview(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('date: $date, ')
          ..write('url: $url, ')
          ..write('categories: $categories, ')
          ..write('description: $description, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('playerPositionMs: $playerPositionMs, ')
          ..write('scrollPosition: $scrollPosition')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    status,
    title,
    author,
    date,
    url,
    categories,
    description,
    imageUrl,
    sortOrder,
    cachedAt,
    playerPositionMs,
    scrollPosition,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArticlePreview &&
          other.id == this.id &&
          other.status == this.status &&
          other.title == this.title &&
          other.author == this.author &&
          other.date == this.date &&
          other.url == this.url &&
          other.categories == this.categories &&
          other.description == this.description &&
          other.imageUrl == this.imageUrl &&
          other.sortOrder == this.sortOrder &&
          other.cachedAt == this.cachedAt &&
          other.playerPositionMs == this.playerPositionMs &&
          other.scrollPosition == this.scrollPosition);
}

class ArticlePreviewsCompanion extends UpdateCompanion<ArticlePreview> {
  final Value<int> id;
  final Value<String> status;
  final Value<String> title;
  final Value<String> author;
  final Value<String> date;
  final Value<String> url;
  final Value<String> categories;
  final Value<String> description;
  final Value<String> imageUrl;
  final Value<int> sortOrder;
  final Value<int> cachedAt;
  final Value<int> playerPositionMs;
  final Value<double> scrollPosition;
  const ArticlePreviewsCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.date = const Value.absent(),
    this.url = const Value.absent(),
    this.categories = const Value.absent(),
    this.description = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.playerPositionMs = const Value.absent(),
    this.scrollPosition = const Value.absent(),
  });
  ArticlePreviewsCompanion.insert({
    this.id = const Value.absent(),
    required String status,
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.date = const Value.absent(),
    this.url = const Value.absent(),
    this.categories = const Value.absent(),
    this.description = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int cachedAt,
    this.playerPositionMs = const Value.absent(),
    this.scrollPosition = const Value.absent(),
  }) : status = Value(status),
       cachedAt = Value(cachedAt);
  static Insertable<ArticlePreview> custom({
    Expression<int>? id,
    Expression<String>? status,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? date,
    Expression<String>? url,
    Expression<String>? categories,
    Expression<String>? description,
    Expression<String>? imageUrl,
    Expression<int>? sortOrder,
    Expression<int>? cachedAt,
    Expression<int>? playerPositionMs,
    Expression<double>? scrollPosition,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (date != null) 'date': date,
      if (url != null) 'url': url,
      if (categories != null) 'categories': categories,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (playerPositionMs != null) 'player_position_ms': playerPositionMs,
      if (scrollPosition != null) 'scroll_position': scrollPosition,
    });
  }

  ArticlePreviewsCompanion copyWith({
    Value<int>? id,
    Value<String>? status,
    Value<String>? title,
    Value<String>? author,
    Value<String>? date,
    Value<String>? url,
    Value<String>? categories,
    Value<String>? description,
    Value<String>? imageUrl,
    Value<int>? sortOrder,
    Value<int>? cachedAt,
    Value<int>? playerPositionMs,
    Value<double>? scrollPosition,
  }) {
    return ArticlePreviewsCompanion(
      id: id ?? this.id,
      status: status ?? this.status,
      title: title ?? this.title,
      author: author ?? this.author,
      date: date ?? this.date,
      url: url ?? this.url,
      categories: categories ?? this.categories,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      cachedAt: cachedAt ?? this.cachedAt,
      playerPositionMs: playerPositionMs ?? this.playerPositionMs,
      scrollPosition: scrollPosition ?? this.scrollPosition,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (categories.present) {
      map['categories'] = Variable<String>(categories.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (playerPositionMs.present) {
      map['player_position_ms'] = Variable<int>(playerPositionMs.value);
    }
    if (scrollPosition.present) {
      map['scroll_position'] = Variable<double>(scrollPosition.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArticlePreviewsCompanion(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('date: $date, ')
          ..write('url: $url, ')
          ..write('categories: $categories, ')
          ..write('description: $description, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('playerPositionMs: $playerPositionMs, ')
          ..write('scrollPosition: $scrollPosition')
          ..write(')'))
        .toString();
  }
}

class $ArticleDetailsTable extends ArticleDetails
    with TableInfo<$ArticleDetailsTable, ArticleDetail> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArticleDetailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _extractedHtmlMeta = const VerificationMeta(
    'extractedHtml',
  );
  @override
  late final GeneratedColumn<String> extractedHtml = GeneratedColumn<String>(
    'extracted_html',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(""),
  );
  static const VerificationMeta _processedHtmlMeta = const VerificationMeta(
    'processedHtml',
  );
  @override
  late final GeneratedColumn<String> processedHtml = GeneratedColumn<String>(
    'processed_html',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(""),
  );
  static const VerificationMeta _pureTextMeta = const VerificationMeta(
    'pureText',
  );
  @override
  late final GeneratedColumn<String> pureText = GeneratedColumn<String>(
    'pure_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(""),
  );
  static const VerificationMeta _phonemizerBlobMeta = const VerificationMeta(
    'phonemizerBlob',
  );
  @override
  late final GeneratedColumn<Uint8List> phonemizerBlob =
      GeneratedColumn<Uint8List>(
        'phonemizer_blob',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    extractedHtml,
    processedHtml,
    pureText,
    phonemizerBlob,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'article_details';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArticleDetail> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('extracted_html')) {
      context.handle(
        _extractedHtmlMeta,
        extractedHtml.isAcceptableOrUnknown(
          data['extracted_html']!,
          _extractedHtmlMeta,
        ),
      );
    }
    if (data.containsKey('processed_html')) {
      context.handle(
        _processedHtmlMeta,
        processedHtml.isAcceptableOrUnknown(
          data['processed_html']!,
          _processedHtmlMeta,
        ),
      );
    }
    if (data.containsKey('pure_text')) {
      context.handle(
        _pureTextMeta,
        pureText.isAcceptableOrUnknown(data['pure_text']!, _pureTextMeta),
      );
    }
    if (data.containsKey('phonemizer_blob')) {
      context.handle(
        _phonemizerBlobMeta,
        phonemizerBlob.isAcceptableOrUnknown(
          data['phonemizer_blob']!,
          _phonemizerBlobMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ArticleDetail map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArticleDetail(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      extractedHtml: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extracted_html'],
      )!,
      processedHtml: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}processed_html'],
      )!,
      pureText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pure_text'],
      )!,
      phonemizerBlob: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}phonemizer_blob'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $ArticleDetailsTable createAlias(String alias) {
    return $ArticleDetailsTable(attachedDatabase, alias);
  }
}

class ArticleDetail extends DataClass implements Insertable<ArticleDetail> {
  final int id;
  final String extractedHtml;
  final String processedHtml;
  final String pureText;
  final Uint8List? phonemizerBlob;
  final int cachedAt;
  const ArticleDetail({
    required this.id,
    required this.extractedHtml,
    required this.processedHtml,
    required this.pureText,
    this.phonemizerBlob,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['extracted_html'] = Variable<String>(extractedHtml);
    map['processed_html'] = Variable<String>(processedHtml);
    map['pure_text'] = Variable<String>(pureText);
    if (!nullToAbsent || phonemizerBlob != null) {
      map['phonemizer_blob'] = Variable<Uint8List>(phonemizerBlob);
    }
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  ArticleDetailsCompanion toCompanion(bool nullToAbsent) {
    return ArticleDetailsCompanion(
      id: Value(id),
      extractedHtml: Value(extractedHtml),
      processedHtml: Value(processedHtml),
      pureText: Value(pureText),
      phonemizerBlob: phonemizerBlob == null && nullToAbsent
          ? const Value.absent()
          : Value(phonemizerBlob),
      cachedAt: Value(cachedAt),
    );
  }

  factory ArticleDetail.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArticleDetail(
      id: serializer.fromJson<int>(json['id']),
      extractedHtml: serializer.fromJson<String>(json['extractedHtml']),
      processedHtml: serializer.fromJson<String>(json['processedHtml']),
      pureText: serializer.fromJson<String>(json['pureText']),
      phonemizerBlob: serializer.fromJson<Uint8List?>(json['phonemizerBlob']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'extractedHtml': serializer.toJson<String>(extractedHtml),
      'processedHtml': serializer.toJson<String>(processedHtml),
      'pureText': serializer.toJson<String>(pureText),
      'phonemizerBlob': serializer.toJson<Uint8List?>(phonemizerBlob),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  ArticleDetail copyWith({
    int? id,
    String? extractedHtml,
    String? processedHtml,
    String? pureText,
    Value<Uint8List?> phonemizerBlob = const Value.absent(),
    int? cachedAt,
  }) => ArticleDetail(
    id: id ?? this.id,
    extractedHtml: extractedHtml ?? this.extractedHtml,
    processedHtml: processedHtml ?? this.processedHtml,
    pureText: pureText ?? this.pureText,
    phonemizerBlob: phonemizerBlob.present
        ? phonemizerBlob.value
        : this.phonemizerBlob,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  ArticleDetail copyWithCompanion(ArticleDetailsCompanion data) {
    return ArticleDetail(
      id: data.id.present ? data.id.value : this.id,
      extractedHtml: data.extractedHtml.present
          ? data.extractedHtml.value
          : this.extractedHtml,
      processedHtml: data.processedHtml.present
          ? data.processedHtml.value
          : this.processedHtml,
      pureText: data.pureText.present ? data.pureText.value : this.pureText,
      phonemizerBlob: data.phonemizerBlob.present
          ? data.phonemizerBlob.value
          : this.phonemizerBlob,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArticleDetail(')
          ..write('id: $id, ')
          ..write('extractedHtml: $extractedHtml, ')
          ..write('processedHtml: $processedHtml, ')
          ..write('pureText: $pureText, ')
          ..write('phonemizerBlob: $phonemizerBlob, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    extractedHtml,
    processedHtml,
    pureText,
    $driftBlobEquality.hash(phonemizerBlob),
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArticleDetail &&
          other.id == this.id &&
          other.extractedHtml == this.extractedHtml &&
          other.processedHtml == this.processedHtml &&
          other.pureText == this.pureText &&
          $driftBlobEquality.equals(
            other.phonemizerBlob,
            this.phonemizerBlob,
          ) &&
          other.cachedAt == this.cachedAt);
}

class ArticleDetailsCompanion extends UpdateCompanion<ArticleDetail> {
  final Value<int> id;
  final Value<String> extractedHtml;
  final Value<String> processedHtml;
  final Value<String> pureText;
  final Value<Uint8List?> phonemizerBlob;
  final Value<int> cachedAt;
  const ArticleDetailsCompanion({
    this.id = const Value.absent(),
    this.extractedHtml = const Value.absent(),
    this.processedHtml = const Value.absent(),
    this.pureText = const Value.absent(),
    this.phonemizerBlob = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  ArticleDetailsCompanion.insert({
    this.id = const Value.absent(),
    this.extractedHtml = const Value.absent(),
    this.processedHtml = const Value.absent(),
    this.pureText = const Value.absent(),
    this.phonemizerBlob = const Value.absent(),
    required int cachedAt,
  }) : cachedAt = Value(cachedAt);
  static Insertable<ArticleDetail> custom({
    Expression<int>? id,
    Expression<String>? extractedHtml,
    Expression<String>? processedHtml,
    Expression<String>? pureText,
    Expression<Uint8List>? phonemizerBlob,
    Expression<int>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (extractedHtml != null) 'extracted_html': extractedHtml,
      if (processedHtml != null) 'processed_html': processedHtml,
      if (pureText != null) 'pure_text': pureText,
      if (phonemizerBlob != null) 'phonemizer_blob': phonemizerBlob,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  ArticleDetailsCompanion copyWith({
    Value<int>? id,
    Value<String>? extractedHtml,
    Value<String>? processedHtml,
    Value<String>? pureText,
    Value<Uint8List?>? phonemizerBlob,
    Value<int>? cachedAt,
  }) {
    return ArticleDetailsCompanion(
      id: id ?? this.id,
      extractedHtml: extractedHtml ?? this.extractedHtml,
      processedHtml: processedHtml ?? this.processedHtml,
      pureText: pureText ?? this.pureText,
      phonemizerBlob: phonemizerBlob ?? this.phonemizerBlob,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (extractedHtml.present) {
      map['extracted_html'] = Variable<String>(extractedHtml.value);
    }
    if (processedHtml.present) {
      map['processed_html'] = Variable<String>(processedHtml.value);
    }
    if (pureText.present) {
      map['pure_text'] = Variable<String>(pureText.value);
    }
    if (phonemizerBlob.present) {
      map['phonemizer_blob'] = Variable<Uint8List>(phonemizerBlob.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArticleDetailsCompanion(')
          ..write('id: $id, ')
          ..write('extractedHtml: $extractedHtml, ')
          ..write('processedHtml: $processedHtml, ')
          ..write('pureText: $pureText, ')
          ..write('phonemizerBlob: $phonemizerBlob, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $PendingOperationsTable extends PendingOperations
    with TableInfo<$PendingOperationsTable, PendingOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant("pending"),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    payload,
    status,
    createdAt,
    retryCount,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingOperation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingOperation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $PendingOperationsTable createAlias(String alias) {
    return $PendingOperationsTable(attachedDatabase, alias);
  }
}

class PendingOperation extends DataClass
    implements Insertable<PendingOperation> {
  final int id;
  final String type;
  final String payload;
  final String status;
  final int createdAt;
  final int retryCount;
  final String? lastError;
  const PendingOperation({
    required this.id,
    required this.type,
    required this.payload,
    required this.status,
    required this.createdAt,
    required this.retryCount,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  PendingOperationsCompanion toCompanion(bool nullToAbsent) {
    return PendingOperationsCompanion(
      id: Value(id),
      type: Value(type),
      payload: Value(payload),
      status: Value(status),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory PendingOperation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingOperation(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  PendingOperation copyWith({
    int? id,
    String? type,
    String? payload,
    String? status,
    int? createdAt,
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
  }) => PendingOperation(
    id: id ?? this.id,
    type: type ?? this.type,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  PendingOperation copyWithCompanion(PendingOperationsCompanion data) {
    return PendingOperation(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingOperation(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, payload, status, createdAt, retryCount, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOperation &&
          other.id == this.id &&
          other.type == this.type &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError);
}

class PendingOperationsCompanion extends UpdateCompanion<PendingOperation> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> payload;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<int> retryCount;
  final Value<String?> lastError;
  const PendingOperationsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  PendingOperationsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required String payload,
    this.status = const Value.absent(),
    required int createdAt,
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : type = Value(type),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<PendingOperation> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
    });
  }

  PendingOperationsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<String>? payload,
    Value<String>? status,
    Value<int>? createdAt,
    Value<int>? retryCount,
    Value<String?>? lastError,
  }) {
    return PendingOperationsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingOperationsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ArticlePreviewsTable articlePreviews = $ArticlePreviewsTable(
    this,
  );
  late final $ArticleDetailsTable articleDetails = $ArticleDetailsTable(this);
  late final $PendingOperationsTable pendingOperations =
      $PendingOperationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    articlePreviews,
    articleDetails,
    pendingOperations,
  ];
}

typedef $$ArticlePreviewsTableCreateCompanionBuilder =
    ArticlePreviewsCompanion Function({
      Value<int> id,
      required String status,
      Value<String> title,
      Value<String> author,
      Value<String> date,
      Value<String> url,
      Value<String> categories,
      Value<String> description,
      Value<String> imageUrl,
      Value<int> sortOrder,
      required int cachedAt,
      Value<int> playerPositionMs,
      Value<double> scrollPosition,
    });
typedef $$ArticlePreviewsTableUpdateCompanionBuilder =
    ArticlePreviewsCompanion Function({
      Value<int> id,
      Value<String> status,
      Value<String> title,
      Value<String> author,
      Value<String> date,
      Value<String> url,
      Value<String> categories,
      Value<String> description,
      Value<String> imageUrl,
      Value<int> sortOrder,
      Value<int> cachedAt,
      Value<int> playerPositionMs,
      Value<double> scrollPosition,
    });

class $$ArticlePreviewsTableFilterComposer
    extends Composer<_$AppDatabase, $ArticlePreviewsTable> {
  $$ArticlePreviewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playerPositionMs => $composableBuilder(
    column: $table.playerPositionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get scrollPosition => $composableBuilder(
    column: $table.scrollPosition,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ArticlePreviewsTableOrderingComposer
    extends Composer<_$AppDatabase, $ArticlePreviewsTable> {
  $$ArticlePreviewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playerPositionMs => $composableBuilder(
    column: $table.playerPositionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get scrollPosition => $composableBuilder(
    column: $table.scrollPosition,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArticlePreviewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArticlePreviewsTable> {
  $$ArticlePreviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<int> get playerPositionMs => $composableBuilder(
    column: $table.playerPositionMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get scrollPosition => $composableBuilder(
    column: $table.scrollPosition,
    builder: (column) => column,
  );
}

class $$ArticlePreviewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArticlePreviewsTable,
          ArticlePreview,
          $$ArticlePreviewsTableFilterComposer,
          $$ArticlePreviewsTableOrderingComposer,
          $$ArticlePreviewsTableAnnotationComposer,
          $$ArticlePreviewsTableCreateCompanionBuilder,
          $$ArticlePreviewsTableUpdateCompanionBuilder,
          (
            ArticlePreview,
            BaseReferences<
              _$AppDatabase,
              $ArticlePreviewsTable,
              ArticlePreview
            >,
          ),
          ArticlePreview,
          PrefetchHooks Function()
        > {
  $$ArticlePreviewsTableTableManager(
    _$AppDatabase db,
    $ArticlePreviewsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArticlePreviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArticlePreviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArticlePreviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> categories = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> imageUrl = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
                Value<int> playerPositionMs = const Value.absent(),
                Value<double> scrollPosition = const Value.absent(),
              }) => ArticlePreviewsCompanion(
                id: id,
                status: status,
                title: title,
                author: author,
                date: date,
                url: url,
                categories: categories,
                description: description,
                imageUrl: imageUrl,
                sortOrder: sortOrder,
                cachedAt: cachedAt,
                playerPositionMs: playerPositionMs,
                scrollPosition: scrollPosition,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String status,
                Value<String> title = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> categories = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> imageUrl = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int cachedAt,
                Value<int> playerPositionMs = const Value.absent(),
                Value<double> scrollPosition = const Value.absent(),
              }) => ArticlePreviewsCompanion.insert(
                id: id,
                status: status,
                title: title,
                author: author,
                date: date,
                url: url,
                categories: categories,
                description: description,
                imageUrl: imageUrl,
                sortOrder: sortOrder,
                cachedAt: cachedAt,
                playerPositionMs: playerPositionMs,
                scrollPosition: scrollPosition,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ArticlePreviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArticlePreviewsTable,
      ArticlePreview,
      $$ArticlePreviewsTableFilterComposer,
      $$ArticlePreviewsTableOrderingComposer,
      $$ArticlePreviewsTableAnnotationComposer,
      $$ArticlePreviewsTableCreateCompanionBuilder,
      $$ArticlePreviewsTableUpdateCompanionBuilder,
      (
        ArticlePreview,
        BaseReferences<_$AppDatabase, $ArticlePreviewsTable, ArticlePreview>,
      ),
      ArticlePreview,
      PrefetchHooks Function()
    >;
typedef $$ArticleDetailsTableCreateCompanionBuilder =
    ArticleDetailsCompanion Function({
      Value<int> id,
      Value<String> extractedHtml,
      Value<String> processedHtml,
      Value<String> pureText,
      Value<Uint8List?> phonemizerBlob,
      required int cachedAt,
    });
typedef $$ArticleDetailsTableUpdateCompanionBuilder =
    ArticleDetailsCompanion Function({
      Value<int> id,
      Value<String> extractedHtml,
      Value<String> processedHtml,
      Value<String> pureText,
      Value<Uint8List?> phonemizerBlob,
      Value<int> cachedAt,
    });

class $$ArticleDetailsTableFilterComposer
    extends Composer<_$AppDatabase, $ArticleDetailsTable> {
  $$ArticleDetailsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extractedHtml => $composableBuilder(
    column: $table.extractedHtml,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get processedHtml => $composableBuilder(
    column: $table.processedHtml,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pureText => $composableBuilder(
    column: $table.pureText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get phonemizerBlob => $composableBuilder(
    column: $table.phonemizerBlob,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ArticleDetailsTableOrderingComposer
    extends Composer<_$AppDatabase, $ArticleDetailsTable> {
  $$ArticleDetailsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extractedHtml => $composableBuilder(
    column: $table.extractedHtml,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get processedHtml => $composableBuilder(
    column: $table.processedHtml,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pureText => $composableBuilder(
    column: $table.pureText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get phonemizerBlob => $composableBuilder(
    column: $table.phonemizerBlob,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArticleDetailsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArticleDetailsTable> {
  $$ArticleDetailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get extractedHtml => $composableBuilder(
    column: $table.extractedHtml,
    builder: (column) => column,
  );

  GeneratedColumn<String> get processedHtml => $composableBuilder(
    column: $table.processedHtml,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pureText =>
      $composableBuilder(column: $table.pureText, builder: (column) => column);

  GeneratedColumn<Uint8List> get phonemizerBlob => $composableBuilder(
    column: $table.phonemizerBlob,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$ArticleDetailsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArticleDetailsTable,
          ArticleDetail,
          $$ArticleDetailsTableFilterComposer,
          $$ArticleDetailsTableOrderingComposer,
          $$ArticleDetailsTableAnnotationComposer,
          $$ArticleDetailsTableCreateCompanionBuilder,
          $$ArticleDetailsTableUpdateCompanionBuilder,
          (
            ArticleDetail,
            BaseReferences<_$AppDatabase, $ArticleDetailsTable, ArticleDetail>,
          ),
          ArticleDetail,
          PrefetchHooks Function()
        > {
  $$ArticleDetailsTableTableManager(
    _$AppDatabase db,
    $ArticleDetailsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArticleDetailsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArticleDetailsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArticleDetailsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> extractedHtml = const Value.absent(),
                Value<String> processedHtml = const Value.absent(),
                Value<String> pureText = const Value.absent(),
                Value<Uint8List?> phonemizerBlob = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
              }) => ArticleDetailsCompanion(
                id: id,
                extractedHtml: extractedHtml,
                processedHtml: processedHtml,
                pureText: pureText,
                phonemizerBlob: phonemizerBlob,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> extractedHtml = const Value.absent(),
                Value<String> processedHtml = const Value.absent(),
                Value<String> pureText = const Value.absent(),
                Value<Uint8List?> phonemizerBlob = const Value.absent(),
                required int cachedAt,
              }) => ArticleDetailsCompanion.insert(
                id: id,
                extractedHtml: extractedHtml,
                processedHtml: processedHtml,
                pureText: pureText,
                phonemizerBlob: phonemizerBlob,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ArticleDetailsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArticleDetailsTable,
      ArticleDetail,
      $$ArticleDetailsTableFilterComposer,
      $$ArticleDetailsTableOrderingComposer,
      $$ArticleDetailsTableAnnotationComposer,
      $$ArticleDetailsTableCreateCompanionBuilder,
      $$ArticleDetailsTableUpdateCompanionBuilder,
      (
        ArticleDetail,
        BaseReferences<_$AppDatabase, $ArticleDetailsTable, ArticleDetail>,
      ),
      ArticleDetail,
      PrefetchHooks Function()
    >;
typedef $$PendingOperationsTableCreateCompanionBuilder =
    PendingOperationsCompanion Function({
      Value<int> id,
      required String type,
      required String payload,
      Value<String> status,
      required int createdAt,
      Value<int> retryCount,
      Value<String?> lastError,
    });
typedef $$PendingOperationsTableUpdateCompanionBuilder =
    PendingOperationsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<String> payload,
      Value<String> status,
      Value<int> createdAt,
      Value<int> retryCount,
      Value<String?> lastError,
    });

class $$PendingOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$PendingOperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingOperationsTable,
          PendingOperation,
          $$PendingOperationsTableFilterComposer,
          $$PendingOperationsTableOrderingComposer,
          $$PendingOperationsTableAnnotationComposer,
          $$PendingOperationsTableCreateCompanionBuilder,
          $$PendingOperationsTableUpdateCompanionBuilder,
          (
            PendingOperation,
            BaseReferences<
              _$AppDatabase,
              $PendingOperationsTable,
              PendingOperation
            >,
          ),
          PendingOperation,
          PrefetchHooks Function()
        > {
  $$PendingOperationsTableTableManager(
    _$AppDatabase db,
    $PendingOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingOperationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => PendingOperationsCompanion(
                id: id,
                type: type,
                payload: payload,
                status: status,
                createdAt: createdAt,
                retryCount: retryCount,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required String payload,
                Value<String> status = const Value.absent(),
                required int createdAt,
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => PendingOperationsCompanion.insert(
                id: id,
                type: type,
                payload: payload,
                status: status,
                createdAt: createdAt,
                retryCount: retryCount,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingOperationsTable,
      PendingOperation,
      $$PendingOperationsTableFilterComposer,
      $$PendingOperationsTableOrderingComposer,
      $$PendingOperationsTableAnnotationComposer,
      $$PendingOperationsTableCreateCompanionBuilder,
      $$PendingOperationsTableUpdateCompanionBuilder,
      (
        PendingOperation,
        BaseReferences<
          _$AppDatabase,
          $PendingOperationsTable,
          PendingOperation
        >,
      ),
      PendingOperation,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ArticlePreviewsTableTableManager get articlePreviews =>
      $$ArticlePreviewsTableTableManager(_db, _db.articlePreviews);
  $$ArticleDetailsTableTableManager get articleDetails =>
      $$ArticleDetailsTableTableManager(_db, _db.articleDetails);
  $$PendingOperationsTableTableManager get pendingOperations =>
      $$PendingOperationsTableTableManager(_db, _db.pendingOperations);
}
