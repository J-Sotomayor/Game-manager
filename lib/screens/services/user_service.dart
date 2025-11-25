import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  Future<DocumentSnapshot> getUser() async {
    final user = _auth.currentUser!;
    return await _db.collection("users").doc(user.uid).get();
  }

  Future<void> updateName(String firstName, String lastName) async {
  final user = _auth.currentUser!;
  await _db.collection('users').doc(user.uid).update({
    'firstName': firstName,
    'lastName': lastName,
    'displayName': '$firstName $lastName', // para mostrar nombre completo
    });
  }


  Future<void> updateProfileImage(String imagePath) async {
    final user = _auth.currentUser!;
    final ref = _storage.ref().child("profile/${user.uid}.jpg");
    await ref.putFile(File(imagePath));
    final imageUrl = await ref.getDownloadURL();
    await _db.collection("users").doc(user.uid).update({
      'photoUrl': imageUrl,
    });
  }  
  Future<void> updatePhoto(String imagePath) async {
    final user = _auth.currentUser!;
    final ref = _storage.ref().child("profile/${user.uid}.jpg");
    await ref.putFile(File(imagePath));
    final url = await ref.getDownloadURL();
    await _db.collection('users').doc(user.uid).update({'photoUrl': url});
  }

  
}
