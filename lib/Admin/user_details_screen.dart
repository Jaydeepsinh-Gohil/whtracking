import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';

class UserDetailScreen extends StatelessWidget {
  final String userId;
  final String userName;

  UserDetailScreen({required this.userId,required this.userName});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(userName ?? 'User Details'),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.call), text: 'Call'),
              Tab(icon: Icon(Icons.sms), text: 'SMS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            CallSection(userId: userId), // Call Tab
            SmsSection(userId: userId),  // SMS Tab
          ],
        ),
      ),
    );
  }
}


class CallSection extends StatefulWidget {
  final String userId;

  CallSection({required this.userId});

  @override
  State<CallSection> createState() => _CallSectionState();
}

class _CallSectionState extends State<CallSection> {
  TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: "Search by name or phone number",
              hintText: "Search by name or phone number",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('calls')
                .where('userId', isEqualTo: widget.userId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No call records found'));
              }

              var callLogs = snapshot.data!.docs;

              // Filtering based on search
              var filteredCallLogs = callLogs.where((call) {
                String contactName = call['contactName'].toString().toLowerCase();
                String phoneNumber = call['phoneNumber'].toString().toLowerCase();
                return contactName.contains(searchQuery) || phoneNumber.contains(searchQuery);
              }).toList();

              if (filteredCallLogs.isEmpty) {
                return Center(child: Text('No matching call records found'));
              }

              // Grouping by Date
              Map<String, List<QueryDocumentSnapshot>> groupedCalls = {};
              for (var call in filteredCallLogs) {
                DateTime callDate = DateTime.fromMillisecondsSinceEpoch(call['timestamp']);
                String formattedDate = getFormattedDate(callDate);

                if (!groupedCalls.containsKey(formattedDate)) {
                  groupedCalls[formattedDate] = [];
                }
                groupedCalls[formattedDate]!.add(call);
              }

              return ListView(
                children: groupedCalls.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Text(
                          entry.key,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...entry.value.map((call) {
                        String callType = call['callType'];
                        String phoneNumber = call['phoneNumber'];
                        String contactName = call['contactName'];

                        return Container(
                          // decoration: BoxDecoration(
                          //   border: Border.all(color: Colors.grey),
                          // ),
                          child: ListTile(
                            leading: callType.toUpperCase() == "INCOMING CALL"?
                            Image.asset("assets/incoming-call.png",height: 22,):
                            callType.toUpperCase() == "OUTGOING CALL" ?
                            Image.asset("assets/outgoing-call.png",height: 20,) : SizedBox.shrink()
                            ,
                            // Icon(
                            //   Icons.phone_callback,
                            //   color: callType.toUpperCase() == "INCOMING CALL"
                            //       ? Colors.green
                            //       : callType.toUpperCase() == "OUTGOING CALL"
                            //       ? Colors.blue
                            //       : Colors.red,
                            // ),
                            title: Text(contactName.isNotEmpty ? contactName : phoneNumber,style: TextStyle(fontSize: 16),),
                            subtitle: Text(callType.toUpperCase()),
                            trailing: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(formatTimestamp(call['timestamp']),style: TextStyle(fontSize: 16,color: Theme.of(context).colorScheme.primary),),
                                GestureDetector(
                                  onTap: () => copyText(context, phoneNumber.toString()),
                                    child: Icon(Icons.copy, color: Colors.grey)),
                                // IconButton(
                                //   icon: Icon(Icons.copy, color: Colors.grey),
                                //   onPressed: () => copyText(context, phoneNumber.toString()),
                                // ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  // Function to get formatted date
  String getFormattedDate(DateTime date) {
    DateTime today = DateTime.now();
    DateTime yesterday = today.subtract(Duration(days: 1));

    if (DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(today)) {
      return "Today";
    } else if (DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(yesterday)) {
      return "Yesterday";
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }
  String formatTimestamp(int? timestamp) {
    if(timestamp != null){
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateFormat('hh:mm a').format(dateTime);
    }else{
      return"";
    }
  }
}


class SmsSection extends StatefulWidget {
  final String userId;

  SmsSection({required this.userId});

  @override
  State<SmsSection> createState() => _SmsSectionState();
}

class _SmsSectionState extends State<SmsSection> {
  TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: "Search by name or phone number",
              hintText: "Search by name or phone number",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sms')
                .where('userId', isEqualTo: widget.userId)
                .orderBy('timestamp', descending: true) // Requires Firestore Index
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No SMS records found'));
              }

              var smsList = snapshot.data!.docs;

              // Filter based on search query
              var filteredSmsList = smsList.where((sms) {
                String contactName = sms['contactName'].toString().toLowerCase();
                String phoneNumber = sms['phoneNumber'].toString().toLowerCase();
                return contactName.contains(searchQuery) || phoneNumber.contains(searchQuery);
              }).toList();

              if (filteredSmsList.isEmpty) {
                return Center(child: Text('No matching SMS records found'));
              }

              // Grouping messages by date
              Map<String, List<QueryDocumentSnapshot>> groupedSms = {};
              for (var sms in filteredSmsList) {
                String formattedDate = formatTimestamp(sms['timestamp']);

                if (!groupedSms.containsKey(formattedDate)) {
                  groupedSms[formattedDate] = [];
                }
                groupedSms[formattedDate]!.add(sms);
              }

              return ListView(
                children: groupedSms.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Text(
                          entry.key, // Date header (Today, Yesterday, or actual date)
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...entry.value.map((sms) {
                        String smsType = sms['type'];
                        String smsTypeString = sms['smsType'];
                        String phoneNumber = sms['phoneNumber'];
                        String messageContent = sms['message'];
                        String contactName = sms['contactName'];

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Container(
                            // decoration: BoxDecoration(
                            //   border: Border.all(color: Colors.grey),
                            //   borderRadius: BorderRadius.circular(8),
                            // ),
                            child: ListTile(
                              leading: Icon(
                                Icons.sms,
                                color: smsType == '2' ? Colors.blue : Colors.green,
                              ),
                              title: Text(
                                "${smsTypeString.toUpperCase()} SMS",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: ReadMoreText(
                                "${contactName.isNotEmpty ? contactName : phoneNumber} (${messageContent})",
                                trimMode: TrimMode.Line,
                                trimLines: 2,
                                colorClickableText: Colors.pink,
                                trimCollapsedText: 'Show more',
                                trimExpandedText: 'Show less',
                                moreStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              trailing: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 10,
                                children: [
                                  Text(showformatTimestamp(sms['timestamp']),style: TextStyle(fontSize: 16,color: Theme.of(context).colorScheme.primary),),
                                  GestureDetector(
                                      onTap: () => copyText(context, messageContent),
                                      child: Icon(Icons.copy, color: Colors.grey)),
                                  // IconButton(
                                  //   icon: Icon(Icons.copy, color: Colors.grey),
                                  //   onPressed: () => copyText(context, messageContent),
                                  // ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );

  }

  String showformatTimestamp(int? timestamp) {
    if(timestamp != null){
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateFormat('hh:mm a').format(dateTime);
    }else{
      return"";
    }
  }

  String formatTimestamp(dynamic timestamp) {
    DateTime date;
    if (timestamp is int) {
      date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return "Unknown Date";
    }

    DateTime today = DateTime.now();
    DateTime yesterday = today.subtract(Duration(days: 1));

    if (DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(today)) {
      return "Today";
    } else if (DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(yesterday)) {
      return "Yesterday";
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }
}

void copyText(BuildContext context,String copyContent) {
  String textToCopy = copyContent;

  Clipboard.setData(ClipboardData(text: textToCopy));

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("Copied to clipboard!"),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
