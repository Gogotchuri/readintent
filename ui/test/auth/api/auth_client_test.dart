import "package:connectrpc/connect.dart";
import "package:flutter_test/flutter_test.dart";
import "package:readintent_flutter/features/auth/api/auth_client.dart";
import "package:readintent_flutter/features/auth/api/auth_client_exceptions.dart";
import "package:readintent_flutter/features/auth/api/auth_service_client.dart";
import "package:mockito/annotations.dart";
import "package:mockito/mockito.dart";
import "package:readintent_flutter/proto/auth/v1/auth_service.pb.dart" as auth_pb;
import "package:readintent_flutter/proto/google/rpc/error_details.pb.dart";

@GenerateMocks([AuthServiceClientI])
import "auth_client_test.mocks.dart";

final sessionMock = auth_pb.Session(
  sessionToken: "mock-session-token",
  identity: auth_pb.Identity(id: "user-id-1", email: "user@example.com", firstName: "John", lastName: "Doe"),
);

void main() {
  late MockAuthServiceClientI mockClient;
  late AuthClient authClient;

  setUp(() {
    mockClient = MockAuthServiceClientI();
    authClient = AuthClient(
      getToken: () async => "mock-token",
      onUnauthorized: () async {},
      client: mockClient,
    );
  });

  void expectSessionMapsCorrectly(Session session, auth_pb.Session proto) {
    expect(session.sessionToken, proto.sessionToken);
    expect(session.user.id, proto.identity.id);
    expect(session.user.email, proto.identity.email);
    expect(session.user.firstName, proto.identity.firstName);
    expect(session.user.lastName, proto.identity.lastName);
  }

  // Test we are mapping proto responses to our Session model correctly
  test("Proto types mapped to local Session model correctly", () async {
    // Login
    when(
      mockClient.passwordLogin(any),
    ).thenAnswer((_) async => auth_pb.PasswordLoginResponse(session: sessionMock));

    final session = await authClient.passwordLogin("email", "password");
    expectSessionMapsCorrectly(session, sessionMock);

    // Registration
    when(
      mockClient.passwordRegistration(any),
    ).thenAnswer((_) async => auth_pb.PasswordRegistrationResponse(session: sessionMock));

    final regSession = await authClient.passwordRegistration("email", "password", "first", "last");
    expectSessionMapsCorrectly(regSession, sessionMock);

    // GetSession
    when(
      mockClient.getSession(any),
    ).thenAnswer((_) async => auth_pb.GetSessionResponse(session: sessionMock));
    final getSession = await authClient.getSession();
    expectSessionMapsCorrectly(getSession, sessionMock);
  });

  // Test we are handling errors correctly by converting them to AuthExceptions
  test("By default any exceptions are converted to AuthExceptions", () async {
    when(mockClient.passwordLogin(any)).thenThrow(Exception("Login failed"));

    expect(
      () => authClient.passwordLogin("email", "password"),
      // Verify that an AuthException is thrown with the expected message
      throwsA(isA<AuthException>().having((e) => e.message, "message", contains("Login failed"))),
    );

    when(
      mockClient.passwordRegistration(any),
    ).thenThrow(ConnectException(Code.unauthenticated, "Registration failed"));
    expect(
      () => authClient.passwordRegistration("email", "password", "first", "last"),
      throwsA(isA<AuthException>().having((e) => e.message, "message", contains("Registration failed"))),
    );
  });

  test("Validation error produces when ConnectException has details of by google.rpc.BadRequest", () async {
    final badRequest = BadRequest(
      fieldViolations: [
        BadRequest_FieldViolation(field_1: "general", description: "general issue 1"),
        BadRequest_FieldViolation(field_1: "general", description: "general issue 2"),
        BadRequest_FieldViolation(field_1: "email", description: "Invalid email format"),
        BadRequest_FieldViolation(field_1: "password", description: "Password too short"),
      ],
    );

    when(mockClient.passwordLogin(any)).thenThrow(
      ConnectException(
        Code.invalidArgument,
        "Validation failed",
        details: [ErrorDetail("google.rpc.BadRequest", badRequest.writeToBuffer())],
      ),
    );

    expect(
      () => authClient.passwordLogin("email", "password"),
      throwsA(
        isA<ValidationException>()
            .having((e) => e.message, "message", contains("Failed to login"))
            .having(
              (e) => e.fieldErrors,
              "fieldErrors",
              containsAll([
                FieldError(field: "general", description: "general issue 1"),
                FieldError(field: "general", description: "general issue 2"),
                FieldError(field: "email", description: "Invalid email format"),
                FieldError(field: "password", description: "Password too short"),
              ]),
            ),
      ),
    );
  });
}
