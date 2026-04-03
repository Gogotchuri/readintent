//
//  Generated code. Do not modify.
//  source: google/rpc/error_details.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use badRequestDescriptor instead')
const BadRequest$json = {
  '1': 'BadRequest',
  '2': [
    {
      '1': 'field_violations',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.google.rpc.BadRequest.FieldViolation',
      '10': 'fieldViolations'
    },
  ],
  '3': [BadRequest_FieldViolation$json],
};

@$core.Deprecated('Use badRequestDescriptor instead')
const BadRequest_FieldViolation$json = {
  '1': 'FieldViolation',
  '2': [
    {'1': 'field', '3': 1, '4': 1, '5': 9, '10': 'field'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
    {'1': 'reason', '3': 3, '4': 1, '5': 9, '10': 'reason'},
    {
      '1': 'localized_message',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.rpc.LocalizedMessage',
      '10': 'localizedMessage'
    },
  ],
};

/// Descriptor for `BadRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List badRequestDescriptor = $convert.base64Decode(
    'CgpCYWRSZXF1ZXN0ElAKEGZpZWxkX3Zpb2xhdGlvbnMYASADKAsyJS5nb29nbGUucnBjLkJhZF'
    'JlcXVlc3QuRmllbGRWaW9sYXRpb25SD2ZpZWxkVmlvbGF0aW9ucxqrAQoORmllbGRWaW9sYXRp'
    'b24SFAoFZmllbGQYASABKAlSBWZpZWxkEiAKC2Rlc2NyaXB0aW9uGAIgASgJUgtkZXNjcmlwdG'
    'lvbhIWCgZyZWFzb24YAyABKAlSBnJlYXNvbhJJChFsb2NhbGl6ZWRfbWVzc2FnZRgEIAEoCzIc'
    'Lmdvb2dsZS5ycGMuTG9jYWxpemVkTWVzc2FnZVIQbG9jYWxpemVkTWVzc2FnZQ==');

@$core.Deprecated('Use localizedMessageDescriptor instead')
const LocalizedMessage$json = {
  '1': 'LocalizedMessage',
  '2': [
    {'1': 'locale', '3': 1, '4': 1, '5': 9, '10': 'locale'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `LocalizedMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List localizedMessageDescriptor = $convert.base64Decode(
    'ChBMb2NhbGl6ZWRNZXNzYWdlEhYKBmxvY2FsZRgBIAEoCVIGbG9jYWxlEhgKB21lc3NhZ2UYAi'
    'ABKAlSB21lc3NhZ2U=');
