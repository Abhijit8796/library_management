import 'package:flutter/material.dart';

class GlobalState with ChangeNotifier {
  Map<String, dynamic>? _branchDetails;
  List<Map<String, dynamic>> _students = [];

  Map<String, dynamic>? get branchDetails => _branchDetails;

  List<Map<String, dynamic>> get students => _students;

  void setBranchDetails(Map<String, dynamic>? branchDetails) {
    _branchDetails = branchDetails;
    notifyListeners();
  }

  void setStudents(List<Map<String, dynamic>> students) {
    _students = students;
    notifyListeners();
  }
}