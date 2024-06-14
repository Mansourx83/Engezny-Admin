import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutterfirebase/components/custom_button_auth.dart';
import 'package:flutterfirebase/components/text_form.dart';
import 'package:flutterfirebase/view/veiw_line.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class AddLine extends StatefulWidget {
  const AddLine({super.key, required this.docId});

  final String docId;

  @override
  State<AddLine> createState() => _AddLineState();
}

class _AddLineState extends State<AddLine> {
  final TextEditingController addNameLine = TextEditingController();
  final TextEditingController addPriceLine = TextEditingController();
  final GlobalKey<FormState> formstate = GlobalKey();
  bool isLoading = false;

  Future<void> addLineAsync() async {
    final CollectionReference line = FirebaseFirestore.instance
        .collection('المواقف')
        .doc(widget.docId)
        .collection("line");

    if (formstate.currentState!.validate()) {
      try {
        final QuerySnapshot nameLine =
            await line.where('nameLine', isEqualTo: addNameLine.text).get();

        if (nameLine.docs.isNotEmpty) {
          showErrorDialog('الخط موجود بالفعل');
        } else {
          setState(() {
            isLoading = true;
          });

          final DocumentReference response = await line.add({
            'nameLine': addNameLine.text,
            'priceLine': addPriceLine.text,
          });
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) {
              return ViewLine(docId: widget.docId);
            }),
          );
        }
      } catch (e) {
        showErrorDialog('حدثت مشكلة أثناء إضافة الخط');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showErrorDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.rightSlide,
      desc: message,
      btnCancelOnPress: () {},
    ).show();
  }

  void showSuccessDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.rightSlide,
      desc: message,
      btnOkOnPress: () {},
    ).show();
  }

  @override
  void dispose() {
    addNameLine.dispose();
    addPriceLine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text("إضافة خط جديد"),
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
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: CustomTextForm(
                        hintText: "ادخل اسم الخط",
                        myController: addNameLine,
                        validator: (val) {
                          return val!.isEmpty ? "ادخل الاسم" : null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: CustomTextForm(
                        keyboardType: TextInputType.number,
                        hintText: "ادخل سعر الخط",
                        myController: addPriceLine,
                        validator: (val) {
                          return val!.isEmpty ? "ادخل السعر" : null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomButtonAuth(
                      child: "اضافة",
                      onPressed: addLineAsync,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
