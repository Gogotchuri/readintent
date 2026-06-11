import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:readintent_flutter/features/auth/presentation/social_auth_section.dart";
import "package:readintent_flutter/features/auth/presentation/splash_screen.dart";
import "package:readintent_flutter/features/auth/providers/auth_provider.dart";
import "package:readintent_flutter/models/auth_state.dart";

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
    this.subtitle = "",
    required this.fields,
    required this.submitLabel,
    required this.onSubmit,
    this.switchSection,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading || authState is AuthInitial;

    List<String>? generalErrors;
    if (authState is AuthError) {
      generalErrors = authState.getGeneralErrors();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      // Switch between loading splash and form based on auth state
      // When logging in or signing up, show the splash screen during loading, and since home page has
      // Fade animation registered in routes during transition, it will fade out the splash and fade in the articles screen
      child: isLoading
          ? const SplashScreen(key: ValueKey("loading"))
          : Scaffold(
              key: const ValueKey("form"),
              body: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        children: [
                          // General errors messages displayed as buttet points at the top
                          if (generalErrors != null && generalErrors.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: generalErrors
                                    .map(
                                      (e) => Text(
                                        "- $e",
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onErrorContainer,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: SvgPicture.asset(
                                    "assets/r-icon.svg",
                                    width: 72,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                  textAlign: TextAlign.center,
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    subtitle,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
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
                                        "OR",
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
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
            ),
    );
  }
}
