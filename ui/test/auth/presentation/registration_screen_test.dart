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
import "package:readintent_flutter/features/auth/presentation/registration_screen.dart";
import "package:readintent_flutter/features/auth/providers/auth_provider.dart";
import "package:readintent_flutter/models/auth_state.dart";
import "package:readintent_flutter/models/user.dart";

@GenerateMocks([AuthClient, SessionStorage])
import "registration_screen_test.mocks.dart";

// Analogous to the login screen tests - Some parts are direct copies
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

  Widget createRegistrationScreen() {
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
    // Keep a live listener on the connectivity stream. isOnlineProvider
    // is overridden with a constant, nothing else subscribes to it, and an
    // unsubscribed StreamProvider never emits - which would hang _restoreSession.
    container.listen(connectivityMonitorProvider, (_, _) {});
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: RegistrationScreen()),
    );
  }

  // Basic registration screen should render without crashing and show first name, last name, email, and password fields when unauthenticated (no token set in session storage on load)
  testWidgets(
    "RegistrationScreen renders first name, last name, email, and password fields when unauthenticated",
    (WidgetTester tester) async {
      await tester.pumpWidget(createRegistrationScreen());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(5));
      expect(find.widgetWithText(TextField, "First Name"), findsOneWidget);
      expect(find.widgetWithText(TextField, "Last Name"), findsOneWidget);
      expect(find.widgetWithText(TextField, "Email"), findsOneWidget);
      expect(find.widgetWithText(TextField, "Password"), findsOneWidget);
      expect(find.widgetWithText(TextField, "Confirm Password"), findsOneWidget);
    },
  );

  // When we tap the sign up button, it should call the passwordRegistration method on the auth client with the names and email and password from the text fields
  testWidgets(
    "RegistrationScreen calls passwordRegistration on auth client with names, email, and password",
    (WidgetTester tester) async {
      when(
        mockAuthClient.passwordRegistration("correct-email", "correct-password", "First", "Last"),
      ).thenAnswer(
        (_) async => Session(
          sessionToken: "token",
          user: User(id: "id", email: "correct-email", firstName: "First", lastName: "Last"),
        ),
      );
      await tester.pumpWidget(createRegistrationScreen());
      await tester.pumpAndSettle();

      // Enter first name, last name, email, and password
      await tester.enterText(find.widgetWithText(TextField, "First Name"), "First");
      await tester.enterText(find.widgetWithText(TextField, "Last Name"), "Last");
      await tester.enterText(find.widgetWithText(TextField, "Email"), "correct-email");
      await tester.enterText(find.widgetWithText(TextField, "Password"), "correct-password");
      await tester.enterText(find.widgetWithText(TextField, "Confirm Password"), "correct-password");
      await tester.tap(find.widgetWithText(ElevatedButton, "Sign Up"));
      await tester.pump(); // Start the registration process

      verify(
        mockAuthClient.passwordRegistration("correct-email", "correct-password", "First", "Last"),
      ).called(1);
    },
  );

  // Login screen should show loading indicator when we tap the login button and the login future is not completed yet, then show error message if login fails
  testWidgets("RegistrationScreen shows loading indicator on registration and error message on failure", (
    WidgetTester tester,
  ) async {
    when(mockAuthClient.passwordRegistration(any, any, any, any)).thenAnswer(
      (_) => Future.delayed(const Duration(seconds: 5), () => throw AuthException("Registration failed")),
    );
    await tester.pumpWidget(createRegistrationScreen());
    await tester.pumpAndSettle();

    // Enter first name, last name, email, and password
    await tester.enterText(find.widgetWithText(TextField, "First Name"), "First");
    await tester.enterText(find.widgetWithText(TextField, "Last Name"), "Last");
    await tester.enterText(find.widgetWithText(TextField, "Email"), "sam@example.com");
    await tester.enterText(find.widgetWithText(TextField, "Password"), "password123");
    await tester.enterText(find.widgetWithText(TextField, "Confirm Password"), "password123");
    await tester.tap(find.widgetWithText(ElevatedButton, "Sign Up"));
    await tester.pump(); // Start the registration process

    // Should show loading indicator and nothing else while waiting for registration future to complete
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text("Registration failed"), findsNothing);
    expect(find.byType(TextField), findsNothing);

    // After the future completes, it should show the error message and the form fields again
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // The general error is rendered as a bullet line ("- Registration failed").
    expect(find.textContaining("Registration failed"), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(5));

    // Drain the pending auto-clear timer so it doesn't outlive the test.
    await tester.pump(const Duration(seconds: 5));
  });

  // Check We display field validation errors completely and correctly
  testWidgets("RegistrationScreen shows field validation errors correctly", (WidgetTester tester) async {
    // AuthClient translates a BadRequest ConnectException into a ValidationException
    // before the provider sees it, so the mocked client throws the translated type.
    when(mockAuthClient.passwordRegistration(any, any, any, any)).thenThrow(
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

    await tester.pumpWidget(createRegistrationScreen());
    await tester.pumpAndSettle();

    // Enter first name, last name, email, and password
    await tester.enterText(find.widgetWithText(TextField, "First Name"), "First");
    await tester.enterText(find.widgetWithText(TextField, "Last Name"), "Last");
    await tester.enterText(find.widgetWithText(TextField, "Email"), "invalid-email");
    // Must satisfy client-side validation (>= 8 chars, matching confirmation)
    // so the request reaches the server and we exercise the server-side errors.
    await tester.enterText(find.widgetWithText(TextField, "Password"), "password123");
    await tester.enterText(find.widgetWithText(TextField, "Confirm Password"), "password123");
    await tester.tap(find.widgetWithText(ElevatedButton, "Sign Up"));
    await tester.pump(); // Start the registration process
    await tester.pumpAndSettle(); // Wait for the registration process to complete

    // Should show field validation errors
    expect(find.textContaining("general issue 1"), findsOneWidget);
    expect(find.textContaining("general issue 2"), findsOneWidget);
    expect(find.textContaining("Invalid email format"), findsOneWidget);
    expect(find.textContaining("Password too short"), findsOneWidget);

    // Drain the pending auto-clear timer so it doesn't outlive the test.
    await tester.pump(const Duration(seconds: 5));
  });

  // Successful registration
  testWidgets("RegistrationScreen successful registration saves session and updates auth state", (
    WidgetTester tester,
  ) async {
    when(
      mockAuthClient.passwordRegistration("correct-email", "correct-password", "First", "Last"),
    ).thenAnswer(
      (_) async => Session(
        sessionToken: "token",
        user: User(id: "id", email: "correct-email", firstName: "First", lastName: "Last"),
      ),
    );
    await tester.pumpWidget(createRegistrationScreen());
    await tester.pumpAndSettle();

    // Enter first name, last name, email, and password
    await tester.enterText(find.widgetWithText(TextField, "First Name"), "First");
    await tester.enterText(find.widgetWithText(TextField, "Last Name"), "Last");
    await tester.enterText(find.widgetWithText(TextField, "Email"), "correct-email");
    await tester.enterText(find.widgetWithText(TextField, "Password"), "correct-password");
    await tester.enterText(find.widgetWithText(TextField, "Confirm Password"), "correct-password");
    await tester.tap(find.widgetWithText(ElevatedButton, "Sign Up"));
    await tester.pump(); // Start the registration process
    await tester.pumpAndSettle(); // Wait for the registration process to complete

    // Check auth state is updated to AuthAuthenticated
    final authState = container.read(authProvider);
    expect(authState, isA<AuthAuthenticated>());
    final authStateData = authState as AuthAuthenticated;
    expect(authStateData.sessionToken, "token");
    expect(authStateData.user.email, "correct-email");
  });
}
