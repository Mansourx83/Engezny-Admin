import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ViewComplaint extends StatefulWidget {
  const ViewComplaint({Key? key}) : super(key: key);

  @override
  _ViewComplaintState createState() => _ViewComplaintState();
}

class _ViewComplaintState extends State<ViewComplaint> {
  TextEditingController addNameController = TextEditingController();
  late String userId;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      if (mounted) {
        setState(() {
          userId = user.uid;
        });
        print(userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('صفحة الشكاوي'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              'الشكاوي المرسلة',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    cursorColor: Colors.blue,
                    controller: addNameController,
                    onChanged: (value) {
                      setState(() {
                        isSearching = true;
                      });
                    },
                    decoration: InputDecoration(
                        hintText: 'ابحث عن موقفك او نمرة سيارة...',
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue))),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    setState(() {});
                  },
                ),
              ],
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                        snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Container(
                        height: 50,
                        width: 60,
                        child: FittedBox(
                          child: CircularProgressIndicator(
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    );
                  }

                  final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                      documents = snapshot.data?.docs ?? [];
                  List<Map<String, dynamic>> filteredComplaints = documents
                      .map((QueryDocumentSnapshot<Map<String, dynamic>>
                              document) =>
                          document.data())
                      .where((messageData) {
                    if (addNameController.text.isEmpty) {
                      return true;
                    } else {
                      return (messageData['startingLocation'] != null &&
                              messageData['startingLocation'] != '' &&
                              messageData['startingLocation']
                                  .contains(addNameController.text)) ||
                          (messageData['endingLocation'] != null &&
                              messageData['endingLocation'] != '' &&
                              messageData['endingLocation']
                                  .contains(addNameController.text)) ||
                          (messageData['carNumber'] != null &&
                              messageData['carNumber'] != '' &&
                              messageData['carNumber']
                                  .contains(addNameController.text));
                    }
                  }).toList();

                  return ListView.builder(
                    physics: BouncingScrollPhysics(),
                    itemCount: filteredComplaints.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Map<String, dynamic> messageData =
                          filteredComplaints[index];

                      return _buildMessageCard(messageData);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> messageData) {
    DateTime? timestamp = _getTimestamp(messageData);

    if (timestamp != null) {
      String formattedTime = DateFormat('d/MM :HH:mm').format(timestamp);

      return FutureBuilder<String?>(
        future: _getUserName(messageData['userId']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    child: const CircularProgressIndicator(
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  )
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            String userName = snapshot.data ?? 'Unknown User';
            // Check if the current user's ID matches the station ID in the complaint data
            if (userId == messageData['stationId']) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رقم السيارة: ${messageData['carNumber']}',
                        style: const TextStyle(fontSize: 20),
                      ),
                      Text(
                        'محتوى الشكوى: ${messageData['complaint']}',
                        style: const TextStyle(fontSize: 20),
                      ),
                      Text(
                        'ركب  من موقف: ${messageData['startingLocation']}',
                        style: const TextStyle(fontSize: 20),
                      ),
                      Text(
                        'خط : ${messageData['endingLocation']}',
                        style: const TextStyle(fontSize: 20),
                      ),
                      Text(
                        'تاريخ الشكوي: $formattedTime',
                        style: const TextStyle(fontSize: 20),
                      ),
                      Text(
                        'المستخدم: ${messageData['userName']}',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return const SizedBox(); // Don't display the complaint
            }
          }
        },
      );
    } else {
      return const SizedBox();
    }
  }

  DateTime? _getTimestamp(Map<String, dynamic> messageData) {
    final timestamp = messageData['timestamp'];
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return null;
  }

  Future<String?> _getUserName(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userSnapshot.exists) {
        return userSnapshot.data()!['userName'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
