// lib/services/native_google_auth.dart

import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:barberiapp/config/env_private.dart';

// Configuración base
final googleSignIn = GoogleSignIn(
  scopes: const ['email', 'profile'],
  clientId: Platform.isIOS ? EnvPrivate.iosClientId : null,
  serverClientId: EnvPrivate.webClientId, // debe ser tu Client ID Web
);

// Helper: login nativo + intercambio con Supabase
Future<AuthResponse?> signInWithGoogleNative() async {
  final account = await googleSignIn.signIn();
  if (account == null) return null; // usuario canceló

  final auth = await account.authentication;
  final idToken = auth.idToken;
  final accessToken = auth.accessToken;

  if (idToken == null) {
    throw Exception('No se recibió idToken de Google');
  }

  return await Supabase.instance.client.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: idToken,
    accessToken: accessToken, // opcional
  );
}

// Helper: cerrar sesión en Google y Supabase
Future<void> googleSignOut() async {
  await googleSignIn.signOut();
  await Supabase.instance.client.auth.signOut();
}
