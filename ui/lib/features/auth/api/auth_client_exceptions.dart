import "package:connectrpc/connect.dart";
import "package:readintent_flutter/proto/google/rpc/error_details.pb.dart" as rpc;

/// Represents a field-level validation error from a BadRequest response.
class FieldError {
  final String field;
  final String description;

  const FieldError({required this.field, required this.description});

  @override
  String toString() => "$field: $description";

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FieldError) return false;
    return field == other.field && description == other.description;
  }

  @override
  int get hashCode => Object.hash(field, description);
}

/// Thrown when the server returns a BadRequest with field violations.
class ValidationException implements Exception {
  final String message;
  final List<FieldError> fieldErrors;

  const ValidationException({required this.message, required this.fieldErrors});

  @override
  String toString() {
    if (fieldErrors.isEmpty) return message;
    final details = fieldErrors.map((e) => e.toString()).join("; ");
    return "$message ($details)";
  }
}

/// General auth exception for non-validation errors.
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Thrown when the backend is unreachable/unhealthy (server-unavailable error
/// or a transport-level failure). Distinct from an auth failure so callers can
/// keep an optimistic cached session instead of logging the user out.
class ServerUnavailableException implements Exception {
  final String message;

  const ServerUnavailableException(this.message);

  @override
  String toString() => message;
}

/// Extracts a BadRequest from ConnectException details, if present.
rpc.BadRequest? extractBadRequest(ConnectException e) {
  for (final detail in e.details) {
    if (detail.type == "google.rpc.BadRequest") {
      return rpc.BadRequest.fromBuffer(detail.value);
    }
  }
  return null;
}

/// Handles a ConnectException by parsing BadRequest details or throwing a
/// general AuthException. Throws [ValidationException] if BadRequest details
/// are present, otherwise throws [AuthException].
Never handleConnectException(ConnectException e, String context) {
  // A server-unavailable error (HTTP 502/503/504/429) means the backend isn't
  // reachable, not that auth failed — surface it distinctly.
  if (e.code == Code.unavailable) {
    throw ServerUnavailableException("Failed to $context: ${e.message}");
  }
  final badRequest = extractBadRequest(e);
  if (badRequest != null && badRequest.fieldViolations.isNotEmpty) {
    final fieldErrors = badRequest.fieldViolations
        .map((v) => FieldError(field: v.field_1, description: v.description))
        .toList();
    throw ValidationException(message: "Failed to $context", fieldErrors: fieldErrors);
  }
  throw AuthException("Failed to $context: ${e.message}");
}
