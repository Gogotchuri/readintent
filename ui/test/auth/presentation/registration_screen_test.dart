import 'package:connectrpc/connect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readintent_flutter/core/session_storage.dart';
import 'package:readintent_flutter/features/auth/api/auth_client.dart';
import 'package:readintent_flutter/features/auth/api/auth_client_exceptions.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readintent_flutter/features/auth/presentation/registration_screen.dart';
import 'package:readintent_flutter/features/auth/providers/auth_provider.dart';
import 'package:readintent_flutter/models/user.dart';
import 'package:readintent_flutter/proto/google/rpc/error_details.pb.dart';

@GenerateMocks([AuthClient, SessionStorage])
import 'registration_screen_test.mocks.dart';

// Analogous to the login screen tests - Some parts are direct copies
void main() {
  late MockAuthClient mockAuthClient;
  late MockSessionStorage mockSessionStorage;

  setUp(() {
    mockAuthClient = MockAuthClient();
    mockSessionStorage = MockSessionStorage();
    when(
      mockAuthClient.getSession(),
    ).thenThrow(ConnectException(Code.unauthenticated, "Unauthenticated"));
    when(mockSessionStorage.getToken()).thenAnswer((_) async => null);
  });

  late ProviderContainer container;

  Widget createRegistrationScreen() {
    container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthClient),
        sessionStorageProvider.overrideWithValue(mockSessionStorage),
      ],
    );
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: RegistrationScreen()),
    );
  }

  // Basic registration screen should render without crashing and show first name, last name, email, and password fields when unauthenticated (no token set in session storage on load)
  testWidgets(
    'RegistrationScreen renders first name, last name, email, and password fields when unauthenticated',
    (WidgetTester tester) async {
      await tester.pumpWidget(createRegistrationScreen());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(5));
      expect(find.widgetWithText(TextField, 'First Name'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Last Name'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Confirm Password'), findsOneWidget);
    },
  );

  // When we tap the sign up button, it should call the passwordRegistration method on the auth client with the names and email and password from the text fields
  testWidgets(
    'RegistrationScreen calls passwordRegistration on auth client with names, email, and password',
    (WidgetTester tester) async {
      when(
        mockAuthClient.passwordRegistration(
          "correct-email",
          "correct-password",
          "First",
          "Last",
        ),
      ).thenAnswer(
        (_) async => Session(
          sessionToken: "token",
          user: User(
            id: "id",
            email: "correct-email",
            firstName: "First",
            lastName: "Last",
          ),
        ),
      );
      await tester.pumpWidget(createRegistrationScreen());
      await tester.pumpAndSettle();

      // Enter first name, last name, email, and password
      await tester.enterText(
        find.widgetWithText(TextField, 'First Name'),
        'First',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Last Name'),
        'Last',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'correct-email',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'correct-password',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm Password'),
        'correct-password',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pump(); // Start the registration process

      verify(
        mockAuthClient.passwordRegistration(
          "correct-email",
          "correct-password",
          "First",
          "Last",
        ),
      ).called(1);
    },
  );

  // Login screen should show loading indicator when we tap the login button and the login future is not completed yet, then show error message if login fails
  testWidgets(
    'RegistrationScreen shows loading indicator on registration and error message on failure',
    (WidgetTester tester) async {
      when(mockAuthClient.passwordRegistration(any, any, any, any)).thenAnswer(
        (_) => Future.delayed(
          const Duration(seconds: 5),
          () => throw AuthException('Registration failed'),
        ),
      );
      await tester.pumpWidget(createRegistrationScreen());
      await tester.pumpAndSettle();

      // Enter first name, last name, email, and password
      await tester.enterText(
        find.widgetWithText(TextField, 'First Name'),
        'First',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Last Name'),
        'Last',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'sam@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm Password'),
        'password123',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pump(); // Start the registration process

      // Should show loading indicator and nothing else while waiting for registration future to complete
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Registration failed'), findsNothing);
      expect(find.byType(TextField), findsNothing);

      // After the future completes, it should show the error message and the form fields again
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Registration failed'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(5));
    },
  );

  // Check We display field validation errors completely and correctly
  testWidgets('RegistrationScreen shows field validation errors correctly', (
    WidgetTester tester,
  ) async {
    final badRequest = BadRequest(
      fieldViolations: [
        BadRequest_FieldViolation(
          field_1: 'general',
          description: 'general issue 1',
        ),
        BadRequest_FieldViolation(
          field_1: 'general',
          description: 'general issue 2',
        ),
        BadRequest_FieldViolation(
          field_1: 'email',
          description: 'Invalid email format',
        ),
        BadRequest_FieldViolation(
          field_1: 'password',
          description: 'Password too short',
        ),
      ],
    );

    when(mockAuthClient.passwordRegistration(any, any, any, any)).thenThrow(
      ConnectException(
        Code.invalidArgument,
        'Validation failed',
        details: [
          ErrorDetail('google.rpc.BadRequest', badRequest.writeToBuffer()),
        ],
      ),
    );

    await tester.pumpWidget(createRegistrationScreen());
    await tester.pumpAndSettle();

    // Enter first name, last name, email, and password
    await tester.enterText(
      find.widgetWithText(TextField, 'First Name'),
      'First',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Last Name'), 'Last');
    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'invalid-email',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'short');
    await tester.enterText(find.widgetWithText(TextField, 'Confirm Password'), 'short');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pump(); // Start the registration process
    await tester
        .pumpAndSettle(); // Wait for the registration process to complete

    // Should show field validation errors
    expect(find.text('general issue 1'), findsOneWidget);
    expect(find.text('general issue 2'), findsOneWidget);
    expect(find.text('Invalid email format'), findsOneWidget);
    expect(find.text('Password too short'), findsOneWidget);
  });

  // Successful registration
  testWidgets(
    'RegistrationScreen successful registration saves session and updates auth state',
    (WidgetTester tester) async {
      when(
        mockAuthClient.passwordRegistration(
          "correct-email",
          "correct-password",
          "First",
          "Last",
        ),
      ).thenAnswer(
        (_) async => Session(
          sessionToken: "token",
          user: User(
            id: "id",
            email: "correct-email",
            firstName: "First",
            lastName: "Last",
          ),
        ),
      );
      await tester.pumpWidget(createRegistrationScreen());
      await tester.pumpAndSettle();

      // Enter first name, last name, email, and password
      await tester.enterText(
        find.widgetWithText(TextField, 'First Name'),
        'First',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Last Name'),
        'Last',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'correct-email',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'correct-password',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm Password'),
        'correct-password',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pump(); // Start the registration process
      await tester
          .pumpAndSettle(); // Wait for the registration process to complete

      // Check auth state is updated to AuthAuthenticated
      final authState = container.read(authProvider);
      expect(authState, isA<AuthAuthenticated>());
      final authStateData = authState as AuthAuthenticated;
      expect(authStateData.sessionToken, 'token');
      expect(authStateData.user.email, 'correct-email');
    },
  );
}
