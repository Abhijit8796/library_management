import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'global_state.dart';
import 'helper_util.dart';
import 'student_details_page.dart';

class StudentsPage extends StatefulWidget {
  final Function onFormSubmitted;

  const StudentsPage({Key? key, required this.onFormSubmitted})
    : super(key: key);

  @override
  _StudentsPageState createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  String searchQuery = '';

  void _navigateToStudentDetailsPage(student) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDetailsPage(student: student),
      ),
    );

    if (result == true) {
      widget.onFormSubmitted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final globalState = Provider.of<GlobalState>(context);
    final List<Map<String, dynamic>> students = globalState.students;

    List<Map<String, dynamic>> filteredStudents =
        students
            .where(
              (student) => student['name']!.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ),
            )
            .toList();

    filteredStudents.sort((a, b) {
      if (a['seatType'] == 'reserved' && b['seatType'] != 'reserved') {
        return -1;
      } else if (a['seatType'] != 'reserved' && b['seatType'] == 'reserved') {
        return 1;
      }
      // If both have the same seatType, compare by endDate in reverse order
      int dateOrder = DateTime.parse(a['endDate']).compareTo(DateTime.parse(b['endDate']));
      return dateOrder;
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage:
                        student['imageUrl'] != null
                            ? NetworkImage(student['imageUrl']!)
                            : null,
                    child:
                        student['imageUrl'] == null
                            ? Icon(Icons.person, size: 24)
                            : null,
                    backgroundColor: Colors.cyan[100],
                  ),
                  title: Text(student['name']!),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seat - ${student['seatType'] == 'reserved' ? 'Reserved (${student['seatNumber']!.toString()})' : 'Unreserved'}',
                      ),
                      Text(
                        '${HelperUtil.formatDate(DateTime.parse(student['startDate']))} till ${HelperUtil.formatDate(DateTime.parse(student['endDate']))}',
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () => _navigateToStudentDetailsPage(student),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
