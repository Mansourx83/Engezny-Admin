// ignore_for_file: use_build_context_synchronously

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutterfirebase/components/custom_button_auth.dart';
import 'package:flutterfirebase/view/veiw_line.dart';
import '../../components/text_form.dart';

class EditLine extends StatefulWidget {
  const EditLine({
    super.key,
    required this.docId,
    required this.oldName,
    required this.stationId,
    required this.oldPrice,
  });

  final String docId;
  final String oldName;
  final String oldPrice;
  final String stationId;

  @override
  State<EditLine> createState() => _EditLineState();
}

class _EditLineState extends State<EditLine> {
  bool isLoading = false;
  TextEditingController editNameController = TextEditingController();
  final TextEditingController addPriceLine = TextEditingController();

  GlobalKey<FormState> formstate = GlobalKey();

  Future<void> editLine() async {
    CollectionReference line = FirebaseFirestore.instance
        .collection('المواقف')
        .doc(widget.docId)
        .collection("line");

    if (formstate.currentState!.validate()) {
      try {
        setState(() {
          isLoading = true;
        });

        await line.doc(widget.stationId).update({
          "nameLine": editNameController.text,
          'priceLine': addPriceLine.text,
        });

        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          animType: AnimType.rightSlide,
          desc: 'تم التعديل بنجاح',
          btnOkOnPress: () {
            Navigator.of(context)
                .pushReplacement(MaterialPageRoute(builder: (context) {
              return ViewLine(docId: widget.docId);
            }));
          },
        ).show();
      } catch (e) {
        setState(() {
          isLoading = false;
        });

        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          desc: 'حدث خطأ',
        ).show().then((value) => Navigator.of(context)
                .pushReplacement(MaterialPageRoute(builder: (context) {
              return ViewLine(docId: widget.docId);
            })));
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    editNameController.dispose();
  }

  @override
  void initState() {
    super.initState();

    editNameController.text = widget.oldName;
    addPriceLine.text = widget.oldPrice;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text("تعديل الخط"),
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
                      child: CustomTextForm(
                        hintText: "الاسم الجديد",
                        myController: editNameController,
                        validator: (val) {
                          if (val == "") {
                            return "ادخل الاسم";
                          }
                          return null;
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: CustomTextForm(
                        keyboardType: TextInputType.number,
                        hintText: "السعر الجديد",
                        myController: addPriceLine,
                        validator: (val) {
                          if (val == "") {
                            return "ادخل السعر";
                          }
                          return null;
                        },
                      ),
                    ),
                    CustomButtonAuth(
                      child: "حفظ",
                      onPressed: () {
                        editLine();
                      },
                    )
                  ],
                ),
        ),
      ),
    );
  }
}
