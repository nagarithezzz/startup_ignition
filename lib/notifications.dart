import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:signup/database_helper.dart';
import 'package:connectivity/connectivity.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<String> notificationList = [];
  @override
  void initState() {
    super.initState();
    fetchDataAndSendEmails();
  }

  Future<void> fetchDataAndSendEmails() async {
    await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> allUserData =
        await DatabaseHelper.instance.getAllUserData();
    for (var userData in allUserData) {
      String email = userData['email'];
      String apiUrl = 'http://165.232.176.210:5000/fetchnotifs';
      Map<String, String> headers = {'Content-Type': 'application/json'};
      Map<String, dynamic> body = {'email': email};
      try {
        http.Response response = await http.post(
          Uri.parse(apiUrl),
          headers: headers,
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          List<dynamic> responseList = jsonDecode(response.body);
          setState(() {
            notificationList = List<String>.from(responseList);
          });
          print('Backend response: ${response.body}');
        } else {
          print('Backend error: ${response.statusCode}, ${response.body}');
        }
      } catch (e) {
        print('Error during HTTP request: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: ListView.builder(
        itemCount: notificationList.length,
        itemBuilder: (context, index) {
          return NotificationCard(
            notificationText: notificationList[index],
            itemIndex: index,
            onItemRemoved: () {
              setState(() {
                notificationList.removeAt(index);
              });
            },
          );
        },
      ),
    );
  }
}

class NotificationCard extends StatefulWidget {
  final String notificationText;
  final int itemIndex;
  final VoidCallback? onItemRemoved;
  const NotificationCard({
    required this.notificationText,
    required this.itemIndex,
    this.onItemRemoved,
  });

  @override
  _NotificationCardState createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  bool _isExpanded = false;
  late int _itemIndex;
  void sendDataToUrl(String action) async {
    await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> allUserData =
        await DatabaseHelper.instance.getAllUserData();
    for (var userData in allUserData) {
      String email = userData['email'];
      String apiUrl = 'http://165.232.176.210:5000/friendaction';
      Map<String, String> headers = {'Content-Type': 'application/json'};
      Map<String, dynamic> body = {
        'itemIndex': widget.itemIndex,
        'action': action,
        'email': email,
      };
      try {
        http.Response response = await http.post(
          Uri.parse(apiUrl),
          headers: headers,
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          print('Response from server: ${response.body}');
        } else {
          print('Server error: ${response.statusCode}, ${response.body}');
        }
      } catch (e) {
        print('Error during HTTP request: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.all(16),
            title: Text(widget.notificationText),
            leading: Icon(Icons.person_2),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          if (_isExpanded)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        sendDataToUrl('accept');
                        print(
                            'Accept pressed for item at index: ${widget.itemIndex}');
                        widget.onItemRemoved?.call();
                        setState(() {
                          // Close the expanded view
                          _isExpanded = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.green,
                      ),
                      child: Text('Accept'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        sendDataToUrl('decline');
                        print(
                            'Decline pressed for item at index: ${widget.itemIndex}');
                        widget.onItemRemoved?.call();
                        setState(() {
                          _isExpanded = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.red,
                      ),
                      child: Text('Decline'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
