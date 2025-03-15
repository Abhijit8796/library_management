import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addBranch(Map<String, dynamic> branch) async {
    await _db.collection('branches').add(branch);
  }

  Future<Map<String, Map<String, dynamic>>> getAllBranchDetails() async {
    final querySnapshot = await _db.collection('branches').get();
    final branchDetailsMap = <String, Map<String, dynamic>>{};

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      branchDetailsMap[doc['name']] = data;
    }

    return branchDetailsMap;
  }

  Future<List<Map<String, dynamic>>> getStudentsByBranchId(String branchId) async {
    final querySnapshot = await _db.collection('students').where('branchId', isEqualTo: branchId).get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }
}