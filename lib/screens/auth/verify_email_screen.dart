import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final email = auth.firebaseUser?.email ?? '';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_read_outlined,
                  size: 72, color: Colors.indigo),
              const SizedBox(height: 16),
              Text('Verify your email',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'We sent a verification link to\n$email\nCheck your inbox (and spam), then tap the button below.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  await auth.refreshVerification();
                  if (context.mounted && !auth.isVerified) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Not verified yet. Open the link first.')));
                  }
                },
                child: const Text("I've verified my email"),
              ),
              TextButton(
                onPressed: () async {
                  await auth.resendVerification();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verification email sent')));
                  }
                },
                child: const Text('Resend email'),
              ),
              TextButton(onPressed: auth.logout, child: const Text('Log out')),
            ],
          ),
        ),
      ),
    );
  }
}