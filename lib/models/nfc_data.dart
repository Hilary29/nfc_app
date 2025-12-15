import 'dart:convert';

class NfcData {
  final String sender;
  final String content;
  final DateTime timestamp;

  NfcData({
    required this.sender,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory NfcData.fromJson(Map<String, dynamic> json) {
    return NfcData(
      sender: json['sender'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  String toJson() {
    return jsonEncode(toMap());
  }

  bool validate() {
    if (sender.isEmpty || content.isEmpty) {
      return false;
    }
    if (utf8.encode(toJson()).length > 800) {
      return false;
    }
    return true;
  }
}
