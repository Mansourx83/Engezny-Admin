import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterfirebase/view/veiw_line.dart';
import 'package:flutterfirebase/services/station/add_station.dart';
import 'package:flutterfirebase/view/view_complaint.dart';
import 'package:badges/badges.dart' as badges;

class StationName extends StatefulWidget {
  const StationName({Key? key}) : super(key: key);

  @override
  State<StationName> createState() => _StationNameState();
}

class _StationNameState extends State<StationName> {
  DocumentSnapshot? stationDocument;
  bool isLoading = true;
  int totalComplaints = 0;
  late StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
      complaintsSubscription;
  bool newComplaint = false;

  @override
  void initState() {
    super.initState();
    _getStationName();
    _getTotalComplaints();
    _listenForComplaints();
    print(FirebaseAuth.instance.currentUser!.uid);
  }

  @override
  void dispose() {
    complaintsSubscription.cancel();
    super.dispose();
  }

  Future<void> _getStationName() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection("المواقف")
          .where("id", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        stationDocument = querySnapshot.docs.first;
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching station name: $e");
    }
  }

  Future<void> _getTotalComplaints() async {
    // هذه الوظيفة قد لا تكون ضرورية إذا كان _listenForComplaints يتحكم بالعداد
  }

  void _listenForComplaints() {
    complaintsSubscription = FirebaseFirestore.instance
        .collection('messages')
        .where('stationId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where('isViewed', isEqualTo: false) // فقط الشكاوى التي لم تُشاهد
        .snapshots()
        .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
      setState(() {
        totalComplaints = snapshot.docs.length; // تحديث عدد الشكاوى
        newComplaint = snapshot.docChanges.isNotEmpty;
      });
    });
  }

  void _navigateToAddStation() async {
    setState(() {
      isLoading = true;
    });

    await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return const AddStation();
    }));

    setState(() {
      isLoading = false;
    });
  }

  void _navigateToViewComplaint() async {
    setState(() {
      isLoading = true;
    });

    final complaintsQuery = FirebaseFirestore.instance
        .collection('messages')
        .where('stationId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where('isViewed', isEqualTo: false);

    final complaintsSnapshot = await complaintsQuery.get();

    for (var doc in complaintsSnapshot.docs) {
      await doc.reference.update({'isViewed': true});
    }

    // إضافة تأخير صغير قبل إعادة تعيين حالة isLoading إلى false
    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      isLoading = false;
    });

    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return ViewComplaint();
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: isLoading
          ? Container()
          : Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (stationDocument == null)
                  FloatingActionButton.extended(
                    backgroundColor: Colors.blue,
                    onPressed: _navigateToAddStation,
                    label: const Text('اضافة موقفك'),
                    icon: const Icon(Icons.add),
                  ),
                const SizedBox(height: 16),
                badges.Badge(
                  position: badges.BadgePosition.topEnd(top: 0, end: 3),
                  badgeAnimation: badges.BadgeAnimation.slide(
                    animationDuration: Duration(seconds: 1),
                  ),
                  badgeContent: Text(
                    totalComplaints.toString(),
                    style: TextStyle(color: Colors.white),
                  ),
                  badgeStyle: badges.BadgeStyle(badgeColor: Colors.red),
                  child: FloatingActionButton.extended(
                    heroTag: 'viewComplaints',
                    backgroundColor: Colors.blue,
                    onPressed: _navigateToViewComplaint,
                    icon: Text(
                      'رؤية الشكاوي ',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    label: Icon(
                      Icons.notifications,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("اسم الموقف: ${stationDocument?["name"] ?? ""}"),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil("login", (route) => false);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
              ),
            )
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                mainAxisExtent: 500,
              ),
              itemCount: stationDocument != null ? 1 : 0,
              itemBuilder: (context, i) {
                return InkWell(
                  onTap: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) {
                      return ViewLine(
                        docId: stationDocument?.id ?? "",
                      );
                    }));
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 60,
                      ),
                      Card(
                        elevation: 20,
                        child: Column(
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) {
                                    return ViewLine(
                                      docId: stationDocument?.id ?? "",
                                    );
                                  }),
                                );
                              },
                              child: const Text(
                                "رؤية الخطوط التي توجد في",
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            Text(
                              "${stationDocument?["name"] ?? ""}",
                              style: const TextStyle(fontSize: 34),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
