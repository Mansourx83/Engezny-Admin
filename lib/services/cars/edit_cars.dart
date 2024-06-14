import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutterfirebase/components/custom_button_auth.dart';
import 'package:flutterfirebase/services/cars/add_cars.dart';
import 'package:flutterfirebase/view/view_cars.dart';

class EditCar extends StatefulWidget {
  const EditCar({
    Key? key,
    required this.carDocId,
    required this.lineId,
    required this.oldNumberOfCar,
    required this.stationId,
  }) : super(key: key);

  final String carDocId;
  final String stationId;
  final String lineId;
  final String oldNumberOfCar;

  @override
  State<EditCar> createState() => _EditCarState();
}

class _EditCarState extends State<EditCar> {
  TextEditingController firstController = TextEditingController();
  TextEditingController secondController = TextEditingController();
  TextEditingController thirdController = TextEditingController();
  TextEditingController digitController = TextEditingController();

  late FocusNode secondFocusNode;
  late FocusNode thirdFocusNode;
  late FocusNode digitFocusNode;

  GlobalKey<FormState> formstate = GlobalKey();

  bool isLoading = false;

  void editCar() async {
    CollectionReference line = FirebaseFirestore.instance
        .collection('المواقف')
        .doc(widget.stationId)
        .collection("line")
        .doc(widget.lineId)
        .collection("car");

    CollectionReference allCarsCollection =
        FirebaseFirestore.instance.collection('AllCars');

    if (formstate.currentState!.validate()) {
      try {
        setState(() {
          isLoading = true;
        });

        // Get the old car data before updating
        DocumentSnapshot oldCarData = await line.doc(widget.carDocId).get();

        // Update in the first collection (line)
        await line.doc(widget.carDocId).update({
          'numberOfCar':
              '${firstController.text.trim()}${secondController.text.trim()}${thirdController.text.trim()}${digitController.text.trim()}',
        });

        // Update in the second collection (AllCars)
        QuerySnapshot existingAllCars = await allCarsCollection
            .where('numberOfCar', isEqualTo: widget.oldNumberOfCar)
            .get();

        if (existingAllCars.docs.isNotEmpty) {
          await existingAllCars.docs.first.reference.update({
            'numberOfCar':
                '${firstController.text.trim()}${secondController.text.trim()}${thirdController.text.trim()}${digitController.text.trim()}',
          });
        }


        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (context) {
          return ViewCars(lineId: widget.lineId, stationId: widget.stationId);
        }));
      } catch (e) {
        setState(() {
          isLoading = false;
        });

        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          desc: 'حدثت خطأ أثناء التعديل',
        ).show();
      }
    }
  }

  @override
  void dispose() {
    firstController.dispose();
    secondController.dispose();
    thirdController.dispose();
    digitController.dispose();
    secondFocusNode.dispose();
    thirdFocusNode.dispose();
    digitFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Split the old number into individual fields
    firstController.text = widget.oldNumberOfCar.substring(0, 1);
    secondController.text = widget.oldNumberOfCar.substring(1, 2);
    thirdController.text = widget.oldNumberOfCar.substring(2, 3);
    digitController.text = widget.oldNumberOfCar.substring(3);

    secondFocusNode = FocusNode();
    thirdFocusNode = FocusNode();
    digitFocusNode = FocusNode();

    secondFocusNode.addListener(() {
      if (!secondFocusNode.hasFocus && mounted) {
        FocusScope.of(context).requestFocus(thirdFocusNode);
      }
    });

    thirdFocusNode.addListener(() {
      if (!thirdFocusNode.hasFocus && mounted) {
        FocusScope.of(context).requestFocus(digitFocusNode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text("تعديل على رقم السيارة"),
        ),
        body: Form(
          key: formstate,
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
                          CarNumberInput(
                            controller: firstController,
                            labelText: 'الحرف الأول',
                            maxLength: 1,
                            nextFocusNode: secondFocusNode,
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(width: 8),
                          CarNumberInput(
                            controller: secondController,
                            labelText: 'الحرف الثاني',
                            maxLength: 1,
                            nextFocusNode: thirdFocusNode,
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(width: 8),
                          CarNumberInput(
                            controller: thirdController,
                            labelText: 'الحرف الثالث',
                            maxLength: 1,
                            nextFocusNode: digitFocusNode,
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(width: 8),
                          CarNumberInput(
                            keyboardType: TextInputType.number,
                            controller: digitController,
                            labelText: 'الأرقام',
                            maxLength: 4,
                            nextFocusNode: null,
                          ),
                        ],
                      ),
                    ),
                    CustomButtonAuth(
                      child: "تعديل",
                      onPressed: editCar,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}


