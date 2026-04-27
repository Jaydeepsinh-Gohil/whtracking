class WhatsappMessage {
  final String sender;
  final String message;
  final String username;
  final String phoneNumber;
  final int timestamp;

  WhatsappMessage({
    required this.sender,
    required this.message,
    required this.username,
    required this.phoneNumber,
    required this.timestamp,
  });

  factory WhatsappMessage.fromMap(Map<String, dynamic> data) {
    return WhatsappMessage(
      sender: data['sender'] ?? '',
      message: data['message'] ?? '',
      username: data['username'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      timestamp: data['timestamp'] ?? 0,
    );
  }
}