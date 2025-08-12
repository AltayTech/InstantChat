import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  UserRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<List<Map<String, dynamic>>> usersStream() {
    return _firestore
        .collection('users')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> usersExcluding({required String uid}) {
    return _firestore
        .collection('users')
        .where('uid', isNotEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }
}
