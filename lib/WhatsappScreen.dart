import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'msgModel.dart';

class WhatsappScreen extends StatefulWidget {
  const WhatsappScreen({super.key});

  @override
  State<WhatsappScreen> createState() => _WhatsappScreenState();
}

class _WhatsappScreenState extends State<WhatsappScreen> {
  static const platform = MethodChannel('com.example.app/service');

  List<WhatsappMessage> messages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  // ✅ Fetch from native
  Future<void> loadMessages() async {
    try {
      final List<dynamic> result =
      await platform.invokeMethod("getLocalWhatsappMessages");

      final data = result.map((e) {
        return WhatsappMessage.fromMap(Map<String, dynamic>.from(e));
      }).toList();

      setState(() {
        messages = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching local messages: $e");
    }
  }

  // ✅ Clear messages
  Future<void> clearMessages() async {
    await platform.invokeMethod("clearLocalWhatsappMessages");
    await loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("WhatsApp Messages"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadMessages,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: clearMessages,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : messages.isEmpty
          ? const Center(child: Text("No messages found"))
          : ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[index];

          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            child: ListTile(
              leading: const Icon(Icons.message),
              title: Text(
                msg.sender,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg.message),
                ],
              ),
              trailing: Text(
                _formatTime(msg.timestamp),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}