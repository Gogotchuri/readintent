import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readintent_flutter/features/auth/presentation/loading_screen.dart';
import 'package:readintent_flutter/features/auth/presentation/social_auth_section.dart';
import 'package:readintent_flutter/features/auth/providers/auth_provider.dart';

class AuthLayout extends ConsumerWidget {
  final String title;
  final String subtitle;
  final List<Widget> fields;
  final String submitLabel;
  final VoidCallback onSubmit;
  final Widget? switchSection;
  final GlobalKey<FormState> formKey;

  const AuthLayout({
    super.key,
    required this.title,
    this.subtitle = '',
    required this.fields,
    required this.submitLabel,
    required this.onSubmit,
    this.switchSection,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState is AuthLoading) {
      return const LoadingScreen();
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  if (authState is AuthError)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        authState.message,
                        style: TextStyle(color: Colors.red[800]),
                      ),
                    ),
                  Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 32),

                        // Render fields
                        ...fields,

                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: onSubmit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(submitLabel),
                        ),
                        // Divider with "OR"
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'OR',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Social Auth
                        SocialAuthSection(),
                        const SizedBox(height: 16),
                        if (switchSection != null) ...[
                          const SizedBox(height: 12),
                          switchSection!,
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
