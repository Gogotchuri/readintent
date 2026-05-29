import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:readintent_flutter/features/auth/providers/auth_provider.dart";

class SocialAuthSection extends ConsumerWidget {
  const SocialAuthSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {
          ref.read(authProvider.notifier).googleSignIn();
        },
        icon: SvgPicture.asset("assets/images/google_logo.svg", height: 20, width: 20),
        label: const Text("Continue with Google"),
      ),
    );
  }
}
