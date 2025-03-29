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


class CallSection extends StatelessWidget {
  final String userId;

  CallSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('calls')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No call records found'));
        }

        var calls = snapshot.data!.docs;

        return ListView.builder(
          itemCount: calls.length,
          itemBuilder: (context, index) {
            var call = calls[index];
            String callType = call['callType']; // incoming, outgoing, missed
            String phoneNumber = call['phoneNumber'];
            String contactName = call['contactName'];

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all( color: Colors.grey),
                ),
                child: ListTile(
                  leading: Icon(Icons.phone, color: callType.toUpperCase() == "INCOMING CALL" ?
                  Colors.green : callType.toUpperCase() == "OUTGOING CALL"? Colors.blue : Colors.green),
                  title: Text(callType.toUpperCase()),
                  subtitle: Text(contactName.isNotEmpty ? contactName : phoneNumber ?? ""),
                  // trailing: IconButton(
                  //   icon: Icon(Icons.copy, color: Colors.grey),
                  //   onPressed: () => copyText(context, callType.toUpperCase().toString()),
                  // ),
                ),

              ),
            );
          },
        );
      },
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


class SmsSection extends StatelessWidget {
  final String userId;

  SmsSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sms')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No call records found'));
        }

        var smsS = snapshot.data!.docs;

        return ListView.builder(
          itemCount: smsS.length,
          itemBuilder: (context, index) {
            var sms = smsS[index];
            String smsType = sms['type']; // incoming, outgoing, missed
            String smsTypeString = sms['smsType']; // incoming, outgoing, missed
            String phoneNumber = sms['phoneNumber'];
            String messageContent = sms['message'];
            String contactName = sms['contactName'];

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all( color: Colors.grey),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.sms,
                    color: smsType == '2' ? Colors.blue : Colors.green, // Outgoing: Blue, Incoming: Green
                  ),
                  title: Text(
                    "${smsTypeString.toUpperCase()}\n${formatTimestamp(sms['timestamp'])}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: ReadMoreText("${contactName.isNotEmpty ? contactName : phoneNumber} (${messageContent})",
                    // "${smsType == '2' ? "Outgoing Sms To" : "Incoming Sms From"} $phoneNumber : $messageContent",
                    trimMode: TrimMode.Line,
                    trimLines: 2,
                    colorClickableText: Colors.pink,
                    trimCollapsedText: 'Show more',
                    trimExpandedText: 'Show less',
                    moreStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ), // Display SMS content
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
