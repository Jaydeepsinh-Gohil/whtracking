import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';

class UserDetailScreen extends StatelessWidget {
  final String userId;

  UserDetailScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('User Details'),
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
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No call records found'));
              }

              var callLogs = snapshot.data!.docs;
              var filteredCallLogs = callLogs.where((call) {
                String contactName = call['contactName'].toString().toLowerCase();
                String phoneNumber = call['phoneNumber'].toString().toLowerCase();
                return contactName.contains(searchQuery) || phoneNumber.contains(searchQuery);
              }).toList();

              if (filteredCallLogs.isEmpty) {
                return Center(child: Text('No matching call records found'));
              }

              return ListView.builder(
                itemCount: filteredCallLogs.length,
                itemBuilder: (context, index) {
                  var call = filteredCallLogs[index];
                  String callType = call['callType'];
                  String phoneNumber = call['phoneNumber'];
                  String contactName = call['contactName'];

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.phone,
                          color: callType.toUpperCase() == "INCOMING CALL"
                              ? Colors.green
                              : callType.toUpperCase() == "OUTGOING CALL"
                              ? Colors.blue
                              : Colors.red,
                        ),
                        title: Text(callType.toUpperCase()),
                        subtitle: Text(contactName.isNotEmpty ? contactName : phoneNumber),
                        trailing: IconButton(
                          icon: Icon(Icons.copy, color: Colors.grey),
                          onPressed: () => copyText(context, phoneNumber.toString()),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String formatTimestamp(int? timestamp) {
    if(timestamp != null){
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
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
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No SMS records found'));
              }

              var smsList = snapshot.data!.docs;
              var filteredSmsList = smsList.where((sms) {
                String contactName = sms['contactName'].toString().toLowerCase();
                String phoneNumber = sms['phoneNumber'].toString().toLowerCase();
                return contactName.contains(searchQuery) || phoneNumber.contains(searchQuery);
              }).toList();

              if (filteredSmsList.isEmpty) {
                return Center(child: Text('No matching SMS records found'));
              }

              return ListView.builder(
                itemCount: filteredSmsList.length,
                itemBuilder: (context, index) {
                  var sms = filteredSmsList[index];
                  String smsType = sms['type'];
                  String smsTypeString = sms['smsType'];
                  String phoneNumber = sms['phoneNumber'];
                  String messageContent = sms['message'];
                  String contactName = sms['contactName'];

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.sms,
                          color: smsType == '2' ? Colors.blue : Colors.green,
                        ),
                        title: Text(
                          "${smsTypeString.toUpperCase()}\n${formatTimestamp(sms['timestamp'])}",
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
                        trailing: IconButton(
                          icon: Icon(Icons.copy, color: Colors.grey),
                          onPressed: () => copyText(context, messageContent),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );

  }

  String formatTimestamp(int? timestamp) {
    if(timestamp != null){
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    }else{
      return"";
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
