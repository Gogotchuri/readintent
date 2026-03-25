//
//  Generated code. Do not modify.
//  source: auth/v1/auth_service.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use identityDescriptor instead')
const Identity$json = {
  '1': 'Identity',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'email', '3': 2, '4': 1, '5': 9, '10': 'email'},
    {'1': 'first_name', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'firstName', '17': true},
    {'1': 'last_name', '3': 4, '4': 1, '5': 9, '9': 1, '10': 'lastName', '17': true},
  ],
  '8': [
    {'1': '_first_name'},
    {'1': '_last_name'},
  ],
};

/// Descriptor for `Identity`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List identityDescriptor = $convert.base64Decode(
    'CghJZGVudGl0eRIOCgJpZBgBIAEoCVICaWQSFAoFZW1haWwYAiABKAlSBWVtYWlsEiIKCmZpcn'
    'N0X25hbWUYAyABKAlIAFIJZmlyc3ROYW1liAEBEiAKCWxhc3RfbmFtZRgEIAEoCUgBUghsYXN0'
    'TmFtZYgBAUINCgtfZmlyc3RfbmFtZUIMCgpfbGFzdF9uYW1l');

@$core.Deprecated('Use sessionDescriptor instead')
const Session$json = {
  '1': 'Session',
  '2': [
    {'1': 'session_token', '3': 1, '4': 1, '5': 9, '10': 'sessionToken'},
    {'1': 'expired_at_unix', '3': 2, '4': 1, '5': 3, '10': 'expiredAtUnix'},
    {'1': 'identity', '3': 3, '4': 1, '5': 11, '6': '.auth.v1.Identity', '10': 'identity'},
  ],
};

/// Descriptor for `Session`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionDescriptor = $convert.base64Decode(
    'CgdTZXNzaW9uEiMKDXNlc3Npb25fdG9rZW4YASABKAlSDHNlc3Npb25Ub2tlbhImCg9leHBpcm'
    'VkX2F0X3VuaXgYAiABKANSDWV4cGlyZWRBdFVuaXgSLQoIaWRlbnRpdHkYAyABKAsyES5hdXRo'
    'LnYxLklkZW50aXR5UghpZGVudGl0eQ==');

@$core.Deprecated('Use emailVerificationFlowDescriptor instead')
const EmailVerificationFlow$json = {
  '1': 'EmailVerificationFlow',
  '2': [
    {'1': 'flow_id', '3': 1, '4': 1, '5': 9, '10': 'flowId'},
    {'1': 'verifiable_address', '3': 2, '4': 1, '5': 9, '10': 'verifiableAddress'},
  ],
};

/// Descriptor for `EmailVerificationFlow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emailVerificationFlowDescriptor = $convert.base64Decode(
    'ChVFbWFpbFZlcmlmaWNhdGlvbkZsb3cSFwoHZmxvd19pZBgBIAEoCVIGZmxvd0lkEi0KEnZlcm'
    'lmaWFibGVfYWRkcmVzcxgCIAEoCVIRdmVyaWZpYWJsZUFkZHJlc3M=');

@$core.Deprecated('Use getSessionRequestDescriptor instead')
const GetSessionRequest$json = {
  '1': 'GetSessionRequest',
};

/// Descriptor for `GetSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSessionRequestDescriptor = $convert.base64Decode(
    'ChFHZXRTZXNzaW9uUmVxdWVzdA==');

@$core.Deprecated('Use getSessionResponseDescriptor instead')
const GetSessionResponse$json = {
  '1': 'GetSessionResponse',
  '2': [
    {'1': 'session', '3': 1, '4': 1, '5': 11, '6': '.auth.v1.Session', '10': 'session'},
  ],
};

/// Descriptor for `GetSessionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSessionResponseDescriptor = $convert.base64Decode(
    'ChJHZXRTZXNzaW9uUmVzcG9uc2USKgoHc2Vzc2lvbhgBIAEoCzIQLmF1dGgudjEuU2Vzc2lvbl'
    'IHc2Vzc2lvbg==');

@$core.Deprecated('Use passwordLoginRequestDescriptor instead')
const PasswordLoginRequest$json = {
  '1': 'PasswordLoginRequest',
  '2': [
    {'1': 'email', '3': 1, '4': 1, '5': 9, '10': 'email'},
    {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
  ],
};

/// Descriptor for `PasswordLoginRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List passwordLoginRequestDescriptor = $convert.base64Decode(
    'ChRQYXNzd29yZExvZ2luUmVxdWVzdBIUCgVlbWFpbBgBIAEoCVIFZW1haWwSGgoIcGFzc3dvcm'
    'QYAiABKAlSCHBhc3N3b3Jk');

@$core.Deprecated('Use passwordLoginResponseDescriptor instead')
const PasswordLoginResponse$json = {
  '1': 'PasswordLoginResponse',
  '2': [
    {'1': 'session', '3': 1, '4': 1, '5': 11, '6': '.auth.v1.Session', '10': 'session'},
  ],
};

/// Descriptor for `PasswordLoginResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List passwordLoginResponseDescriptor = $convert.base64Decode(
    'ChVQYXNzd29yZExvZ2luUmVzcG9uc2USKgoHc2Vzc2lvbhgBIAEoCzIQLmF1dGgudjEuU2Vzc2'
    'lvblIHc2Vzc2lvbg==');

