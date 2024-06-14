import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barcode_scan2/barcode_scan2.dart'; // استيراد حزمة قراءة الباركود
import 'package:flutterfirebase/components/custom_button_auth.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutterfirebase/view/view_cars.dart';

class CarNumberInput extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final int maxLength;
  final TextInputType keyboardType;
  final FocusNode? nextFocusNode;
  final bool autofocus;

  const CarNumberInput({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.maxLength,
    this.nextFocusNode,
    required this.keyboardType,
    this.autofocus = false,
  });

  void _moveToNextField(FocusNode? focusNode, BuildContext context) {
    if (focusNode != null) {
      FocusScope.of(context).requestFocus(focusNode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextFormField(
        autofocus: autofocus,
        controller: controller,
        maxLength: maxLength,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
          labelText: labelText,
          labelStyle: TextStyle(
            color: Colors.blue,
            fontSize: 10,
          ),
        ),
        keyboardType: keyboardType,
        validator: (val) {
          if (val == null || val.trim().isEmpty) {
            return 'الرجاء ادخال $labelText';
          }
          return null;
        },
        onChanged: (value) {
          if (value.length == maxLength && nextFocusNode != null) {
            _moveToNextField(nextFocusNode, context);
          }
        },
        onEditingComplete: () {
          if (nextFocusNode != null) {
            _moveToNextField(nextFocusNode, context);
          }
        },
        textInputAction:
            nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
      ),
    );
  }
}

class AddCar extends StatefulWidget {
  const AddCar({
    Key? key,
    required this.stationId,
    required this.lineId,
  });

  final String stationId;
  final String lineId;

  @override
  State<AddCar> createState() => _AddCarState();
}

class _AddCarState extends State<AddCar> {
  late TextEditingController firstController;
  late TextEditingController secondController;
  late TextEditingController thirdController;
  late TextEditingController digitController;

  late FocusNode firstFocusNode;
  late FocusNode secondFocusNode;
  late FocusNode thirdFocusNode;
  late FocusNode digitFocusNode;

  GlobalKey<FormState> formState = GlobalKey();
  bool isLoading = false;
  bool isFieldsFilled = false;

