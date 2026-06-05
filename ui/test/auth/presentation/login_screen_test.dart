import "package:connectrpc/connect.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:readintent_flutter/core/connectivity.dart";
import "package:readintent_flutter/core/session_storage.dart";
import "package:readintent_flutter/features/auth/api/auth_client.dart";
import "package:readintent_flutter/features/auth/api/auth_client_exceptions.dart";
import "package:mockito/annotations.dart";
import "package:mockito/mockito.dart";
import "package:readintent_flutter/features/auth/presentation/login_screen.dart";
import "package:readintent_flutter/features/auth/providers/auth_provider.dart";
import "package:readintent_flutter/models/auth_state.dart";
import "package:readintent_flutter/models/user.dart";

@GenerateMocks([AuthClient, SessionStorage])
import "login_screen_test.mocks.dart";

void main() {
  late MockAuthClient mockAuthClient;
  late MockSessionStorage mockSessionStorage;

  setUp(() {
    mockAuthClient = MockAuthClient();
    mockSessionStorage = MockSessionStorage();
    when(mockAuthClient.getSession()).thenThrow(ConnectException(Code.unauthenticated, "Unauthenticated"));
    when(mockSessionStorage.getToken()).thenAnswer((_) async => null);
  });

  late ProviderContainer container;

  tearDown(() {
    // Dispose the provider so any scheduled error-clear timer is cancelled.
    container.dispose();
  });

  Widget createLoginScreen() {
    container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthClient),
        sessionStorageProvider.overrideWithValue(mockSessionStorage),
        isOnlineProvider.overrideWithValue(true),
        // _restoreSession reads connectivityMonitorProvider directly (not the
        // isOnlineProvider override), so stub it to avoid the real plugin.
        connectivityMonitorProvider.overrideWith((ref) => Stream.value(true)),
      ],
    );
    // Keep a live listener on the connectivity stream. Because isOnlineProvider
    // is overridden with a constant, nothing else subscribes to it, and an
    // unsubscribed StreamProvider never emits - which would hang _restoreSession.
    container.listen(connectivityMonitorProvider, (_, _) {});
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  // Basic login screen should render without crashing and show email and password fields when unauthenticated (no token set in session storage on load)
  testWidgets("LoginScreen renders email and password fields when unauthenticated", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.widgetWithText(TextField, "Email"), findsOneWidget);
    expect(find.widgetWithText(TextField, "Password"), findsOneWidget);
  });

  // The login screen should show loading state when we are trying to fetch the session (simulate this by making getSession return a Future that never completes) and not show the form fields
  testWidgets("LoginScreen shows loading state when fetching session", (WidgetTester tester) async {
    // Setup artificial delay on getSession to simulate AuthInitial state for longer and display loading indicator
    when(mockAuthClient.getSession()).thenAnswer(
      (_) => Future.delayed(
        const Duration(seconds: 5),
        () => throw ConnectException(Code.unauthenticated, "Unauthenticated"),
      ),
    );
    when(mockSessionStorage.getToken()).thenAnswer((_) async => "mock-token");
    await tester.pumpWidget(createLoginScreen());
    await tester.pump(); // Start the build and trigger the getSession call

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    // If we wait for the future to complete, it should then show the form fields since we are unauthenticated
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  // When we tap the login button, it should call the passwordLogin method on the auth client with the email and password from the text fields
  testWidgets("LoginScreen calls passwordLogin on auth client with email and password", (
    WidgetTester tester,
  ) async {
    when(mockAuthClient.passwordLogin("correct-email", "correct-password")).thenAnswer(
      (_) async => Session(
        sessionToken: "token",
        user: User(id: "id", email: "correct-email", firstName: "First", lastName: "Last"),
      ),
    );
    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    // Enter email and password
    await tester.enterText(find.widgetWithText(TextField, "Email"), "correct-email");
    await tester.enterText(find.widgetWithText(TextField, "Password"), "correct-password");
    await tester.tap(find.widgetWithText(ElevatedButton, "Login"));
    await tester.pump(); // Start the login process

    verify(mockAuthClient.passwordLogin("correct-email", "correct-password")).called(1);
  });

  // Login screen should show loading indicator when we tap the login button and the login future is not completed yet, then show error message if login fails
  testWidgets("LoginScreen shows loading indicator on login and error message on failure", (
    WidgetTester tester,
  ) async {
    when(mockAuthClient.passwordLogin(any, any)).thenAnswer(
      (_) => Future.delayed(const Duration(seconds: 5), () => throw AuthException("Login failed")),
    );
    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    // Enter email and password
    await tester.enterText(find.widgetWithText(TextField, "Email"), "sam@example.com");
    await tester.enterText(find.widgetWithText(TextField, "Password"), "password123");
    await tester.tap(find.widgetWithText(ElevatedButton, "Login"));
    await tester.pump(); // Start the login process

    // Should show loading indicator and nothing else while waiting for login future to complete
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text("Login failed"), findsNothing);
    expect(find.byType(TextField), findsNothing);

    // After the future completes, it should show the error message and the form fields again
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // The general error is rendered as a bullet line ("- Login failed").
    expect(find.textContaining("Login failed"), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    // Drain the pending auto-clear timer so it doesn't outlive the test.
    await tester.pump(const Duration(seconds: 5));
  });

  // Check We display field validation errors completely and correctly
  testWidgets("LoginScreen shows field validation errors correctly", (WidgetTester tester) async {
    // AuthClient translates a BadRequest ConnectException into a ValidationException
    // before the provider sees it, so the mocked client throws the translated type.
    when(mockAuthClient.passwordLogin(any, any)).thenThrow(
      const ValidationException(
        message: "Validation failed",
        fieldErrors: [
          FieldError(field: "general", description: "general issue 1"),
          FieldError(field: "general", description: "general issue 2"),
          FieldError(field: "email", description: "Invalid email format"),
          FieldError(field: "password", description: "Password too short"),
        ],
      ),
    );

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    // Enter email and password
    await tester.enterText(find.widgetWithText(TextField, "Email"), "invalid-email");
    await tester.enterText(find.widgetWithText(TextField, "Password"), "short");
    await tester.tap(find.widgetWithText(ElevatedButton, "Login"));
    await tester.pump(); // Start the login process
    await tester.pumpAndSettle(); // Wait for the login process to complete

    // Should show field validation errors
    expect(find.textContaining("general issue 1"), findsOneWidget);
    expect(find.textContaining("general issue 2"), findsOneWidget);
    expect(find.textContaining("Invalid email format"), findsOneWidget);
    expect(find.textContaining("Password too short"), findsOneWidget);

    // Drain the pending auto-clear timer so it doesn't outlive the test.
    await tester.pump(const Duration(seconds: 5));
  });

  // Successful login
  testWidgets("LoginScreen successful login saves session and updates auth state", (
    WidgetTester tester,
  ) async {
    when(mockAuthClient.passwordLogin("correct-email", "correct-password")).thenAnswer(
      (_) async => Session(
        sessionToken: "token",
        user: User(id: "id", email: "correct-email", firstName: "First", lastName: "Last"),
      ),
    );
    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    // Enter email and password
    await tester.enterText(find.widgetWithText(TextField, "Email"), "correct-email");
    await tester.enterText(find.widgetWithText(TextField, "Password"), "correct-password");
    await tester.tap(find.widgetWithText(ElevatedButton, "Login"));
    await tester.pump(); // Start the login process
    await tester.pumpAndSettle(); // Wait for the login process to complete

    // Check auth state is updated to AuthAuthenticated
    final authState = container.read(authProvider);
    expect(authState, isA<AuthAuthenticated>());
    final authStateData = authState as AuthAuthenticated;
    expect(authStateData.sessionToken, "token");
    expect(authStateData.user.email, "correct-email");
  });
}
