import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/rendering.dart';
import 'package:flutterfirebase/services/cars/add_cars.dart';
import 'package:flutterfirebase/services/cars/edit_cars.dart';
import 'package:flutterfirebase/view/view_complaint.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

class ViewCars extends StatefulWidget {
  const ViewCars({super.key, required this.lineId, required this.stationId});

  final String lineId;
  final String stationId;

  @override
  State<ViewCars> createState() => _ViewCarsState();
}

class _ViewCarsState extends State<ViewCars> {
  List<QueryDocumentSnapshot> carsAvailable = [];
  int totalNumberOfCars = 0;
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingButtons = true;

  Future<void> getData() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection("المواقف")
        .doc(widget.stationId)
        .collection("line")
        .doc(widget.lineId)
        .collection("car")
        .orderBy("timestamp", descending: false)
        .get();

    carsAvailable = querySnapshot.docs;
    totalNumberOfCars = carsAvailable.length;
    isLoading = false;
    setState(() {});
  }

  @override
  void initState() {
    getData();
    super.initState();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: AnimatedOpacity(
        opacity: _showFloatingButtons ? 1.0 : 0.0,
        duration: Duration(milliseconds: 500),
        child: _showFloatingButtons
            ? Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton.extended(
                    backgroundColor: Colors.blue,
                    onPressed: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) {
                          return AddCar(
                            lineId: widget.lineId,
                            stationId: widget.stationId,
                          );
                        },
                      ));
                    },
                    label: const Text(
                      'اضافة سيارة',
                      style: TextStyle(color: Colors.white),
                    ),
                    icon: const Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton.extended(
                    heroTag: 'deleteCarByBarcode',
                    backgroundColor: Colors.red,
                    onPressed: _deleteCarByBarcode,
                    label: const Text('حذف سيارة بالباركود',
                        style: TextStyle(color: Colors.white)),
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : SizedBox(),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 0.0,
            floating: true,
            pinned: true,
            snap: false,
            backgroundColor: Colors.blue,
            title: Text("العربيات المتاحة: $totalNumberOfCars"),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.blue,
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Text("جار التحميل....."),
                          ],
                        ),
                      )
                    : InkWell(
                        onTap: () {},
                        child: Card(
                          child: Column(
                            children: [
                              Text(
                                "${carsAvailable[index]["numberOfCar"]}",
                                style: const TextStyle(fontSize: 20),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      AwesomeDialog(
                                        btnCancelText: "حذف",
                                        context: context,
                                        dialogType: DialogType.warning,
                                        animType: AnimType.rightSlide,
                                        desc:
                                            'هل تريد حذف ${carsAvailable[index]["numberOfCar"]}',
                                        btnCancelOnPress: () async {
                                          await FirebaseFirestore.instance
                                              .collection("المواقف")
                                              .doc(widget.stationId)
                                              .collection("line")
                                              .doc(widget.lineId)
                                              .collection("car")
                                              .doc(carsAvailable[index].id)
                                              .delete();
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                                builder: (context) {
                                              return ViewCars(
                                                lineId: widget.lineId,
                                                stationId: widget.stationId,
                                              );
                                            }),
                                          );
                                        },
                                      ).show();
                                    },
                                    icon: const Icon(Icons.delete),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      AwesomeDialog(
                                        context: context,
                                        dialogType: DialogType.warning,
                                        animType: AnimType.rightSlide,
                                        desc:
                                            'هل تريد التعديل على ${carsAvailable[index]["numberOfCar"]}',
                                        btnOkText: "تعديل",
                                        btnOkOnPress: () {
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                                builder: (context) {
                                              return EditCar(
                                                lineId: widget.lineId,
                                                stationId: widget.stationId,
                                                oldNumberOfCar:
                                                    carsAvailable[index]
                                                        ["numberOfCar"],
                                                carDocId:
                                                    carsAvailable[index].id,
                                              );
                                            }),
                                          );
                                        },
                                      ).show();
                                    },
                                    icon: const Icon(Icons.edit),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
              },
              childCount: carsAvailable.length,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCarByBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode) {
        String barcode = result.rawContent;
        String carNumber = barcode;
        await FirebaseFirestore.instance
            .collection("المواقف")
            .doc(widget.stationId)
            .collection("line")
            .doc(widget.lineId)
            .collection("car")
            .where("numberOfCar", isEqualTo: carNumber)
            .get()
            .then((QuerySnapshot querySnapshot) {
          querySnapshot.docs.forEach((doc) async {
            await doc.reference.delete();
          });
        });

        await getData();
      }
    } catch (e) {}
  }
}