  @override
  void initState() {
    super.initState();

    firstController = TextEditingController();
    secondController = TextEditingController();
    thirdController = TextEditingController();
    digitController = TextEditingController();

    firstFocusNode = FocusNode();
    secondFocusNode = FocusNode();
    thirdFocusNode = FocusNode();
    digitFocusNode = FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted && !firstFocusNode.hasFocus) {
      FocusScope.of(context).requestFocus(firstFocusNode);
    }
  }

  @override
  void dispose() {
    firstController.dispose();
    secondController.dispose();
    thirdController.dispose();
    digitController.dispose();
    firstFocusNode.dispose();
    secondFocusNode.dispose();
    thirdFocusNode.dispose();
    digitFocusNode.dispose();
    super.dispose();
  }

  void _checkFieldsFilled() {
  setState(() {
    // التحقق من أن الحقول الأخرى غير فارغة
    bool areOtherFieldsFilled = secondController.text.isNotEmpty && thirdController.text.isNotEmpty;
    
    // التحقق من أن حقل digitController يحتوي على الأقل على رقمين
    bool isDigitFieldValid = digitController.text.length >= 2;

    // تحديث الحالة بناءً على الشروط أعلاه
    isFieldsFilled = areOtherFieldsFilled && isDigitFieldValid;
  });
}

  Future<void> addCar() async {
    setState(() {
      isLoading = true;
    });

    if (secondController.text.isEmpty ||
        thirdController.text.isEmpty ||
        digitController.text.isEmpty) {
      await showErrorDialog('الرجاء ملء جميع الحقول');
      setState(() {
        isLoading = false;
      });
      return;
    }

    CollectionReference carsCollection = FirebaseFirestore.instance
        .collection('المواقف')
        .doc(widget.stationId)
        .collection('line')
        .doc(widget.lineId)
        .collection('car');

    CollectionReference allCarsCollection =
        FirebaseFirestore.instance.collection('AllCars');

    if (formState.currentState!.validate()) {
      try {
        String carNumber =
            '${firstController.text.trim()}${secondController.text.trim()}${thirdController.text.trim()}${digitController.text.trim()}';

        QuerySnapshot stationsSnapshot =
            await FirebaseFirestore.instance.collection('المواقف').get();

        for (QueryDocumentSnapshot stationDoc in stationsSnapshot.docs) {
          String stationId = stationDoc.id;

          QuerySnapshot linesSnapshot = await FirebaseFirestore.instance
              .collection('المواقف')
              .doc(stationId)
              .collection('line')
              .get();

          for (QueryDocumentSnapshot lineDoc in linesSnapshot.docs) {
            String lineId = lineDoc.id;
            QuerySnapshot carsSnapshot = await FirebaseFirestore.instance
                .collection('المواقف')
                .doc(stationId)
                .collection('line')
                .doc(lineId)
                .collection('car')
                .where('numberOfCar', isEqualTo: carNumber)
                .get();

            if (carsSnapshot.docs.isNotEmpty) {
              if (stationId == widget.stationId && lineId == widget.lineId) {
                await showErrorDialog('السيارة موجودة بالفعل');
                return;
              } else if (stationId == widget.stationId &&
                  lineId != widget.lineId) {
                await showErrorDialog(
                    'السيارة موجودة في نفس الموقف ولكن في خط آخر');
                return;
              } else {
                await showErrorDialog('السيارة موجودة في موقف آخر');
                return;
              }
            }
          }
        }

        await carsCollection.add({
          'numberOfCar': carNumber,
          'timestamp': FieldValue.serverTimestamp(),
        });

        final querySnapshot = await FirebaseFirestore.instance
            .collection("AllCars")
            .where('numberOfCar', isEqualTo: carNumber)
            .where('stationId',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
        } else {
          await allCarsCollection.add({
            'numberOfCar': carNumber,
            'timestamp': FieldValue.serverTimestamp(),
            'stationId': FirebaseAuth.instance.currentUser!.uid,
          });
        }
        await showSuccessDialog('تمت اضافة السيارة بنجاح');
      } catch (e) {
        await showErrorDialog('حدثت مشكلة اثناء اضافة السيارة');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> showErrorDialog(String message) async {
    await AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.rightSlide,
      desc: message,
      btnCancelOnPress: () {},
    ).show();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ViewCars(
            lineId: widget.lineId,
            stationId: widget.stationId,
          );
        },
      ),
    );
  }

  Future<void> showSuccessDialog(String message) async {
    await AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.rightSlide,
      desc: message,
      btnOkOnPress: () {},
    ).show();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ViewCars(
            lineId: widget.lineId,
            stationId: widget.stationId,
          );
        },
      ),
    );
  }

  Widget _buildTextField(String labelText, TextEditingController controller,
      FocusNode focusNode, int maxLength, TextInputType keyboardType,
      {FocusNode? nextFocusNode}) {
    return Expanded(
      child: TextFormField(
        controller: controller,
        textAlign: TextAlign.center,
        focusNode: focusNode,
        onChanged: (value) {
          if (value.length == maxLength && nextFocusNode != null) {
            _moveToNextField(nextFocusNode);
          }
          _checkFieldsFilled();
        },
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.blue, fontSize: 10),
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
        keyboardType: keyboardType,
        maxLength: maxLength,
        onEditingComplete: () {
          if (nextFocusNode != null) {
            _moveToNextField(nextFocusNode);
          }
        },
        textInputAction:
            nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
      ),
    );
  }

  void _moveToNextField(FocusNode? focusNode) {
    if (focusNode != null) {
      FocusScope.of(context).requestFocus(focusNode);
    }
  }

  Future<void> _scanBarcode() async {
    setState(() {
      isLoading = true;
    });
    try {
      var result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode) {
        String barcode = result.rawContent;

        RegExp regex = RegExp(r'^[\u0600-\u06FF]{2,3}\d{2,4}$');
        if (!regex.hasMatch(barcode)) {
          await showErrorDialog('الباركود غير صالح');
          return;
        }

        if (barcode.substring(0, 1).isEmpty) {
          firstController.text = '';
          secondController.text = barcode.substring(1, 2);
          thirdController.text = barcode.substring(2, 3);
          digitController.text = barcode.substring(3);
        } else {
          firstController.text = barcode.substring(0, 1);
          secondController.text = barcode.substring(1, 2);
          thirdController.text = barcode.substring(2, 3);
          digitController.text = barcode.substring(3);
        }

        _checkFieldsFilled();
        await addCar();
      }
    } catch (e) {
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("اضافة سيارة"),
      ),
      body: Form(
        key: formState,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.blue,
                ),
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        _buildTextField(
                          'الحرف الاول',
                          firstController,
                          firstFocusNode,
                          1,
                          TextInputType.text,
                          nextFocusNode: secondFocusNode,
                        ),
                        _buildTextField(
                          "الحرف الثاني",
                          secondController,
                          secondFocusNode,
                          1,
                          TextInputType.text,
                          nextFocusNode: thirdFocusNode,
                        ),
                        _buildTextField(
                          "الحرف الثالث",
                          thirdController,
                          thirdFocusNode,
                          1,
                          TextInputType.text,
                          nextFocusNode: digitFocusNode,
                        ),
                        const SizedBox(width: 8),
                        _buildTextField(
                          "الارقام",
                          digitController,
                          digitFocusNode,
                          4,
                          TextInputType.number,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  if (isFieldsFilled)
                    CustomButtonAuth(
                      child: "اضافة السيارة ",
                      onPressed: addCar,
                    ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        onPressed: _scanBarcode,
        label: Text('الاضافة بالباركود'),
        icon: Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
