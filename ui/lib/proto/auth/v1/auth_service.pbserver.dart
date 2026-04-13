//
//  Generated code. Do not modify.
//  source: auth/v1/auth_service.proto
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

import 'auth_service.pb.dart' as $0;
import 'auth_service.pbjson.dart';

export 'auth_service.pb.dart';

abstract class AuthServiceBase extends $pb.GeneratedService {
  $async.Future<$0.PasswordLoginResponse> passwordLogin($pb.ServerContext ctx, $0.PasswordLoginRequest request);
  $async.Future<$0.PasswordRegistrationResponse> passwordRegistration($pb.ServerContext ctx, $0.PasswordRegistrationRequest request);
  $async.Future<$0.LogoutResponse> logout($pb.ServerContext ctx, $0.LogoutRequest request);
  $async.Future<$0.GetSessionResponse> getSession($pb.ServerContext ctx, $0.GetSessionRequest request);
  $async.Future<$0.HealthResponse> health($pb.ServerContext ctx, $0.HealthRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'PasswordLogin': return $0.PasswordLoginRequest();
      case 'PasswordRegistration': return $0.PasswordRegistrationRequest();
      case 'Logout': return $0.LogoutRequest();
      case 'GetSession': return $0.GetSessionRequest();
      case 'Health': return $0.HealthRequest();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'PasswordLogin': return this.passwordLogin(ctx, request as $0.PasswordLoginRequest);
      case 'PasswordRegistration': return this.passwordRegistration(ctx, request as $0.PasswordRegistrationRequest);
      case 'Logout': return this.logout(ctx, request as $0.LogoutRequest);
      case 'GetSession': return this.getSession(ctx, request as $0.GetSessionRequest);
      case 'Health': return this.health(ctx, request as $0.HealthRequest);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => AuthServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => AuthServiceBase$messageJson;
}

