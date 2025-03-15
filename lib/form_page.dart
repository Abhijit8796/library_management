import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FormPage extends StatefulWidget {
  final String branchName;
  final String branchId;

  const FormPage({Key? key, required this.branchName, required this.branchId})
      : super(key: key);

  @override
  _FormPageState createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  String _seatType = 'reserved';
  DateTime? _startDate;
  DateTime? _endDate;
  File? _image;
  File? _receiptImage;

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

  Future<String> _uploadImage(File image, String path) async {
    print('Inside upload image');
    final storageRef = FirebaseStorage.instance.ref().child(path);
    final uploadTask = storageRef.putFile(image);
    print('Upload task triggered');
    try {
      final snapshot = await uploadTask.whenComplete(() => {});
      if (snapshot.state == TaskState.success) {
        print('Image uploaded');
        return await snapshot.ref.getDownloadURL();
      } else {
        print('Image upload failed with state: ${snapshot.state}');
        throw Exception('Image upload failed');
      }
    } catch (e) {
      print('Error during image upload: $e');
      throw Exception('Image upload failed: $e');
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      print('Inside form submission');
      String? imageUrl;
      String? receiptUrl;

      if (_image != null) {
        imageUrl = await _uploadImage(
            _image!, 'students/${widget.branchId}/image_${DateTime
            .now()
            .millisecondsSinceEpoch}.jpg');
      }

      if (_receiptImage != null) {
        receiptUrl = await _uploadImage(
            _receiptImage!, 'students/${widget.branchId}/receipt_${DateTime
            .now()
            .millisecondsSinceEpoch}.jpg');
        print('Receipt URL : ' + receiptUrl.toString());
      }

      print('About to submit ...');
      await FirebaseFirestore.instance.collection('students').add({
        'branchId': widget.branchId,
        'branchName': widget.branchName,
        'seatType': _seatType,
        'startDate': _startDate,
        'endDate': _endDate,
        'imageUrl': imageUrl,
        'receiptUrl': receiptUrl,
        // Add other form fields here
      });

      // Handle form submission success (e.g., show a success message or navigate back)
      print('Form Submission is successful');
    }
  }

  void _showImageSourceActionSheet(bool isReceipt) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) =>
          SafeArea(
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Student Registration'),
        backgroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Branch - ${widget.branchName}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () => _showImageSourceActionSheet(false),
                child:
                _image == null
                    ? Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[300],
                  child: Icon(Icons.camera_alt, color: Colors.white),
                )
                    : Image.file(
                  _image!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Student Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the student name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _seatType,
                      decoration: InputDecoration(labelText: 'Seat Type'),
                      items:
                      ['Reserved', 'Unreserved']
                          .map(
                            (type) =>
                            DropdownMenuItem(
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
                      child: TextFormField(
                        decoration: InputDecoration(labelText: 'Seat Number'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_seatType == 'reserved' &&
                              (value == null || value.isEmpty)) {
                            return 'Please enter the seat number';
                          }
                          return null;
                        },
                      ),
                    ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
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
                            _startDate = pickedDate;
                          });
                        }
                      },
                      controller: TextEditingController(
                        text:
                        _startDate != null
                            ? _startDate!.toLocal().toString().split(' ')[0]
                            : '',
                      ),
                      validator: (value) {
                        if (_startDate == null) {
                          return 'Please select a start date';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
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
                            _endDate = pickedDate;
                          });
                        }
                      },
                      controller: TextEditingController(
                        text:
                        _endDate != null
                            ? _endDate!.toLocal().toString().split(' ')[0]
                            : '',
                      ),
                      validator: (value) {
                        if (_endDate == null) {
                          return 'Please select an end date';
                        }
                        if (_startDate != null &&
                            _endDate!.isBefore(_startDate!)) {
                          return 'End date cannot be before start date';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              TextFormField(
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
                      _receiptImage == null ? Colors.black54 : Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Register Student',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
