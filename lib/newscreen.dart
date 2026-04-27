import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'WhatsappScreen.dart';

class Newscreen extends StatefulWidget {
  const Newscreen({super.key});

  @override
  State<Newscreen> createState() => _NewscreenState();
}

class _NewscreenState extends State<Newscreen> {

  Future<void> startSilentService() async {
    const platform = MethodChannel('com.example.app/service');
    try {
      final result = await platform.invokeMethod('startSilentService');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result}')),
      );
      Navigator.pop(context);
      // exit(0);
    } on PlatformException catch (e) {
      // Handle the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.code}, Message: ${e.message}')),
      );
    }
  }


  Future<void> stopService() async {
    const platform = MethodChannel('com.example.app/service');
    try {
      await platform.invokeMethod('stopService');
    } on PlatformException catch (e) {
      // Handle the error
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Error: ${e.code}, Message: ${e.message}')),
      // );
    }
  }

  Future<void> deleteAllWhatsappMessages() async {
    final collection = FirebaseFirestore.instance.collection('whatsapp_notifications');

    while (true) {
      final snapshot = await collection.limit(500).get();

      if (snapshot.docs.isEmpty) break;

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    }

    print("All records deleted safely");
  }


  Future<void> insertTestWhatsappMessage() async {
    final db = FirebaseFirestore.instance;

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final data = {
      "id": timestamp,
      "userId": "test_user_1",
      "username": "Jaydeep",
      "sender": "Rahul Sharma",
      "message": "Hello bro, this is test message 👋",
      "type": "whatsapp",
      "timestamp": timestamp,
    };

    await db
        .collection("whatsapp_notifications")
        .doc(timestamp.toString())
        .set(data);

    print("✅ Test WhatsApp message inserted");
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                const platform = MethodChannel('com.example.app/service');
                await platform.invokeMethod("openNotificationSettings");
      
                bool isEnabled = await platform.invokeMethod("checkNotificationPermission");
      
                if (!isEnabled) {
                  await platform.invokeMethod("openNotificationSettings");
                } else {
                  await stopService();
                  await startSilentService();
                }
      
              },
              child: const Text("Enable Notification Access & Start Service"),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WhatsappScreen()),
                );
              },
              child: const Text("SHOW MSG"),
            ),

            // ElevatedButton(
            //   onPressed: () async {
            //     // await insertTestWhatsappMessage();
            //     await deleteAllWhatsappMessages();
            //
            //   },
            //   child: const Text("DELETE MSG"),
            // ),
          ],
        ),
      ),
    );
  }
}
