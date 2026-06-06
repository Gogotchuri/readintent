//
//  Generated code. Do not modify.
//  source: google/rpc/error_details.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// A message type used to describe a single bad request field.
class BadRequest_FieldViolation extends $pb.GeneratedMessage {
  factory BadRequest_FieldViolation({
    $core.String? field_1,
    $core.String? description,
    $core.String? reason,
    LocalizedMessage? localizedMessage,
  }) {
    final $result = create();
    if (field_1 != null) {
      $result.field_1 = field_1;
    }
    if (description != null) {
      $result.description = description;
    }
    if (reason != null) {
      $result.reason = reason;
    }
    if (localizedMessage != null) {
      $result.localizedMessage = localizedMessage;
    }
    return $result;
  }
  BadRequest_FieldViolation._() : super();
  factory BadRequest_FieldViolation.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BadRequest_FieldViolation.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BadRequest.FieldViolation',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'google.rpc'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'field')
    ..aOS(2, _omitFieldNames ? '' : 'description')
    ..aOS(3, _omitFieldNames ? '' : 'reason')
    ..aOM<LocalizedMessage>(4, _omitFieldNames ? '' : 'localizedMessage',
        subBuilder: LocalizedMessage.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BadRequest_FieldViolation clone() =>
      BadRequest_FieldViolation()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BadRequest_FieldViolation copyWith(
          void Function(BadRequest_FieldViolation) updates) =>
      super.copyWith((message) => updates(message as BadRequest_FieldViolation))
          as BadRequest_FieldViolation;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BadRequest_FieldViolation create() => BadRequest_FieldViolation._();
  BadRequest_FieldViolation createEmptyInstance() => create();
  static $pb.PbList<BadRequest_FieldViolation> createRepeated() =>
      $pb.PbList<BadRequest_FieldViolation>();
  @$core.pragma('dart2js:noInline')
  static BadRequest_FieldViolation getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BadRequest_FieldViolation>(create);
  static BadRequest_FieldViolation? _defaultInstance;

  ///  A path that leads to a field in the request body. The value will be a
  ///  sequence of dot-separated identifiers that identify a protocol buffer
  ///  field.
  ///
  ///  Consider the following:
  ///
  ///      message CreateContactRequest {
  ///        message EmailAddress {
  ///          enum Type {
  ///            TYPE_UNSPECIFIED = 0;
  ///            HOME = 1;
  ///            WORK = 2;
  ///          }
  ///
  ///          optional string email = 1;
  ///          repeated EmailType type = 2;
  ///        }
  ///
  ///        string full_name = 1;
  ///        repeated EmailAddress email_addresses = 2;
  ///      }
  ///
  ///  In this example, in proto `field` could take one of the following values:
  ///
  ///  * `full_name` for a violation in the `full_name` value
  ///  * `email_addresses[0].email` for a violation in the `email` field of the
  ///    first `email_addresses` message
  ///  * `email_addresses[2].type[1]` for a violation in the second `type`
  ///    value in the third `email_addresses` message.
  ///
  ///  In JSON, the same values are represented as:
  ///
  ///  * `fullName` for a violation in the `fullName` value
  ///  * `emailAddresses[0].email` for a violation in the `email` field of the
  ///    first `emailAddresses` message
  ///  * `emailAddresses[2].type[1]` for a violation in the second `type`
  ///    value in the third `emailAddresses` message.
  @$pb.TagNumber(1)
  $core.String get field_1 => $_getSZ(0);
  @$pb.TagNumber(1)
  set field_1($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasField_1() => $_has(0);
  @$pb.TagNumber(1)
  void clearField_1() => clearField(1);

  /// A description of why the request element is bad.
  @$pb.TagNumber(2)
  $core.String get description => $_getSZ(1);
  @$pb.TagNumber(2)
  set description($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasDescription() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescription() => clearField(2);

  /// The reason of the field-level error. This is a constant value that
  /// identifies the proximate cause of the field-level error. It should
  /// uniquely identify the type of the FieldViolation within the scope of the
  /// google.rpc.ErrorInfo.domain. This should be at most 63
  /// characters and match a regular expression of `[A-Z][A-Z0-9_]+[A-Z0-9]`,
  /// which represents UPPER_SNAKE_CASE.
  @$pb.TagNumber(3)
  $core.String get reason => $_getSZ(2);
  @$pb.TagNumber(3)
  set reason($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasReason() => $_has(2);
  @$pb.TagNumber(3)
  void clearReason() => clearField(3);

  /// Provides a localized error message for field-level errors that is safe to
  /// return to the API consumer.
  @$pb.TagNumber(4)
  LocalizedMessage get localizedMessage => $_getN(3);
  @$pb.TagNumber(4)
  set localizedMessage(LocalizedMessage v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasLocalizedMessage() => $_has(3);
  @$pb.TagNumber(4)
  void clearLocalizedMessage() => clearField(4);
  @$pb.TagNumber(4)
  LocalizedMessage ensureLocalizedMessage() => $_ensure(3);
}

/// Describes violations in a client request. This error type focuses on the
/// syntactic aspects of the request.
class BadRequest extends $pb.GeneratedMessage {
  factory BadRequest({
    $core.Iterable<BadRequest_FieldViolation>? fieldViolations,
  }) {
    final $result = create();
    if (fieldViolations != null) {
      $result.fieldViolations.addAll(fieldViolations);
    }
    return $result;
  }
  BadRequest._() : super();
  factory BadRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BadRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BadRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'google.rpc'),
      createEmptyInstance: create)
    ..pc<BadRequest_FieldViolation>(
        1, _omitFieldNames ? '' : 'fieldViolations', $pb.PbFieldType.PM,
        subBuilder: BadRequest_FieldViolation.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BadRequest clone() => BadRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BadRequest copyWith(void Function(BadRequest) updates) =>
      super.copyWith((message) => updates(message as BadRequest)) as BadRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BadRequest create() => BadRequest._();
  BadRequest createEmptyInstance() => create();
  static $pb.PbList<BadRequest> createRepeated() => $pb.PbList<BadRequest>();
  @$core.pragma('dart2js:noInline')
  static BadRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BadRequest>(create);
  static BadRequest? _defaultInstance;

  /// Describes all violations in a client request.
  @$pb.TagNumber(1)
  $core.List<BadRequest_FieldViolation> get fieldViolations => $_getList(0);
}

/// Provides a localized error message that is safe to return to the user
/// which can be attached to an RPC error.
class LocalizedMessage extends $pb.GeneratedMessage {
  factory LocalizedMessage({
    $core.String? locale,
    $core.String? message,
  }) {
    final $result = create();
    if (locale != null) {
      $result.locale = locale;
    }
    if (message != null) {
      $result.message = message;
    }
    return $result;
  }
  LocalizedMessage._() : super();
  factory LocalizedMessage.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory LocalizedMessage.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LocalizedMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'google.rpc'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'locale')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  LocalizedMessage clone() => LocalizedMessage()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  LocalizedMessage copyWith(void Function(LocalizedMessage) updates) =>
      super.copyWith((message) => updates(message as LocalizedMessage))
          as LocalizedMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LocalizedMessage create() => LocalizedMessage._();
  LocalizedMessage createEmptyInstance() => create();
  static $pb.PbList<LocalizedMessage> createRepeated() =>
      $pb.PbList<LocalizedMessage>();
  @$core.pragma('dart2js:noInline')
  static LocalizedMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LocalizedMessage>(create);
  static LocalizedMessage? _defaultInstance;

  /// The locale used following the specification defined at
  /// https://www.rfc-editor.org/rfc/bcp/bcp47.txt.
  /// Examples are: "en-US", "fr-CH", "es-MX"
  @$pb.TagNumber(1)
  $core.String get locale => $_getSZ(0);
  @$pb.TagNumber(1)
  set locale($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasLocale() => $_has(0);
  @$pb.TagNumber(1)
  void clearLocale() => clearField(1);

  /// The localized error message in the above locale.
  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => clearField(2);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
