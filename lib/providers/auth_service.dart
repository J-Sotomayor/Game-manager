import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? user;

  AuthService() {
    _auth.authStateChanges().listen((u) {
      user = u;
      notifyListeners();
    });
  }

  /// LOGIN: Iniciar sesión con correo y contraseña
  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      // Aquí puedes mapear códigos si quieres mensajes más específicos
      // e.code: 'invalid-email', 'user-not-found', 'wrong-password', etc.
      throw e.message ?? 'Error al iniciar sesión';
    } catch (_) {
      throw 'Error desconocido al iniciar sesión';
    }
  }

  /// REGISTER: Crear usuario en Auth + guardar datos en Firestore
  ///
  /// Se usa así desde RegisterPage:
  ///   await auth.register(name, email, password);
  Future<void> register(String name, String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Crear documento en Firestore: /users/{uid}
      await _db.collection('users').doc(cred.user!.uid).set({
        'displayName': name.trim(),
        'email': email.trim(),
        'photoUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Opcional: obligar a iniciar sesión manualmente después de registrarse
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Error al registrar usuario';
    } catch (_) {
      throw 'Error desconocido al registrar usuario';
    }
  }

  /// Cerrar sesión normal
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// (Opcional) Eliminar cuenta + datos.
  /// Si ya tienes otra versión para esto, puedes combinarlo.
  Future<void> deleteAccountCompletely() async {
    final current = _auth.currentUser;
    if (current == null) {
      throw 'No hay usuario autenticado.';
    }

    final uid = current.uid;

    // 1) Intentar borrar subcolección de favoritos si la usas
    try {
      final favsSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .get();
      for (final d in favsSnap.docs) {
        await d.reference.delete();
      }
    } catch (_) {
      // Si no existe, no pasa nada
    }

    // 2) Borrar documento principal del usuario
    try {
      await _db.collection('users').doc(uid).delete();
    } catch (_) {
      // Aunque falle, seguimos con Auth para no dejar la cuenta activa
    }

    // 3) Borrar cuenta de Auth
    try {
      await current.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'Por seguridad, inicia sesión de nuevo antes de eliminar tu cuenta.';
      }
      throw e.message ?? 'No se pudo eliminar la cuenta';
    }
  }
}
