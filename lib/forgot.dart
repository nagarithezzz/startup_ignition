import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';
import 'dart:convert';
import 'package:signup/login.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ForgotPasswordVerificationScreen extends StatefulWidget {
  @override
  _ForgotPasswordVerificationScreenState createState() =>
      _ForgotPasswordVerificationScreenState();
}

class _ForgotPasswordVerificationScreenState
    extends State<ForgotPasswordVerificationScreen> {
  TextEditingController emailController = TextEditingController();
  String email = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  email = emailController.text.trim();
                  if (email.isEmpty) {
                    print('Please enter an email address');
                    return;
                  }
                  String apiUrl = 'http://165.232.176.210:5000/resetpassmail';
                  Map<String, String> headers = {
                    'Content-Type': 'application/json'
                  };
                  Map<String, dynamic> body = {'email': email};
                  try {
                    http.Response response = await http.post(
                      Uri.parse(apiUrl),
                      headers: headers,
                      body: jsonEncode(body),
                    );

                    if (response.statusCode == 200) {
                      if (response.body == "Mail Sent!!") {
                        Fluttertoast.showToast(
                          msg: response.body,
                          toastLength: Toast.LENGTH_LONG,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                        );
                        Future.delayed(Duration(seconds: 2), () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginPage()),
                            (Route<dynamic> route) => false,
                          );
                        });
                      } else {
                        Fluttertoast.showToast(
                          msg: response.body,
                          toastLength: Toast.LENGTH_LONG,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                        );
                      }
                    } else {
                      print(
                          'Backend error: ${response.statusCode}, ${response.body}');
                    }
                  } catch (e) {
                    print('Error during HTTP request: $e');
                  }
                },
                child: Text('Send Reset Email'),
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
