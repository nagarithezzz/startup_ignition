import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:signup/chat.dart';
import 'package:signup/database_helper.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'dart:convert';
import 'package:connectivity/connectivity.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

String userEmail = '';

class DisplaySuccessStoryPage extends StatefulWidget {
  @override
  _DisplaySuccessStoryPageState createState() =>
      _DisplaySuccessStoryPageState();
}

class _DisplaySuccessStoryPageState extends State<DisplaySuccessStoryPage> {
  Future<String> _getEmail() async {
    final dbHelper = DatabaseHelper.instance;
    final userData = await dbHelper.getAllUserData();

    if (userData.isNotEmpty) {
      userEmail = userData[0]['email'] as String;
      return userData[0]['email'] as String;
    } else {
      userEmail = "email@email.com";
      return "email@email.com";
    }
  }

  List<SuccessStory> users = [];
  List<SuccessStory> filteredUsers = [];
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      var url = Uri.parse('http://165.232.176.210:5000/getusers');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> userList = [];
        String emailToRemove = await _getEmail();
        for (var userData in data) {
          String username = userData[0] as String;
          String email = userData[1] as String;
          String designation = userData[2] as String;
          String website = userData[3] as String;
          String company = userData[4] as String;
          String city = userData[5] as String;

          if (email != emailToRemove) {
            userList.add({
              "username": username,
              "email": email,
              "designation": designation,
              "website": website,
              "company": company,
              "city": city,
            });
          }
        }
        print('Received JSON data:');
        print(userList);

        setState(() {
          users = userList.map((user) => SuccessStory.fromJson(user)).toList();
          filteredUsers = List.from(users);
        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching user data: $error');
    }
  }

  void filterUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredUsers = List.from(users);
      });
    } else {
      setState(() {
        filteredUsers = users.where((user) {
          return user.username.toLowerCase().contains(query.toLowerCase()) ||
              user.email.toLowerCase().contains(query.toLowerCase()) ||
              user.designation.toLowerCase().contains(query.toLowerCase()) ||
              user.company.toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 16.0),
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: ListView.separated(
                  separatorBuilder: (context, index) => Divider(
                    color: Colors.grey,
                    height: 1.0,
                  ),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserDetailsPage(user: user),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 16.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${user.username}',
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${user.designation} at ${user.company}',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserDetailsPage extends StatefulWidget {
  final SuccessStory user;

  UserDetailsPage({required this.user});

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  String buttonStatus = 'Collaborate';
  late ProgressDialog pd;

  @override
  void initState() {
    super.initState();
    pd = ProgressDialog(context: context);
    Future.delayed(Duration.zero, () {
      pd.show(msg: 'Fetching the user...');
      checkFriendStatus();
      fetchpendingfriends().then((_) {
        Future.delayed(Duration(milliseconds: 500), () {
          pd.close();
        });
      });
    });
  }

  Future<void> fetchpendingfriends() async {
    try {
      Map<String, dynamic> requestBody = {
        'email': userEmail,
      };
      var url = Uri.parse('http://165.232.176.210:5000/fetchpendingfriends');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200) {
        var responseBody = response.body;
        if (responseBody.contains(widget.user.email)) {
          setState(() {
            buttonStatus = 'Accept';
          });
        }
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<void> cancelRequest() async {
    try {
      Map<String, dynamic> requestBody = {
        'email': userEmail,
        'frnd_email': widget.user.email,
      };
      var url = Uri.parse('http://165.232.176.210:5000/cancelrequest');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200) {
        var responseBody = response.body;
        if (responseBody == "Success") {
          setState(() {
            buttonStatus = "Collaborate";
          });
        }
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<void> checkFriendStatus() async {
    try {
      Map<String, dynamic> requestBody = {
        'email': userEmail,
        'frnd_email': widget.user.email,
      };
      var url = Uri.parse('http://165.232.176.210:5000/checkfriendStatus');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200) {
        print("SUCCESS");
        var responseBody = response.body;
        if (responseBody == "00") {
          setState(() {
            buttonStatus = 'Pending';
          });
        } else if (responseBody == "0") {
          setState(() {
            buttonStatus = 'Message';
          });
        }
      } else {
        print('Error : ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<void> sendFriendRequest() async {
    if (buttonStatus == 'Collaborate') {
      try {
        Map<String, dynamic> requestBody = {
          'email': userEmail,
          'frnd_email': widget.user.email,
          'status': 'requested',
        };
        var url = Uri.parse('http://165.232.176.210:5000/friend_request');
        var response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        if (response.statusCode == 200) {
          setState(() {
            buttonStatus = 'Pending';
          });
          print('Friend request sent successfully');
        } else {
          print('Error sending friend request: ${response.statusCode}');
        }
      } catch (error) {
        print('Error sending friend request: $error');
      }
    }
  }

  Future<void> unfriend() async {
    if (buttonStatus == "Pending") {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Cancel Collaboration"),
            content:
                Text("Are you sure you want to cancel this collaboration?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("No"),
              ),
              TextButton(
                onPressed: () {
                  cancelRequest();
                  Navigator.of(context).pop();
                },
                child: Text("Yes"),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> chat() async {
    if (buttonStatus == "Message") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatPage()),
      );
    }
  }

  Future<void> accept() async {
    if (buttonStatus == "Accept") {
      acceptfriend();
    }
  }

  Future<void> acceptfriend() async {
    try {
      Map<String, dynamic> requestBody = {
        'email': userEmail,
        'frnd_email': widget.user.email,
      };
      var url = Uri.parse('http://165.232.176.210:5000/acceptfriend');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200) {
        var responseBody = response.body;
        if (responseBody == "Success") {
          setState(() {
            buttonStatus = "Message";
          });
        }
      }
    } catch (error) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Details'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('android/app/images/cover.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 4.0,
                  ),
                  image: DecorationImage(
                    image: AssetImage('android/app/images/user.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.user.username}',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.0),
                Text(
                  '${widget.user.designation} | ${widget.user.company}',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8.0),
                InkWell(
                  onTap: () {
                    _launchURL('${widget.user.website}');
                  },
                  child: Text(
                    '${widget.user.website}',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.blue,
                    ),
                  ),
                ),
                SizedBox(height: 8.0),
                Text(
                  '${widget.user.city}',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.0),
          Container(
            width: double.infinity,
            height: 40,
            margin: EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: () {
                if (buttonStatus == "Collaborate") {
                  sendFriendRequest();
                }
                if (buttonStatus == "Pending") {
                  unfriend();
                }
                if (buttonStatus == "Accept") {
                  accept();
                }
                if (buttonStatus == "Message") {
                  chat();
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: Text(
                buttonStatus,
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }
}

class SuccessStory {
  final String username;
  final String email;
  final String designation;
  final String company;
  final String website;
  final String city;
  SuccessStory({
    required this.username,
    required this.email,
    required this.designation,
    required this.company,
    required this.website,
    required this.city,
  });

  factory SuccessStory.fromJson(Map<String, dynamic> json) {
    return SuccessStory(
      username: json['username'],
      email: json['email'],
      designation: json['designation'],
      company: json['company'],
      website: json['website'],
      city: json['city'],
    );
  }

  void main() {
    runApp(MaterialApp(
      home: DisplaySuccessStoryPage(),
    ));
  }
}
