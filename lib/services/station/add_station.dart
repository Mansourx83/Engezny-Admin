// ignore_for_file: use_build_context_synchronously

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterfirebase/components/custom_button_auth.dart';
import 'package:flutterfirebase/components/text_form.dart';
import 'package:flutterfirebase/view/veiw_statioon.dart';
import 'package:geolocator/geolocator.dart';

class AddStation extends StatefulWidget {
  const AddStation({Key? key}) : super(key: key);

  @override
  State<AddStation> createState() => _AddStationState();
}

class _AddStationState extends State<AddStation> {
  TextEditingController addNameController = TextEditingController();
  GlobalKey<FormState> formstate = GlobalKey();
  CollectionReference stations =
      FirebaseFirestore.instance.collection('المواقف');
  bool isLoading = false;

  Future<void> addStationName() async {
    if (formstate.currentState!.validate()) {
      try {
        setState(() {
          isLoading = true;
        });

        QuerySnapshot existingLines = await stations
            .where('name', isEqualTo: addNameController.text)
            .get();

        if (existingLines.docs.isNotEmpty) {
          AwesomeDialog(
                  context: context,
                  dialogType: DialogType.error,
                  animType: AnimType.rightSlide,
                  desc: 'الموقف موجود بالفعل!',
                  btnCancelOnPress: () {})
              .show()
              .then((value) => Navigator.of(context)
                  .pushNamedAndRemoveUntil("homepage", (route) => false));
          setState(() {
            isLoading = false;
          });
        } else {
          Position position = await Geolocator.getCurrentPosition();

          DocumentReference response = await stations.add({
            'name': addNameController.text,
            'location': GeoPoint(position.latitude, position.longitude),
            'id': FirebaseAuth.instance.currentUser!.uid,
            'timestamp': FieldValue.serverTimestamp(),
          });

          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            animType: AnimType.rightSlide,
            desc: 'تمت الإضافة بنجاح: ${addNameController.text}',
            btnOkOnPress: () {
              setState(() {
                isLoading = false;
              });
            },
          ).show().then((value) => Navigator.of(context)
              .pushNamedAndRemoveUntil("homepage", (route) => false));
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          desc: 'حدث خطأ أثناء الإضافة!',
        ).show();
      }
    }
  }

  Future<void> getStationLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        AwesomeDialog(
          btnCancelText: "العوده",
          context: context,
          dialogType: DialogType.warning,
          animType: AnimType.rightSlide,
          desc: "لا يمكن اضافة الموقف بدون الموقع",
          btnCancelOnPress: () async {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) {
                return const StationName();
              }),
              (route) => false,
            );
          },
        ).show();
      }
    }
    if (permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition();
    }
  }

  @override
  void dispose() {
    super.dispose();
    addNameController.dispose();
  }

  @override
  void initState() {
    getStationLocation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text("اضافة الموقف"),
        ),
        body: Form(
          key: formstate,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                  color: Colors.blue,
                ))
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: CustomTextForm(
                        hintText: "ادخل اسم الموقف",
                        myController: addNameController,
                        validator: (val) {
                          if (val == "") {
                            return "enter namee";
                          }
                          return null;
                        },
                      ),
                    ),
                    CustomButtonAuth(
                      child: "اضافة",
                      onPressed: () {
                        addStationName();
                      },
                    )
                  ],
                ),
        ),
      ),
    );
  }
}
