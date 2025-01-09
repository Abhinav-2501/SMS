import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async'; // For Timer
import 'package:get/get.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( // Use GetMaterialApp to support GetX navigation and state management
      title: 'Flutter SMS Inbox App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const SmsInboxPage(),
    );
  }
}

class SmsController extends GetxController {
  final SmsQuery _query = SmsQuery();
  var categorizedMessages = <String, List<SmsMessage>>{}.obs;
  Timer? _timer; // Timer for periodic fetching

  // Predefined categories map
  final Map<String, List<String>> categories = {
    "Groceries": ["General Store", "confectionary", "Kirana", "Supermarket", "Big Bazaar", "DMart", "Reliance Fresh", "Grocery", "Provision Store"],
    "Utilities Bills": ["Electricity", "Prepaid Recharges", "Postpaid Recharges", "Water", "Gas", "Gas Cylinder", "LPG", "PNG", "Tata Power", "MSEB", "BSNL", "MTNL", "Water Bill", "Electricity Bill", "Utility Payment"],
    "EMI": ["Loan", "EMI", "HDFC Loan", "SBI Loan", "Personal Loan", "Home Loan", "Car Loan", "Credit EMI", "EMI Due", "EMI Payment"],
    "Travel": ["Redbus", "IRCTC", "Roadlines", "Metro", "Rail"],
    "Food & Drinks": ["Restaurant", "sweet", "Salt", "Misthan", "Bake Brown", "Burger", "Coffee", "Cafe", "Food", "Zomato", "Swiggy", "Drink", "Barbeque Nation", "CCD", "McDonald's", "Domino's", "Pizza Hut", "Starbucks", "Burger King"],
    "Fuel": ["Petrol", "Diesel", "Fuel", "HPCL", "IOCL", "Bharat Petroleum", "Indian Oil", "Shell", "Fuel Pump"],
    "Entertainment": ["Movie", "Concert", "Cinema", "Club", "Pub", "Bar", "Theater", "PVR", "INOX", "BookMyShow", "Multiplex", "Event"],
    "Health": ["Doctor", "Medications", "Medicos", "Medical", "Hospital", "Apollo", "Max", "Fortis", "Pharmacy", "Pathology", "Lab Test", "Diagnostics", "Health Checkup"],
    "Shopping": ["Clothing", "Sports", "Kerana", "Mart", "Shopping", "Shoes", "Myntra", "Amazon", "Flipkart", "Snapdeal", "Lifestyle", "Shoppers Stop", "Pantaloons", "Zara", "H&M", "Westside"],
    "Unknown": ["Miscellaneous", "Misc", "Uncategorized", "Others", "Unknown"],
    "Faimly": ["Tripathi", "Tiwari"]

  };


  // Categorize a message based on the categories map
  String categorizeMessage(String message) {
    for (var category in categories.keys) {
      for (var keyword in categories[category]!) {
        if (message.toLowerCase().contains(keyword.toLowerCase())) {
          return category;
        }
      }
    }
    return 'Unknown'; // Default category if no match is found
  }

  // Process and categorize messages
  void _processMessages(List<SmsMessage> messages) {
    Map<String, List<SmsMessage>> categorized = {};

    for (var message in messages) {
      String category = categorizeMessage(message.body ?? '');
      if (!categorized.containsKey(category)) {
        categorized[category] = [];
      }
      categorized[category]!.add(message);
    }

    categorizedMessages.value = categorized; // Update state with GetX
  }
//
  // Start polling SMS every 10 seconds
  void _startAutomaticFetching() {
    _timer = Timer.periodic(Duration(seconds: 50), (timer) async {
      var permission = await Permission.sms.status;
      if (permission.isGranted) {
        final messages = await _query.querySms(
          kinds: [
            SmsQueryKind.inbox,
            SmsQueryKind.sent,
          ],
          count: 1000, // Fetch up to 1000 messages
        );
        debugPrint('Total SMS fetched: ${messages.length}');

        // Filter messages based on the specified criteria
        final filteredMessages = messages.where((message) {
          final body = message.body?.toLowerCase() ?? '';
          return (body.contains('credit') || body.contains('debit')) &&
              body.contains('a/c') &&
              body.contains('upi');
        }).toList();

        debugPrint('Filtered messages: ${filteredMessages.length}');
        _processMessages(filteredMessages); // Categorize the filtered messages
      } else {
        await Permission.sms.request();
      }
    });
  }

  @override
  void onInit() {
    super.onInit();
    _startAutomaticFetching(); // Start the automatic fetching when the controller is initialized
  }

  @override
  void onClose() {
    _timer?.cancel(); // Cancel the timer when the controller is closed
    super.onClose();
  }
}

class SmsInboxPage extends StatelessWidget {
  const SmsInboxPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SmsController controller = Get.put(SmsController()); // Initialize the controller

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Inbox Example'),
      ),
      body: Container(
        padding: const EdgeInsets.all(10.0),
        child: Obx(() {
          // Observe changes in the categorizedMessages state
          if (controller.categorizedMessages.isNotEmpty) {
            return _CategorizedMessagesView(categorizedMessages: controller.categorizedMessages);
          } else {
            return Center(
              child: Text(
                'No messages to show.\n Fetching automatically...',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            );
          }
        }),
      ),
    );
  }
}

class _CategorizedMessagesView extends StatelessWidget {
  const _CategorizedMessagesView({
    Key? key,
    required this.categorizedMessages,
  }) : super(key: key);

  final Map<String, List<SmsMessage>> categorizedMessages;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: categorizedMessages.keys.map((category) {
        return ExpansionTile(
          title: Text('$category (${categorizedMessages[category]!.length})'), // Show category name with count
          children: categorizedMessages[category]!
              .map((message) => ListTile(
            title: Text('${message.sender} [${message.date}]'),
            subtitle: Text('${message.body}'),
          ))
              .toList(),
        );
      }).toList(),
    );
  }
}

