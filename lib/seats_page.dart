import 'package:dnyanjyoti_abhyasika_app/form_page.dart';
import 'package:dnyanjyoti_abhyasika_app/student_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'global_state.dart';
import 'helper_util.dart';

class SeatsPage extends StatefulWidget {
  final Function onFormSubmitted;

  const SeatsPage({Key? key, required this.onFormSubmitted}) : super(key: key);

  @override
  _SeatsPageState createState() => _SeatsPageState();
}

class _SeatsPageState extends State<SeatsPage> {
  void _navigateToFormPage(seatNumber) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FormPage(initialValues: {'seatNumber': seatNumber}),
      ),
    );

    if (result == true) {
      widget.onFormSubmitted();
    }
  }

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

  Map<String, dynamic>? getStudentForSeat(students, seatNumber) {
    List<Map<String, dynamic>> studentsForSeat =
        students
            .where((student) => student['seatNumber'] == seatNumber)
            .toList();
    for (var student in studentsForSeat) {
      if (HelperUtil.isTodayWithinDateRange(
        student['startDate'],
        student['endDate'],
      )) {
        return student;
      }
    }
    return null;
  }

  DateTime? getMaxEndDateForSeat(
    List<Map<String, dynamic>> students,
    int? seatNumber,
  ) {
    if (seatNumber == null) return null;
    List<Map<String, dynamic>> studentsForSeat =
        students
            .where((student) => student['seatNumber'] == seatNumber)
            .toList();
    if (studentsForSeat.isEmpty) return null;
    return studentsForSeat
        .map((student) => DateTime.parse(student['endDate']))
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  bool isEndDateWithinNextFiveDays(DateTime? endDate) {
    if (endDate == null) return false;
    final now = DateTime.now();
    final difference = endDate.difference(now).inDays;
    return difference <= 5 && difference >= 0;
  }

  @override
  Widget build(BuildContext context) {
    final globalState = Provider.of<GlobalState>(context);

    final branchDetails = globalState.branchDetails;

    if (branchDetails == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<List<String>> seatLayout = branchDetails['seatLayout'];
    final int totalReservedSeats = branchDetails['reservedSeats'];
    final int totalUnreservedSeats = branchDetails['unreservedSeats'];
    final List<Map<String, dynamic>> students = globalState.students;

    Set<String> occupiedSeats = {};
    int occupiedReservedSeats = 0;
    int occupiedUnreservedSeats = 0;

    for (var student in students) {
      if (HelperUtil.isTodayWithinDateRange(
        student['startDate'],
        student['endDate'],
      )) {
        if (student['seatType'] == 'reserved') {
          occupiedSeats.add(student['seatNumber']!.toString());
          occupiedReservedSeats++;
        } else {
          occupiedUnreservedSeats++;
        }
      }
    }

    double maxWidthForSeatLayout = MediaQuery.of(context).size.width * 0.9;
    double maxHeightForSeatLayout = 370;
    int maxSeatsInRow = seatLayout
        .map((row) => row.length)
        .reduce((a, b) => a > b ? a : b);
    double seatWidth =
        (maxWidthForSeatLayout / maxSeatsInRow) - 4; // Subtracting margin
    double seatHeight =
        (maxHeightForSeatLayout / seatLayout.length) - 4; // Subtracting margin

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: seatLayout.length,
                itemBuilder: (context, rowIndex) {
                  List<String> seats = seatLayout[rowIndex];

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(seats.length, (seatIndex) {
                      String seat = seats[seatIndex];
                      if (seat != '') {
                        String occupancyStatus =
                            occupiedSeats.contains(seat) ? 'X' : '_';
                        Color seatColor;
                        String seatLabel = '';
                        if (occupancyStatus == 'X') {
                          seatColor = Colors.red;
                          seatLabel = seat;
                        } else {
                          seatColor = Colors.blue;
                          seatLabel = seat;
                        }

                        var maxEndDate = getMaxEndDateForSeat(
                          students,
                          int.tryParse(seatLabel),
                        );
                        if (isEndDateWithinNextFiveDays(maxEndDate)) {
                          seatColor = Colors.orange;
                        }

                        return GestureDetector(
                          onTap:
                              seatColor == Colors.blue
                                  ? () => _navigateToFormPage(
                                    int.tryParse(seatLabel),
                                  )
                                  : () => _navigateToStudentDetailsPage(
                                    getStudentForSeat(
                                      students,
                                      int.tryParse(seatLabel),
                                    ),
                                  ),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            width: seatWidth,
                            height: seatHeight,
                            decoration: BoxDecoration(
                              color: seatColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Center(
                              child: Text(
                                seatLabel,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Container(
                          margin: const EdgeInsets.all(2),
                          width: seatWidth,
                          height: seatHeight,
                        ); // Empty space
                      }
                    }),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Current Occupancy',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 60),
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Table(
                  columnWidths: {1: IntrinsicColumnWidth()},
                  children: [
                    TableRow(
                      children: [
                        TableCell(
                          child: Container(
                            width: double.infinity,
                            child: Text(
                              'Reserved Seats',
                              style: TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                        TableCell(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$occupiedReservedSeats / $totalReservedSeats',
                                  style: TextStyle(
                                    fontSize: 22,
                                    color:
                                        occupiedReservedSeats ==
                                                totalReservedSeats
                                            ? Colors.red
                                            : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        SizedBox(height: 20), // Add spacing between rows
                        SizedBox(height: 20),
                      ],
                    ),
                    TableRow(
                      children: [
                        TableCell(
                          child: Container(
                            width: double.infinity,
                            child: Text(
                              'Unreserved Seats',
                              style: TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                        TableCell(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$occupiedUnreservedSeats / $totalUnreservedSeats',
                                  style: TextStyle(
                                    fontSize: 22,
                                    color:
                                        occupiedUnreservedSeats ==
                                                totalUnreservedSeats
                                            ? Colors.orange
                                            : (occupiedUnreservedSeats /
                                                    totalUnreservedSeats) >=
                                                (1 +
                                                    (int.tryParse(
                                                          dotenv
                                                              .env['UNRESERVED_EXTRA_CAPACITY']!,
                                                        )! /
                                                        100))
                                            ? Colors.red
                                            : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
