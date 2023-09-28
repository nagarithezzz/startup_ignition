import 'dart:convert';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:connectivity/connectivity.dart';
import 'package:signup/dashboard.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'package:signup/database_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:signup/verify.dart';
import 'package:signup/main.dart';
import 'package:signup/forgot.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final double headingFontSize =
        1.7 * Theme.of(context).textTheme.headline6!.fontSize!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: ListView(
          padding: EdgeInsets.all(16.0),
          shrinkWrap: true,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Login',
                style: TextStyle(
                  fontSize: headingFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _login,
                child: Text('Login'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 8.0),
            SizedBox(height: 8.0),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ForgotPasswordVerificationScreen()),
                );
              },
              child: Text('Forgot Password?'),
            ),
          ],
        ),
      ),
    );
  }

  void _login() async {
    String email = _emailController.text;
    String password = _passwordController.text;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final fcmToken = await FirebaseMessaging.instance.getToken();
    print("Token is " + fcmToken!);
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
      print("Token is " + fcmToken);
    }).onError((err) {
      print("Error is " + err);
    });

    Login loginData =
        Login(email: email, password: password, fcmtoken: fcmToken);

    String jsonData = json.encode(loginData.toJson());

    Uri url = Uri.parse('http://165.232.176.210:5000/login');
    ProgressDialog pd = ProgressDialog(context: context);
    pd.show(msg: "Logging you in...");
    try {
      http.Response response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonData,
      );

      if (response.statusCode == 200) {
        String message = response.body;
        if (message == "Password is incorrect") {
          pd.close();
          Fluttertoast.showToast(
            msg: message,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        } else if (message == "Email doesn't exist!!") {
          pd.close();
          Fluttertoast.showToast(
            msg: message,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        } else {
          Map<String, dynamic> userData = jsonDecode(message);
          int id = await DatabaseHelper.instance.insertUserData(
            email: userData['email'],
            name: userData['name'],
            phone: userData['phone'],
            whatsappNumber: userData['whatsapp_no'],
            linkedinProfile: userData['linkedin'],
            designation: userData['designation'],
            company: userData['company'],
            website: userData['website'],
            aboutCompany: userData['aboutCompany'],
            lookingFor: userData['lookingfor'],
            sector: userData['sector'],
            websiteReview: userData['websiteReview'],
            additionalInfo: userData['additionalInfo'],
            category: userData['category'],
            typeOfStartup: userData['typeOfStartup'],
            city: userData['city'],
            role: userData['role'],
            isVerified: userData['is_verified'],
          );

          if (id != null) {
            print('User data inserted into the database with ID: $id');
            String apiUrl = 'http://165.232.176.210:5000/check_verified';
            Map<String, String> headers = {'Content-Type': 'application/json'};
            Map<String, dynamic> body = {'email': email};
            try {
              http.Response response = await http.post(
                Uri.parse(apiUrl),
                headers: headers,
                body: jsonEncode(body),
              );

              if (response.statusCode == 200) {
                print('Backend response: ${response.body}');

                bool isVerified = response.body == 'True';

                await DatabaseHelper.instance
                    .updateIsVerifiedStatus(email, isVerified);
                pd.close();
                if (isVerified) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => DashboardApp()),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => VerificationScreen()),
                  );
                }
              } else {
                print(
                    'Backend error: ${response.statusCode}, ${response.body}');
              }
            } catch (e) {
              print('Error during HTTP request: $e');
            }
          } else {
            print('Failed to insert user data into the database.');
          }
        }
      } else {
        print('Server not running');
      }
    } catch (error) {
      print('Error: $error');
    }
  }
}

class Login {
  String email;
  String password;
  String fcmtoken;
  Login({required this.email, required this.password, required this.fcmtoken});

  factory Login.fromJson(Map<String, dynamic> json) {
    return Login(
      email: json['email'],
      password: json['password'],
      fcmtoken: json['fcmtoken'],
    );
  }

  Map<String, dynamic> toJson() => {
        "email": email,
        "password": password,
        "fcmtoken": fcmtoken,
      };
}
