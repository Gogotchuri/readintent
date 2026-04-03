import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:readintent_flutter/features/auth/presentation/auth_layout.dart";
import "package:readintent_flutter/features/auth/providers/auth_provider.dart";
import "package:readintent_flutter/models/auth_state.dart";

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authProvider.notifier)
          .passwordRegistration(
            _emailController.text.trim(),
            _passwordController.text,
            _firstNameController.text.trim(),
            _lastNameController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    String? fieldError(String field) {
      if (authState is! AuthError) return null;
      return authState.getJoinedFieldErrors(field);
    }

    return AuthLayout(
      title: "Create an Account",
      submitLabel: "Sign Up",
      onSubmit: _submit,
      formKey: _formKey,
      fields: [
        // First Name
        TextFormField(
          controller: _firstNameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: "First Name",
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "Please enter your first name";
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Last Name
        TextFormField(
          controller: _lastNameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: "Last Name",
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "Please enter your last name";
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Email
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: "Email",
            prefixIcon: const Icon(Icons.email_outlined),
            border: const OutlineInputBorder(),
            errorText: fieldError("email"),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "Please enter your email";
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: "Password",
            prefixIcon: const Icon(Icons.lock_outlined),
            border: const OutlineInputBorder(),
            errorText: fieldError("password"),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter a password";
            }
            if (value.length < 8) {
              return "Password must be at least 8 characters";
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: "Confirm Password",
            prefixIcon: const Icon(Icons.lock_outlined),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value != _passwordController.text) {
              return "Passwords do not match";
            }
            return null;
          },
        ),
      ],
      switchSection: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Already have an account?"),
          TextButton(onPressed: () => context.go("/login"), child: const Text("Sign In")),
        ],
      ),
      subtitle: "Sign up to get started",
    );
  }
}
