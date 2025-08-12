import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthRepository {
  AuthRepository({
    required fb_auth.FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required FirebaseMessaging messaging,
  }) : _auth = auth,
       _firestore = firestore,
       _messaging = messaging;

  final fb_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  Stream<fb_auth.User?> authStateChanges() => _auth.authStateChanges();

  Future<fb_auth.UserCredential> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final token = await _messaging.getToken();
    await _firestore.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'email': email,
      'name': name,
      'photoUrl': null,
      'isOnline': true,
      'fcmToken': token,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  Future<fb_auth.UserCredential> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': cred.user!.email ?? email,
      'isOnline': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return cred;
  }

  Future<void> logout() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await _auth.signOut();
  }

  fb_auth.User? get currentUser => _auth.currentUser;
}
