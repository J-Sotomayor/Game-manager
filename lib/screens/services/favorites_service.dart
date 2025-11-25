import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }
    return user.uid;
  }

  /// Stream que devuelve la lista de IDs de juegos favoritos del usuario.
  Stream<List<String>> getFavoritesStream() {
    final userId = _userId;
    return _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            final gameId = data['gameId'] as String?;
            // Si no existe el campo, usamos el id del doc
            return gameId ?? doc.id;
          }).toList(),
        );
  }

  /// Agregar un juego a favoritos
  Future<void> addFavorite(String gameId) async {
    final userId = _userId;

    await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(gameId) // usamos el ID del doc como el ID del juego
        .set(
      {
        'gameId': gameId,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Quitar un juego de favoritos
  Future<void> removeFavorite(String gameId) async {
    final userId = _userId;

    await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(gameId)
        .delete();
  }

  /// Ver si un juego ya está en favoritos
  Future<bool> isFavorite(String gameId) async {
    final userId = _userId;

    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(gameId)
        .get();

    return doc.exists;
  }
}
