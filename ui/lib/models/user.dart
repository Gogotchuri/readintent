import 'package:readintent_flutter/proto/auth/v1/auth_service.pb.dart';

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
    );
  }
  
  factory User.fromRpcIdentity(Identity identity) {
    return User(
      id: identity.id,
      firstName: identity.firstName,
      lastName: identity.lastName,
      email: identity.email,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
    };
  }
}
