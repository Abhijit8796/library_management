import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'form_page.dart';
import 'seats_page.dart';
import 'students_page.dart';
import 'supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dnyanjyoti Abhyasika',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white70),
      ),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final supbaseService = SupabaseService();
  int _selectedIndex = 0;
  List<String> _allowedBranches = [];
  String? _selectedBranch;
  Map<String, Map<String, dynamic>> _branchDetailsMap = {};
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _authenticateAndLoadBranches();
  }

  Future<void> _authenticateAndLoadBranches() async {
    await _loadBranches();
    await _loadStudents();
  }

  Future<void> _loadBranches() async {
    final branchDetailsMap = await supbaseService.getAllBranchDetails();

    setState(() {
      _allowedBranches = branchDetailsMap.keys.toList();
      _branchDetailsMap = branchDetailsMap;
      if (_allowedBranches.isNotEmpty) {
        _selectedBranch = _allowedBranches[0];
      }
    });
  }

  Future<void> _loadStudents() async {
    if (_selectedBranch != null) {
      final students = await supbaseService.getStudentsByBranchId(
        _branchDetailsMap[_selectedBranch]!['id'],
      );

      setState(() {
        _students = students;
      });
    } else {
      setState(() {
        _students = [];
      });
    }
  }

  void _navigateToFormPage(branchDetails, students) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                FormPage(branchDetails: branchDetails, students: students),
      ),
    );

    if (result == true) {
      _loadStudents();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onLogout() {
    // Handle logout logic here
  }

  @override
  Widget build(BuildContext context) {
    final branchDetails =
        _selectedBranch != null ? _branchDetailsMap[_selectedBranch] : null;

    final List<Widget> _widgetOptions = <Widget>[
      branchDetails == null
          ? CircularProgressIndicator()
          : SeatsPage(
            seatLayout: branchDetails['seatLayout'],
            totalReservedSeats: branchDetails['reservedSeats'],
            totalUnreservedSeats: branchDetails['unreservedSeats'],
            students: _students,
          ),
      branchDetails == null
          ? CircularProgressIndicator()
          : StudentsPage(students: _students),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 240,
              child: DropdownButton<String>(
                value: _selectedBranch,
                items:
                    _allowedBranches.map<DropdownMenuItem<String>>((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: TextStyle(fontSize: 24)),
                      );
                    }).toList(),
                onChanged: (String? newValue) async {
                  setState(() {
                    _selectedBranch = newValue!;
                  });
                  await _loadStudents();
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _onLogout,
              color: Colors.black,
            ),
          ],
        ),
      ),
      body: Center(
        child:
            branchDetails == null
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading branch details from database'),
                  ],
                )
                : _widgetOptions.elementAt(_selectedIndex),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            branchDetails == null
                ? null
                : () => _navigateToFormPage(branchDetails, _students),
        shape: CircleBorder(),
        backgroundColor: Colors.lightBlueAccent,
        child: Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 5,
              blurRadius: 10,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.event_seat, size: 28),
              label: 'Seats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 28),
              label: 'Students',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.indigo,
          backgroundColor: Colors.white,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
