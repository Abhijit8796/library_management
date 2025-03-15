import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentsPage extends StatefulWidget {
  final List<Map<String, dynamic>> students;

  const StudentsPage({Key? key, required this.students}) : super(key: key);

  @override
  _StudentsPageState createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  String searchQuery = '';

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredStudents =
        widget.students
            .where(
              (student) => student['name']!.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ),
            )
            .toList();

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
                        '${formatDate(DateTime.parse(student['startDate']))} till ${formatDate(DateTime.parse(student['endDate']))}',
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    onPressed: () => _makePhoneCall(student['mobile']),
                    icon: const Icon(Icons.call),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
