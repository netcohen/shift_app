import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  GoogleSignInAccount? _user;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar.readonly',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  Future<void> _handleSignIn() async {
    try {
      final account = await _googleSignIn.signIn();
      setState(() => _user = account);
    } catch (error) {
      debugPrint('❌ Sign-in error: $error');
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.signOut();
    setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift App – התחברות'),
        actions: [
          if (_user != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleSignOut,
            ),
        ],
      ),
      body: Center(
        child:
            _user == null
                ? ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('התחבר עם Google'),
                  onPressed: _handleSignIn,
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(_user!.photoUrl ?? ''),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _user!.displayName ?? 'לא ידוע',
                      style: const TextStyle(fontSize: 20),
                    ),
                    Text(
                      _user!.email,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
      ),
    );
  }
}
