import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentDetailsPage extends StatelessWidget {
  final Map<String, dynamic> student;

  const StudentDetailsPage({Key? key, required this.student}) : super(key: key);

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Student Details'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    student['imageUrl'] != null
                        ? NetworkImage(student['imageUrl']!)
                        : null,
                child:
                    student['imageUrl'] == null
                        ? Icon(Icons.person, size: 50)
                        : null,
                backgroundColor: Colors.cyan[100],
              ),
            ),
            SizedBox(height: 16),
            Text(
              student['name']!,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Card(
              child: Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text('Start Date', style: TextStyle(fontSize: 12)),
                      subtitle: Text(
                        student['startDate']!,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text('End Date', style: TextStyle(fontSize: 12)),
                      subtitle: Text(
                        student['endDate']!,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Card(
              child: ListTile(
                title: Text('Mobile Number', style: TextStyle(fontSize: 12)),
                subtitle: Text(
                  '${student['mobile']}',
                  style: TextStyle(fontSize: 18),
                ),
                leading: IconButton(
                  icon: Icon(Icons.call_rounded, size: 36),
                  onPressed: () => _makePhoneCall(student['mobile']),
                ),
              ),
            ),
            Card(
              child: Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(
                        'Payment Amount',
                        style: TextStyle(fontSize: 12),
                      ),
                      subtitle: Text(
                        student['paymentAmount']!.toString(),
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text('Seat Type', style: TextStyle(fontSize: 12)),
                      subtitle: Text(
                        student['seatType'] == 'reserved'
                            ? 'Reserved (${student['seatNumber']})'
                            : 'Unreserved',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Text('Open renew membership form'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                backgroundColor: Colors.lightBlueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Renew Membership',
                style: TextStyle(color: Colors.black, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
