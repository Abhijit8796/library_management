import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FormPage extends StatefulWidget {
  final String branchName;
  final int branchId;

  const FormPage({Key? key, required this.branchName, required this.branchId})
    : super(key: key);

  @override
  _FormPageState createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _mobile;
  String _seatType = 'reserved';
  int? _seatNumber;
  double? _paymentAmount;
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

  Future<String> _uploadImage(File image, String bucket, String path) async {
    await Supabase.instance.client.storage.from(bucket).upload(path, image);

    final signedUrlResponse = await Supabase.instance.client.storage
        .from(bucket)
        .createSignedUrl(path, 60 * 60 * 24 * 365 * 50);

    return signedUrlResponse;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      String? imageUrl;
      String? receiptUrl;

      if (_image != null) {
        imageUrl = await _uploadImage(
          _image!,
          'student-images',
          '${widget.branchId}_${_name?.replaceAll(' ', '').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      if (_receiptImage != null) {
        receiptUrl = await _uploadImage(
          _receiptImage!,
          'receipt-images',
          '${widget.branchId}_${_name?.replaceAll(' ', '').toLowerCase()}_receipt_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      var record = {
        'branchId': widget.branchId,
        'name': _name,
        'mobile': _mobile,
        'startDate': _startDate?.toIso8601String(),
        'endDate': _endDate?.toIso8601String(),
        'seatType': _seatType,
        'seatNumber': _seatNumber,
        'paymentAmount': _paymentAmount,
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
                onChanged: (value) {
                  setState(() {
                    _name = value!;
                  });
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Student Mobile'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the student mobile number';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _mobile = value!;
                  });
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
                        onChanged: (value) {
                          setState(() {
                            _seatNumber = int.tryParse(value);
                          });
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
                onChanged: (value) {
                  setState(() {
                    _paymentAmount = double.tryParse(value);
                  });
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
