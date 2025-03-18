import 'dart:io';

import 'package:dnyanjyoti_abhyasika_app/helper_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'global_state.dart';

class FormPage extends StatefulWidget {
  final Map<String, dynamic>? initialValues;

  const FormPage({super.key, this.initialValues});

  @override
  _FormPageState createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _seatNumberController;
  late TextEditingController _paymentAmountController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  String _seatType = 'reserved';
  File? _image;
  File? _receiptImage;
  String? _imageUrl;
  int? _selectedSeatNumber;
  List<int> availableSeatNumbers = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialValues?['name'],
    );
    _mobileController = TextEditingController(
      text: widget.initialValues?['mobile'],
    );
    _seatNumberController = TextEditingController(
      text: widget.initialValues?['seatNumber']?.toString(),
    );
    _paymentAmountController = TextEditingController(
      text: widget.initialValues?['paymentAmount']?.toString(),
    );
    _startDateController = TextEditingController(
      text: widget.initialValues?['startDate'],
    );
    _endDateController = TextEditingController(
      text: widget.initialValues?['endDate'],
    );
    _seatType = widget.initialValues?['seatType'] ?? 'reserved';
    _imageUrl = widget.initialValues?['imageUrl'];
    _selectedSeatNumber = widget.initialValues?['seatNumber'];

    _startDateController.addListener(_recalculateAvailableSeats);
    _endDateController.addListener(_recalculateAvailableSeats);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recalculateAvailableSeats();
  }

  List<int> getAvailableSeatNumbers(
    List<Map<String, dynamic>> students,
    int totalReservedSeats,
    String? startDate,
    String? endDate,
  ) {
    if (_selectedSeatNumber != null && _selectedSeatNumber != '') {
      return [_selectedSeatNumber!];
    }

    if (startDate == null ||
        startDate == '' ||
        endDate == null ||
        endDate == '') {
      return [];
    }

    print('Current start-date: $startDate & end-date: $endDate');
    DateTime start = DateTime.parse(startDate);
    DateTime end = DateTime.parse(endDate);
    Set<int> occupiedSeats = {};

    for (var student in students) {
      DateTime studentStart = DateTime.parse(student['startDate']);
      DateTime studentEnd = DateTime.parse(student['endDate']);
      if (student['seatType'] == 'reserved' &&
          studentEnd.isAfter(start) &&
          studentStart.isBefore(end)) {
        occupiedSeats.add(student['seatNumber']);
      }
    }

    List<int> availableSeats = [];
    for (int i = 1; i <= totalReservedSeats; i++) {
      if (!occupiedSeats.contains(i)) {
        availableSeats.add(i);
      }
    }

    return availableSeats;
  }

  void _recalculateAvailableSeats() {
    final globalState = Provider.of<GlobalState>(context, listen: false);
    setState(() {
      print('I am here 1');
      availableSeatNumbers = getAvailableSeatNumbers(
        globalState.students,
        globalState.branchDetails!['reservedSeats'],
        _startDateController.text,
        _endDateController.text,
      );
    });
  }

  Future<void> _pickImage(ImageSource source, bool isReceipt) async {
    final ImagePicker _picker = ImagePicker();
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        if (isReceipt) {
          _receiptImage = File(pickedFile.path);
        } else {
          _image = File(pickedFile.path);
        }
      });
    }
  }

  Future<String> _uploadImage(File image, String bucket, String path) async {
    await Supabase.instance.client.storage.from(bucket).upload(path, image);

    final signedUrlResponse = await Supabase.instance.client.storage
        .from(bucket)
        .createSignedUrl(path, 60 * 60 * 24 * 365 * 50);

    return signedUrlResponse;
  }

  bool isUnreservedOverbooked(
    Map<String, dynamic>? branchDetails,
    List<Map<String, dynamic>> students,
    String startDate,
    String endDate,
  ) {
    List<Map<String, dynamic>> unreservedStudents =
        students
            .where(
              (student) =>
                  student['seatType'] == 'unreserved' &&
                  (DateTime.parse(
                        startDate,
                      ).isBefore(DateTime.parse(student['endDate'])) &&
                      DateTime.parse(
                        endDate,
                      ).isAfter(DateTime.parse(student['startDate']))),
            )
            .toList();

    return (unreservedStudents.length / branchDetails!['unreservedSeats']) >=
        (1 + (int.tryParse(dotenv.env['UNRESERVED_EXTRA_CAPACITY']!)! / 100));
  }

  Map<String, dynamic>? isReservedSeatBooked(
    Map<String, dynamic>? branchDetails,
    List<Map<String, dynamic>> students,
    String startDate,
    String endDate,
    int seatNumber,
  ) {
    List<Map<String, dynamic>> reservedStudents =
        students
            .where(
              (student) =>
                  student['seatType'] == 'reserved' &&
                  student['seatNumber'] == seatNumber &&
                  (DateTime.parse(
                        startDate,
                      ).isBefore(DateTime.parse(student['endDate'])) &&
                      DateTime.parse(
                        endDate,
                      ).isAfter(DateTime.parse(student['startDate']))),
            )
            .toList();

    if (reservedStudents.isEmpty) {
      return null;
    }
    return reservedStudents[0];
  }

  Future<void> _submitForm(
    Map<String, dynamic>? branchDetails,
    List<Map<String, dynamic>> students,
  ) async {
    if (_formKey.currentState!.validate()) {
      String? imageUrl;
      String? receiptUrl;

      if (_seatType == 'reserved') {
        Map<String, dynamic>? reservationDetails = isReservedSeatBooked(
          branchDetails,
          students,
          _startDateController.text,
          _endDateController.text,
          int.tryParse(_seatNumberController.text)!,
        );
        print(reservationDetails);
        if (reservationDetails != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Seat is already reserved for \n${reservationDetails['name']} '
                '(${HelperUtil.formatDate(DateTime.parse(reservationDetails['startDate']))} to '
                '${HelperUtil.formatDate(DateTime.parse(reservationDetails['endDate']))})',
              ),
            ),
          );
          return;
        }
      } else if (_seatType == 'unreserved' &&
          isUnreservedOverbooked(
            branchDetails,
            students,
            _startDateController.text,
            _endDateController.text,
          )) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unreserved seats are overbooked, cant book more!'),
          ),
        );
        return;
      }

      if (_image != null) {
        imageUrl = await _uploadImage(
          _image!,
          'student-images',
          '${branchDetails!['id']}_${_nameController.text.replaceAll(' ', '').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      if (_receiptImage != null) {
        receiptUrl = await _uploadImage(
          _receiptImage!,
          'receipt-images',
          '${branchDetails!['id']}_${_nameController.text.replaceAll(' ', '').toLowerCase()}_receipt_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      var record = {
        'branchId': branchDetails!['id'],
        'name': _nameController.text,
        'mobile': _mobileController.text,
        'startDate': _startDateController.text,
        'endDate': _endDateController.text,
        'seatType': _seatType,
        'seatNumber': int.tryParse(_seatNumberController.text),
        'paymentAmount': double.tryParse(_paymentAmountController.text),
        'imageUrl': imageUrl,
        'receiptUrl': receiptUrl,
      };

      await Supabase.instance.client.from('students').insert(record);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Registration successful!')));
      Navigator.pop(context, true);
    }
  }

  void _showImageSourceActionSheet(bool isReceipt) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Camera'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera, isReceipt);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery, isReceipt);
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final globalState = Provider.of<GlobalState>(context);
    final Map<String, dynamic>? branchDetails = globalState.branchDetails;
    final List<Map<String, dynamic>> students = globalState.students;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Student Registration'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    'Branch - ${branchDetails!['name']}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _showImageSourceActionSheet(false),
                    child:
                        _imageUrl != null
                            ? Image.network(
                              _imageUrl!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            )
                            : _image == null
                            ? Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                            )
                            : Image.file(
                              _image!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                  ),
                  SizedBox(height: 5),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Student Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the student name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 5),
                  TextFormField(
                    controller: _mobileController,
                    decoration: InputDecoration(labelText: 'Student Mobile'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the student mobile number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _startDateController,
                          decoration: InputDecoration(labelText: 'Start Date'),
                          readOnly: true,
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _startDateController.text =
                                    pickedDate.toLocal().toString().split(
                                      ' ',
                                    )[0];
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a start date';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        child: TextFormField(
                          controller: _endDateController,
                          decoration: InputDecoration(labelText: 'End Date'),
                          readOnly: true,
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _endDateController.text =
                                    pickedDate.toLocal().toString().split(
                                      ' ',
                                    )[0];
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select an end date';
                            }
                            if (_startDateController.text.isNotEmpty &&
                                DateTime.parse(value).isBefore(
                                  DateTime.parse(_startDateController.text),
                                )) {
                              return 'End date cannot be before start date';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _seatType,
                          decoration: InputDecoration(labelText: 'Seat Type'),
                          items:
                              ['Reserved', 'Unreserved']
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type.toLowerCase(),
                                      child: Text(type),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              _seatType = value!;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      if (_seatType == 'reserved')
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: 'Seat Number',
                            ),
                            value: _selectedSeatNumber,
                            menuMaxHeight: 250.0,
                            items:
                                availableSeatNumbers
                                    .map(
                                      (seatNumber) => DropdownMenuItem(
                                        value: seatNumber,
                                        child: Text(seatNumber.toString()),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSeatNumber = value;
                              });
                            },
                            validator: (value) {
                              if (_seatType == 'reserved' && value == null) {
                                return 'Please select a seat number';
                              }
                              return null;
                            },
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 5),
                  TextFormField(
                    controller: _paymentAmountController,
                    decoration: InputDecoration(labelText: 'Payment Amount'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the payment amount';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _showImageSourceActionSheet(true),
                        child: Text('Attach Receipt'),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[350],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      Text(
                        _receiptImage == null
                            ? 'No Receipt Attached'
                            : 'Receipt Attached',
                        style: TextStyle(
                          color:
                              _receiptImage == null
                                  ? Colors.black54
                                  : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => _submitForm(branchDetails, students),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      backgroundColor: Colors.lightBlueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Register Student',
                      style: TextStyle(color: Colors.black, fontSize: 20),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
