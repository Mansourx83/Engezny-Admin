import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:barcode_scan2/gen/protos/protos.pbenum.dart';
import 'package:barcode_scan2/platform_wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutterfirebase/services/lines/add_line.dart';
import 'package:flutterfirebase/services/lines/edit_line.dart';
import 'package:flutterfirebase/view/view_cars.dart';

class ViewLine extends StatefulWidget {
  const ViewLine({Key? key, required this.docId}) : super(key: key);

  final String docId;

  @override
  State<ViewLine> createState() => _ViewLineState();
}

class _ViewLineState extends State<ViewLine> {
  late Future<List<QueryDocumentSnapshot>> linesFuture;
  late String stationId;
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingButtons = true;
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    linesFuture = getData();

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        setState(() {
          _showFloatingButtons = true;
        });
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        setState(() {
          _showFloatingButtons = false;
        });
      }
    });
  }

  Future<List<QueryDocumentSnapshot>> getData() async {
    DocumentSnapshot stationSnapshot = await FirebaseFirestore.instance
        .collection("المواقف")
        .doc(widget.docId)
        .get();

    stationId = widget.docId;

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection("المواقف")
        .doc(widget.docId)
        .collection("line")
        .get();

    return querySnapshot.docs.toList();
  }

  Widget buildGridItem(QueryDocumentSnapshot line) {
    return InkWell(
      onTap: () => navigateToViewCars(line.id),
      child: Card(
        elevation: 3,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                "asset/images/micrbus.png",
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            Text(
              "${line["nameLine"]}",
              style: const TextStyle(fontSize: 20),
            ),
            Text(
              "${line["priceLine"]}ج",
              style: const TextStyle(fontSize: 20),
            ),
            buildActionButtons(line),
          ],
        ),
      ),
    );
  }

  Widget buildActionButtons(QueryDocumentSnapshot line) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        buildActionButton(
          onPressed: () => showDeleteDialog(line),
          icon: Icons.delete,
        ),
        buildActionButton(
          onPressed: () => showEditDialog(line),
          icon: Icons.edit,
        ),
      ],
    );
  }

  Widget buildActionButton({VoidCallback? onPressed, IconData? icon}) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }

  Future<void> showDeleteDialog(QueryDocumentSnapshot line) async {
    await AwesomeDialog(
      btnCancelText: "حذف",
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.rightSlide,
      desc: 'هل تريد حذف ${line["nameLine"]}',
      btnCancelOnPress: () async {
        await deleteLine(line.id);
        setState(() {
          linesFuture = getData();
        });
      },
    ).show();
  }

  Future<void> showEditDialog(QueryDocumentSnapshot line) async {
    await AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.rightSlide,
      desc: 'هل تريد التعديل على ${line["nameLine"]}',
      btnOkText: "تعديل",
      btnOkOnPress: () {
        navigateToEditLine(line.id, line["nameLine"], line["priceLine"]);
      },
    ).show();
  }

  Future<void> deleteLine(String lineId) async {
    await FirebaseFirestore.instance
        .collection("المواقف")
        .doc(widget.docId)
        .collection("line")
        .doc(lineId)
        .delete();
  }

  void navigateToViewCars(String lineId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ViewCars(lineId: lineId, stationId: stationId);
        },
      ),
    );
  }

  void navigateToEditLine(String lineId, String oldName, String oldPrice) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) {
          return EditLine(
            stationId: lineId,
            docId: widget.docId,
            oldName: oldName,
            oldPrice: oldPrice,
          );
        },
      ),
    );
  }

  void navigateToAddLine() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) {
          return AddLine(docId: widget.docId);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 0.0,
              floating: false,
              pinned: true,
              title: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: FutureBuilder<List<QueryDocumentSnapshot>>(
                  future: linesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator(
                        color: Colors.blue,
                      );
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else {
                      return Text(
                        "الخطوط المتاحة: ${snapshot.data!.length}",
                      );
                    }
                  },
                ),
              ),
            ),
          ];
        },
        body: isLoading
            ? Center(
                child: CircularProgressIndicator(
                color: Colors.blue,
              ))
            : FutureBuilder<List<QueryDocumentSnapshot>>(
                future: linesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.blue,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text("Error: ${snapshot.error}"),
                    );
                  } else {
                    return GridView.builder(
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.only(top: 6),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 260,
                      ),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, i) {
                        return buildGridItem(snapshot.data![i]);
                      },
                    );
                  }
                },
              ),
      ),
      floatingActionButton: AnimatedOpacity(
        opacity: _showFloatingButtons ? 1.0 : 0.0,
        duration: Duration(milliseconds: 500),
        child: _showFloatingButtons ? FloatingButton() : SizedBox(),
      ),
    );
  }

  Column FloatingButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          backgroundColor: Colors.blue,
          onPressed: navigateToAddLine,
          label: const Text(
            'اضافة خط جديد',
            style: TextStyle(color: Colors.white),
          ),
          icon: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        FloatingActionButton.extended(
          heroTag: 'addByBarcode',
          backgroundColor: Colors.green,
          onPressed: () {
            _scanBarcodeAndAddCar();
          },
          label: Text(
            'الإضافة بالباركود',
            style: TextStyle(color: Colors.white),
          ),
          icon: Icon(
            Icons.qr_code_scanner,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        // زر جديد للحذف بالباركود
        FloatingActionButton.extended(
          heroTag: 'deleteByBarcode',
          backgroundColor: Colors.red,
          onPressed: () {
            _deleteCarByBarcode();
          },
          label: Text(
            'الحذف بالباركود',
            style: TextStyle(color: Colors.white),
          ),
          icon: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _deleteCarByBarcode() async {
    setState(() {
      isLoading = true;
    });
    try {
      var result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode) {
        String barcodeData = result.rawContent;
        List<String> dataParts = barcodeData.split(',');
        if (dataParts.length == 2) {
          String lineName = dataParts[0].trim();
          String carNumber = dataParts[1].trim();

          var lineSnapshot = await FirebaseFirestore.instance
              .collection("المواقف")
              .doc(widget.docId)
              .collection("line")
              .where("nameLine", isEqualTo: lineName)
              .get();

          if (lineSnapshot.docs.isNotEmpty) {
            String lineId = lineSnapshot.docs.first.id;

            var carSnapshot = await FirebaseFirestore.instance
                .collection("المواقف")
                .doc(widget.docId)
                .collection("line")
                .doc(lineId)
                .collection("car")
                .where("numberOfCar", isEqualTo: carNumber)
                .get();

            if (carSnapshot.docs.isNotEmpty) {
              // حذف السيارة
              await carSnapshot.docs.first.reference.delete();
              _showDialog("نجاح", "تم حذف السيارة بنجاح.");
            } else {
              _showDialog("خطأ", "لم يتم العثور على السيارة لحذفها.");
            }
          } else {
            _showDialog("خطأ", "لم يتم العثور على الخط المحدد.");
          }
        } else {
          _showDialog("خطأ", "بيانات الباركود غير صالحة للحذف.");
        }
      }
    } catch (e) {
      _showDialog("خطأ", "حدث خطأ أثناء مسح الباركود للحذف: $e.");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _scanBarcodeAndAddCar() async {
    setState(() {
      isLoading = true;
    });
    try {
      var result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode) {
        String barcodeData = result.rawContent;
        List<String> dataParts = barcodeData.split(',');
        if (dataParts.length == 2) {
          String lineName = dataParts[0].trim();
          String carNumber = dataParts[1].trim();

          RegExp carNumberRegex = RegExp(r'^[\u0600-\u06FF]{2,3}\d{2,4}$');
          if (!carNumberRegex.hasMatch(carNumber)) {
            _showDialog("خطأ", "رقم السيارة غير صالح.");
            return;
          }
          var lineSnapshot = await FirebaseFirestore.instance
              .collection("المواقف")
              .doc(widget.docId)
              .collection("line")
              .where("nameLine", isEqualTo: lineName)
              .get();

          if (lineSnapshot.docs.isNotEmpty) {
            String lineId = lineSnapshot.docs.first.id;

            // التحقق من وجود السيارة في الخط الحالي
            var carInCurrentLineSnapshot = await FirebaseFirestore.instance
                .collection("المواقف")
                .doc(widget.docId)
                .collection("line")
                .doc(lineId)
                .collection("car")
                .where("numberOfCar", isEqualTo: carNumber)
                .get();

            if (carInCurrentLineSnapshot.docs.isNotEmpty) {
              _showDialog("خطأ", "السيارة موجودة بالفعل في الخط الحالي.");
              return;
            }

            // التحقق من وجود السيارة في خطوط أخرى ضمن نفس الموقف
            // التحقق من وجود السيارة في خطوط أخرى ضمن نفس الموقف
            var carInOtherLinesSnapshot = await FirebaseFirestore.instance
                .collection("المواقف")
                .doc(widget.docId)
                .collection("line")
                .where(FieldPath.documentId,
                    isNotEqualTo: lineId) // استثناء الخط الحالي من البحث
                .get();

            bool carFoundInAnotherLine = false;
            String foundLineName =
                ""; // متغير جديد لتخزين اسم الخط الذي وُجدت فيه السيارة

            for (var doc in carInOtherLinesSnapshot.docs) {
              var carsSnapshot = await doc.reference
                  .collection("car")
                  .where("numberOfCar", isEqualTo: carNumber)
                  .get();
              if (carsSnapshot.docs.isNotEmpty) {
                carFoundInAnotherLine = true;
                foundLineName = doc.data()["nameLine"]; // تخزين اسم الخط
                break;
              }
            }

            if (carFoundInAnotherLine) {
              _showDialog("خطأ",
                  "السيارة موجودة في نفس الموقف ولكن في خط آخر: $foundLineName."); // استخدام اسم الخط في الرسالة
              return;
            }

            // التحقق من وجود السيارة في مواقف أخرى
            var carInOtherStationsSnapshot = await FirebaseFirestore.instance
                .collectionGroup('car')
                .where('numberOfCar', isEqualTo: carNumber)
                .get();

            if (carInOtherStationsSnapshot.docs.isNotEmpty) {
              _showDialog("خطأ", "السيارة موجودة في  موقف اخر.");
              return;
            }

            await FirebaseFirestore.instance
                .collection("المواقف")
                .doc(widget.docId)
                .collection("line")
                .doc(lineId)
                .collection("car")
                .add({
              'numberOfCar': carNumber,
              'timestamp': FieldValue.serverTimestamp(),
            });
            _showDialog("نجاح", "تم إضافة السيارة بنجاح إلى الخط: $lineName.");
          } else {
            _showDialog("خطأ", "لم يتم العثور على الخط: $lineName.");
          }
        } else {
          _showDialog("خطأ", "بيانات الباركود غير صالحة.");
        }
      }
    } catch (e) {
      _showDialog("خطأ", "حدث خطأ أثناء مسح الباركود: $e.");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showDialog(String title, String content) {
    AwesomeDialog(
      context: context,
      dialogType: title == "نجاح" ? DialogType.success : DialogType.error,
      animType: AnimType.bottomSlide,
      title: title,
      desc: content,
      btnOkOnPress: () {},
    ).show();
  }
}