@$core.Deprecated('Use passwordRegistrationRequestDescriptor instead')
const PasswordRegistrationRequest$json = {
  '1': 'PasswordRegistrationRequest',
  '2': [
    {'1': 'email', '3': 1, '4': 1, '5': 9, '10': 'email'},
    {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
    {'1': 'first_name', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'firstName', '17': true},
    {'1': 'last_name', '3': 4, '4': 1, '5': 9, '9': 1, '10': 'lastName', '17': true},
  ],
  '8': [
    {'1': '_first_name'},
    {'1': '_last_name'},
  ],
};

/// Descriptor for `PasswordRegistrationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List passwordRegistrationRequestDescriptor = $convert.base64Decode(
    'ChtQYXNzd29yZFJlZ2lzdHJhdGlvblJlcXVlc3QSFAoFZW1haWwYASABKAlSBWVtYWlsEhoKCH'
    'Bhc3N3b3JkGAIgASgJUghwYXNzd29yZBIiCgpmaXJzdF9uYW1lGAMgASgJSABSCWZpcnN0TmFt'
    'ZYgBARIgCglsYXN0X25hbWUYBCABKAlIAVIIbGFzdE5hbWWIAQFCDQoLX2ZpcnN0X25hbWVCDA'
    'oKX2xhc3RfbmFtZQ==');

@$core.Deprecated('Use passwordRegistrationResponseDescriptor instead')
const PasswordRegistrationResponse$json = {
  '1': 'PasswordRegistrationResponse',
  '2': [
    {'1': 'session', '3': 1, '4': 1, '5': 11, '6': '.auth.v1.Session', '10': 'session'},
    {'1': 'verification_flow', '3': 2, '4': 1, '5': 11, '6': '.auth.v1.EmailVerificationFlow', '9': 0, '10': 'verificationFlow', '17': true},
  ],
  '8': [
    {'1': '_verification_flow'},
  ],
};

/// Descriptor for `PasswordRegistrationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List passwordRegistrationResponseDescriptor = $convert.base64Decode(
    'ChxQYXNzd29yZFJlZ2lzdHJhdGlvblJlc3BvbnNlEioKB3Nlc3Npb24YASABKAsyEC5hdXRoLn'
    'YxLlNlc3Npb25SB3Nlc3Npb24SUAoRdmVyaWZpY2F0aW9uX2Zsb3cYAiABKAsyHi5hdXRoLnYx'
    'LkVtYWlsVmVyaWZpY2F0aW9uRmxvd0gAUhB2ZXJpZmljYXRpb25GbG93iAEBQhQKEl92ZXJpZm'
    'ljYXRpb25fZmxvdw==');

@$core.Deprecated('Use logoutRequestDescriptor instead')
const LogoutRequest$json = {
  '1': 'LogoutRequest',
};

/// Descriptor for `LogoutRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logoutRequestDescriptor = $convert.base64Decode(
    'Cg1Mb2dvdXRSZXF1ZXN0');

@$core.Deprecated('Use logoutResponseDescriptor instead')
const LogoutResponse$json = {
  '1': 'LogoutResponse',
};

/// Descriptor for `LogoutResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logoutResponseDescriptor = $convert.base64Decode(
    'Cg5Mb2dvdXRSZXNwb25zZQ==');

const $core.Map<$core.String, $core.dynamic> AuthServiceBase$json = {
  '1': 'AuthService',
  '2': [
    {'1': 'PasswordLogin', '2': '.auth.v1.PasswordLoginRequest', '3': '.auth.v1.PasswordLoginResponse'},
    {'1': 'PasswordRegistration', '2': '.auth.v1.PasswordRegistrationRequest', '3': '.auth.v1.PasswordRegistrationResponse'},
    {'1': 'Logout', '2': '.auth.v1.LogoutRequest', '3': '.auth.v1.LogoutResponse'},
    {'1': 'GetSession', '2': '.auth.v1.GetSessionRequest', '3': '.auth.v1.GetSessionResponse'},
  ],
};

@$core.Deprecated('Use authServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> AuthServiceBase$messageJson = {
  '.auth.v1.PasswordLoginRequest': PasswordLoginRequest$json,
  '.auth.v1.PasswordLoginResponse': PasswordLoginResponse$json,
  '.auth.v1.Session': Session$json,
  '.auth.v1.Identity': Identity$json,
  '.auth.v1.PasswordRegistrationRequest': PasswordRegistrationRequest$json,
  '.auth.v1.PasswordRegistrationResponse': PasswordRegistrationResponse$json,
  '.auth.v1.EmailVerificationFlow': EmailVerificationFlow$json,
  '.auth.v1.LogoutRequest': LogoutRequest$json,
  '.auth.v1.LogoutResponse': LogoutResponse$json,
  '.auth.v1.GetSessionRequest': GetSessionRequest$json,
  '.auth.v1.GetSessionResponse': GetSessionResponse$json,
};

/// Descriptor for `AuthService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List authServiceDescriptor = $convert.base64Decode(
    'CgtBdXRoU2VydmljZRJOCg1QYXNzd29yZExvZ2luEh0uYXV0aC52MS5QYXNzd29yZExvZ2luUm'
    'VxdWVzdBoeLmF1dGgudjEuUGFzc3dvcmRMb2dpblJlc3BvbnNlEmMKFFBhc3N3b3JkUmVnaXN0'
    'cmF0aW9uEiQuYXV0aC52MS5QYXNzd29yZFJlZ2lzdHJhdGlvblJlcXVlc3QaJS5hdXRoLnYxLl'
    'Bhc3N3b3JkUmVnaXN0cmF0aW9uUmVzcG9uc2USOQoGTG9nb3V0EhYuYXV0aC52MS5Mb2dvdXRS'
    'ZXF1ZXN0GhcuYXV0aC52MS5Mb2dvdXRSZXNwb25zZRJFCgpHZXRTZXNzaW9uEhouYXV0aC52MS'
    '5HZXRTZXNzaW9uUmVxdWVzdBobLmF1dGgudjEuR2V0U2Vzc2lvblJlc3BvbnNl');

