import 'package:flutter/material.dart';

class SeatsPage extends StatelessWidget {
  final List<List<String>> seatLayout;
  final int totalReservedSeats;
  final int totalUnreservedSeats;
  final List<Map<String, dynamic>> students;

  const SeatsPage({
    Key? key,
    required this.seatLayout,
    required this.totalReservedSeats,
    required this.totalUnreservedSeats,
    required this.students,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Set<String> occupiedSeats = Set();
    int occupiedReservedSeats = 0;
    int occupiedUnreservedSeats = 0;

    for (var student in students) {
      if (student['seatType'] == 'reserved') {
        occupiedSeats.add(student['seatNumber']!.toString());
        occupiedReservedSeats++;
      } else {
        occupiedUnreservedSeats++;
      }
    }

    double maxWidthForSeatLayout = MediaQuery.of(context).size.width * 0.9;
    double maxHeightForSeatLayout = 420;
    int maxSeatsInRow = seatLayout
        .map((row) => row.length)
        .reduce((a, b) => a > b ? a : b);
    double seatWidth =
        maxWidthForSeatLayout / maxSeatsInRow - 4; // Subtracting margin
    double seatHeight =
        maxHeightForSeatLayout / seatLayout.length - 4; // Subtracting margin

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
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
                          return Container(
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
                          );
                        } else {
                          return Container(
                            margin: const EdgeInsets.all(2),
                            width: seatWidth,
                            height: seatHeight * 0.5,
                          ); // Empty space
                        }
                      }),
                    );
                  },
                ),
              ),
            ),
          ),
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
                                  '${occupiedReservedSeats} / ${totalReservedSeats}',
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
                                  '${occupiedUnreservedSeats} / ${totalUnreservedSeats}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    color:
                                        occupiedUnreservedSeats ==
                                                totalUnreservedSeats
                                            ? Colors.orange
                                            : occupiedUnreservedSeats /
                                                    totalUnreservedSeats >
                                                1.25
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
