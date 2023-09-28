import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:signup/database_helper.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen();

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isVerified = true;
  bool _isEmailSent = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Email Verification'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isEmailSent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 80.0),
                  child: Text(
                    'Please check the link sent your Email ID',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: () async {
                  await DatabaseHelper.instance.database;
                  List<Map<String, dynamic>> allUserData =
                      await DatabaseHelper.instance.getAllUserData();
                  for (var userData in allUserData) {
                    String email = userData['email'];
                    String name = userData['name'];
                    String apiUrl = 'http://165.232.176.210:5000/resend_email';
                    Map<String, String> headers = {
                      'Content-Type': 'application/json'
                    };
                    Map<String, dynamic> body = {'email': email, 'name': name};
                    try {
                      http.Response response = await http.post(
                        Uri.parse(apiUrl),
                        headers: headers,
                        body: jsonEncode(body),
                      );

                      if (response.statusCode == 200) {
                        print('Backend response: ${response.body}');
                      } else {
                        print(
                            'Backend error: ${response.statusCode}, ${response.body}');
                      }
                    } catch (e) {
                      print('Error during HTTP request: $e');
                    }
                  }
                },
                child: Text('Resend Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
