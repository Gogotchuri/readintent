import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialAuthSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {
          // TODO: Implement Google Sign-In
        },
        icon: SvgPicture.asset(
          'assets/images/google_logo.svg',
          height: 20,
          width: 20,
        ),
        label: const Text('Continue with Google'),
      ),
    );
  }
}
