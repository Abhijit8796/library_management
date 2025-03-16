import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, Map<String, dynamic>>> getAllBranchDetails() async {
    final response = await _client.from('branches').select();
    final Map<String, Map<String, dynamic>> branchDetailsMap = {};
    for (var branch in response) {
      List<dynamic> seatLayoutDynamic = List<dynamic>.from(
        branch['seatLayout'],
      );
      List<List<String>> seatLayout =
          seatLayoutDynamic.map((innerList) {
            return List<String>.from(innerList);
          }).toList();
      branchDetailsMap[branch['name']] = {
        'id': branch['id'],
        'name': branch['name'],
        'seatLayout': seatLayout,
        'reservedSeats': branch['reservedSeats'],
        'unreservedSeats': branch['unreservedSeats'],
      };
    }
    return branchDetailsMap;
  }

  Future<List<Map<String, dynamic>>> getStudentsByBranchId(int branchId) async {
    final today = DateTime.now().toIso8601String();
    final response = await _client
        .from('students')
        .select()
        .eq('branchId', branchId)
        .gte('endDate', today);
    return List<Map<String, dynamic>>.from(response);
  }
}
