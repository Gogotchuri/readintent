import "package:connectrpc/connect.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:mockito/annotations.dart";
import "package:mockito/mockito.dart";
import "package:readintent_flutter/core/session_storage.dart";
import "package:readintent_flutter/features/auth/api/auth_client.dart";
import "package:readintent_flutter/features/auth/api/auth_service_client.dart";
import "package:readintent_flutter/features/auth/providers/auth_provider.dart";
import "package:readintent_flutter/main.dart";
import "package:readintent_flutter/models/user.dart";
import "package:readintent_flutter/proto/auth/v1/auth_service.pb.dart" as auth_pb;
import "package:readintent_flutter/proto/google/rpc/error_details.pbserver.dart";

@GenerateMocks([AuthServiceClientI, SessionStorage])
import "auth_flow_test.mocks.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthServiceClientI mockRPCClient;
  late MockSessionStorage mockSessionStorage;
  late ProviderContainer container;

  final protoSession = auth_pb.Session(
    sessionToken: "test-session-token",
    identity: auth_pb.Identity(
      id: "user-id-1",
      email: "user@example.com",
      firstName: "John",
      lastName: "Doe",
    ),
  );

  setUp(() {
    mockRPCClient = MockAuthServiceClientI();
    mockSessionStorage = MockSessionStorage();

    // SessionStorage mock can default to noop
    when(mockSessionStorage.getToken()).thenAnswer((_) async => null);
    when(mockSessionStorage.saveToken(any)).thenAnswer((_) async {});
    when(mockSessionStorage.getUser()).thenAnswer((_) async => null);
    when(mockSessionStorage.saveUser(any)).thenAnswer((_) async {});
  });

  Widget createApp() {
    container = ProviderContainer(
      overrides: [
        sessionStorageProvider.overrideWithValue(mockSessionStorage),
        authServiceProvider.overrideWith((ref) {
          return AuthClient(
            onUnauthorized: () => ref.read(authProvider.notifier).logout(),
            client: mockRPCClient,
          );
        }),
      ],
    );
    return UncontrolledProviderScope(container: container, child: const MyApp());
  }

  group("Initialization flows", () {
    testWidgets("no session goes to login screen", (WidgetTester tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      expect(find.text("Login"), findsOneWidget);
    });

    testWidgets("valid session goes to home screen", (WidgetTester tester) async {
      when(
        mockRPCClient.getSession(any),
      ).thenAnswer((_) async => auth_pb.GetSessionResponse(session: protoSession));
      when(mockSessionStorage.getToken()).thenAnswer((_) async => "test-session-token");
      when(mockSessionStorage.getUser()).thenAnswer((_) async => User.fromRpcIdentity(protoSession.identity));

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      expect(
        find.text("Welcome, John Doe!"),
        findsOneWidget,
      ); // TODO change this once we actually have a home screen
    });

    testWidgets("invalid session goes to login screen", (WidgetTester tester) async {
      when(mockRPCClient.getSession(any)).thenThrow(Exception("Invalid session"));
      when(mockSessionStorage.getToken()).thenAnswer((_) async => "invalid-session-token");

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      expect(find.text("Login"), findsOneWidget);
    });
  });

  group("Authentication flows", () {
    testWidgets("Login success", (WidgetTester tester) async {
      when(
        mockRPCClient.passwordLogin(any),
      ).thenAnswer((_) async => auth_pb.PasswordLoginResponse(session: protoSession));

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Enter email and password and submit
      await tester.enterText(find.widgetWithText(TextField, "Email"), "user@example.com");
      await tester.enterText(find.widgetWithText(TextField, "Password"), "password");
      await tester.tap(find.widgetWithText(ElevatedButton, "Login"));
      await tester.pumpAndSettle();

      expect(find.text("Welcome, John Doe!"), findsOneWidget);
    });

    testWidgets("Login general fail", (WidgetTester tester) async {
      when(mockRPCClient.passwordLogin(any)).thenThrow(Exception("Login failed"));

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Enter email and password and submit
      await tester.enterText(find.widgetWithText(TextField, "Email"), "user@example.com");
      await tester.enterText(find.widgetWithText(TextField, "Password"), "password");
      await tester.tap(find.widgetWithText(ElevatedButton, "Login"));
      await tester.pumpAndSettle();

      expect(find.textContaining("Login failed"), findsOneWidget);
    });

    testWidgets("Login field validation", (WidgetTester tester) async {
      final badRequest = BadRequest(
        fieldViolations: [
          BadRequest_FieldViolation(field_1: "general", description: "general issue 1"),
          BadRequest_FieldViolation(field_1: "general", description: "general issue 2"),
          BadRequest_FieldViolation(field_1: "email", description: "Invalid email format"),
        ],
      );

      when(mockRPCClient.passwordLogin(any)).thenThrow(
        ConnectException(
          Code.invalidArgument,
          "Validation failed",
          details: [ErrorDetail("google.rpc.BadRequest", badRequest.writeToBuffer())],
        ),
      );

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Enter login details and submit
      await tester.enterText(find.widgetWithText(TextField, "Email"), "user@example.com");
      await tester.enterText(find.widgetWithText(TextField, "Password"), "password");
      await tester.tap(find.widgetWithText(ElevatedButton, "Login"));
      await tester.pumpAndSettle();

      // Should show field validation errors
      expect(find.textContaining("general issue 1"), findsOneWidget);
      expect(find.textContaining("general issue 2"), findsOneWidget);
      expect(find.textContaining("Invalid email format"), findsOneWidget);
    });

    group("Registration flows", () {
      testWidgets("Registration success", (WidgetTester tester) async {
        when(
          mockRPCClient.passwordRegistration(any),
        ).thenAnswer((_) async => auth_pb.PasswordRegistrationResponse(session: protoSession));

        await tester.pumpWidget(createApp());
        await tester.pumpAndSettle();

        // Go to registration screen
        await tester.tap(find.widgetWithText(TextButton, "Sign Up"));
        await tester.pumpAndSettle();

        // Enter registration details and submit
        await tester.enterText(find.widgetWithText(TextField, "Email"), "user@example.com");
        await tester.enterText(find.widgetWithText(TextField, "First Name"), "John");
        await tester.enterText(find.widgetWithText(TextField, "Last Name"), "Doe");
        await tester.enterText(find.widgetWithText(TextField, "Password"), "password");
        await tester.enterText(find.widgetWithText(TextField, "Confirm Password"), "password");
        await tester.tap(find.widgetWithText(ElevatedButton, "Sign Up"));
        await tester.pumpAndSettle();

        expect(find.text("Welcome, John Doe!"), findsOneWidget);
      });
    });

    testWidgets("Registration general fail", (WidgetTester tester) async {
      when(mockRPCClient.passwordRegistration(any)).thenThrow(Exception("Registration failed"));

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Go to registration screen
      await tester.tap(find.widgetWithText(TextButton, "Sign Up"));
      await tester.pumpAndSettle();

      // Enter registration details and submit
      await tester.enterText(find.widgetWithText(TextField, "Email"), "user@example.com");
      await tester.enterText(find.widgetWithText(TextField, "First Name"), "John");
      await tester.enterText(find.widgetWithText(TextField, "Last Name"), "Doe");
      await tester.enterText(find.widgetWithText(TextField, "Password"), "password");
      await tester.enterText(find.widgetWithText(TextField, "Confirm Password"), "password");
      await tester.tap(find.widgetWithText(ElevatedButton, "Sign Up"));
      await tester.pumpAndSettle();

      expect(find.textContaining("Registration failed"), findsOneWidget);
    });

    testWidgets("Registration field validation", (WidgetTester tester) async {
      final badRequest = BadRequest(
        fieldViolations: [
          BadRequest_FieldViolation(field_1: "general", description: "general issue 1"),
          BadRequest_FieldViolation(field_1: "general", description: "general issue 2"),
          BadRequest_FieldViolation(field_1: "email", description: "Invalid email format"),
          BadRequest_FieldViolation(field_1: "password", description: "Password too short"),
        ],
      );

      when(mockRPCClient.passwordRegistration(any)).thenThrow(
        ConnectException(
          Code.invalidArgument,
          "Validation failed",
          details: [ErrorDetail("google.rpc.BadRequest", badRequest.writeToBuffer())],
        ),
      );

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Go to registration screen
      await tester.tap(find.widgetWithText(TextButton, "Sign Up"));
      await tester.pumpAndSettle();

      // Enter registration details and submit
      await tester.enterText(find.widgetWithText(TextField, "Email"), "user@example.com");
      await tester.enterText(find.widgetWithText(TextField, "First Name"), "John");
      await tester.enterText(find.widgetWithText(TextField, "Last Name"), "Doe");
      await tester.enterText(find.widgetWithText(TextField, "Password"), "password");
      await tester.enterText(find.widgetWithText(TextField, "Confirm Password"), "password");
      await tester.tap(find.widgetWithText(ElevatedButton, "Sign Up"));
      await tester.pumpAndSettle();

      // Check we are actually on sign up still
      expect(find.text("Create an Account"), findsOneWidget);
      // Should show field validation errors
      expect(find.textContaining("general issue 1"), findsOneWidget);
      expect(find.textContaining("general issue 2"), findsOneWidget);
      expect(find.textContaining("Invalid email format"), findsOneWidget);
      expect(find.textContaining("Password too short"), findsOneWidget);
    });

    testWidgets("Logout", (WidgetTester tester) async {
      when(
        mockRPCClient.passwordLogin(any),
      ).thenAnswer((_) async => auth_pb.PasswordLoginResponse(session: protoSession));

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Login first
      await tester.enterText(find.widgetWithText(TextField, "Email"), "user@example.com");
      await tester.enterText(find.widgetWithText(TextField, "Password"), "password");
      await tester.tap(find.widgetWithText(ElevatedButton, "Login"));
      await tester.pumpAndSettle();

      // Logout
      await tester.tap(find.widgetWithText(ElevatedButton, "Logout"));
      await tester.pumpAndSettle();

      expect(find.text("Login"), findsOneWidget);
    });
  });
}
