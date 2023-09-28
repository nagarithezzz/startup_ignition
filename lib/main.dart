import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signup/dashboard.dart';
import 'firebase_options.dart';
import 'package:signup/login.dart';
import 'package:connectivity/connectivity.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:signup/database_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:signup/verify.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  runApp(MaterialApp(
    home: SplashScreen(),
  ));
}

class LoginOrRegisterScreen extends StatefulWidget {
  @override
  _LoginOrRegisterScreenState createState() => _LoginOrRegisterScreenState();
}

class _LoginOrRegisterScreenState extends State<LoginOrRegisterScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('StartUp Ignition'),
      ),
      body: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.topCenter,
            child: Image.asset(
              'android/app/images/startup_ignition.jpeg',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height *
                0.25, // Adjust the position
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue,
                          Colors.blueAccent
                        ], // Gradient colors
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(30), // Adjust the corner radius
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignUpPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        primary:
                            Colors.transparent, // Transparent background color
                        onPrimary: Colors.white, // Text color
                        padding: EdgeInsets.symmetric(
                          vertical: 16, // Adjust the vertical padding
                          horizontal: 24, // Adjust the horizontal padding
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero, // No button border
                        ),
                        elevation: 0, // No elevation
                      ),
                      child: Text('Register'),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue,
                          Colors.blueAccent
                        ], // Gradient colors
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(30), // Adjust the corner radius
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.transparent,
                        onPrimary: Colors.white, // Text color
                        padding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        elevation: 0,
                      ),
                      child: Text('Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int userDataCount = 0;
  int _completedSpins = 0;
  int _desiredSpins = 5;
  double _startingSize = 0.25;
  double _endingSize = 0.50;

  Future<void> getUserDataCount() async {
    try {
      int? count = await DatabaseHelper.instance.getUserDataCount();
      setState(() {
        userDataCount = count ?? 0;
      });

      if (userDataCount == 1) {
        await DatabaseHelper.instance.database;
        List<Map<String, dynamic>> allUserData =
            await DatabaseHelper.instance.getAllUserData();
        for (var userData in allUserData) {
          String email = userData['email'];
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

              if (isVerified) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardApp()),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => VerificationScreen()),
                );
              }
            } else {
              print('Backend error: ${response.statusCode}, ${response.body}');
            }
          } catch (e) {
            print('Error during HTTP request: $e');
          }
        }
      } else if (userDataCount == 0) {
        Timer(Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginOrRegisterScreen()),
          );
        });
      } else {
        Fluttertoast.showToast(
          msg:
              'Multiple Users found!! You are not allowed to proceed further.. Please Clear the data and restart the application',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        Future.delayed(Duration(seconds: 5), () {
          exit(0);
        });
      }
    } catch (error) {
      print('Error fetching user data count: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    getUserDataCount();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _completedSpins++;
          if (_completedSpins >= _desiredSpins) {
            _controller.stop();
            Timer(Duration(seconds: 2), () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SignUpPage()),
              );
            });
          } else {
            _controller.reset();
            _startingSize = _endingSize;
            _endingSize += 0.25;
            _controller.forward();
          }
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            double scaleFactor = _startingSize +
                (_endingSize - _startingSize) * _controller.value;
            return Transform.scale(
              scale: scaleFactor,
              child: RotationTransition(
                turns: _controller,
                child: Image(
                  image: AssetImage('android/app/images/startup_ignition.jpeg'),
                  width: 200,
                  height: 200,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SignUpApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SignUpPage(),
    );
  }
}

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  int currentStep = 0;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  TextEditingController _accountTypeController = TextEditingController();
  TextEditingController _whatsappNumberController = TextEditingController();
  TextEditingController _linkedinProfileController = TextEditingController();
  TextEditingController _designationController = TextEditingController();
  TextEditingController _companyController = TextEditingController();
  TextEditingController _websiteController = TextEditingController();

  TextEditingController _aboutCompanyController = TextEditingController();
  TextEditingController _lookingForController = TextEditingController();
  TextEditingController _sectorController = TextEditingController();
  TextEditingController _websiteReviewController = TextEditingController();

  TextEditingController _additionalInfoController = TextEditingController();
  TextEditingController _categoryController = TextEditingController();
  TextEditingController _typeOfStartupController = TextEditingController();
  TextEditingController _cityController = TextEditingController();
  PageController _pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Column(
        children: [
          Container(
            height: 120,
            child: Stepper(
              currentStep: currentStep,
              onStepTapped: (step) {
                setState(() {
                  currentStep = step;
                  _pageController.animateToPage(
                    step,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.ease,
                  );
                });
              },
              type: StepperType.horizontal,
              steps: [
                Step(
                  title: Text(
                    'Step 1',
                    style: TextStyle(
                      color: currentStep >= 0 ? Colors.blue : Colors.black,
                    ),
                  ),
                  state:
                      currentStep >= 0 ? StepState.complete : StepState.indexed,
                  content: SizedBox(),
                ),
                Step(
                  title: Text(
                    'Step 2',
                    style: TextStyle(
                      color: currentStep >= 1 ? Colors.blue : Colors.black,
                    ),
                  ),
                  state:
                      currentStep >= 1 ? StepState.complete : StepState.indexed,
                  content: SizedBox(),
                ),
                Step(
                  title: Text(
                    'Step 3',
                    style: TextStyle(
                      color: currentStep >= 2 ? Colors.blue : Colors.black,
                    ),
                  ),
                  state:
                      currentStep >= 2 ? StepState.complete : StepState.indexed,
                  content: SizedBox(),
                ),
                Step(
                  title: Text(
                    'Step 4',
                    style: TextStyle(
                      color: currentStep >= 3 ? Colors.blue : Colors.black,
                    ),
                  ),
                  state:
                      currentStep >= 3 ? StepState.complete : StepState.indexed,
                  content: SizedBox(),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              children: [
                StepPage(
                  page: 1,
                  content: FirstPage(
                    nameController: _nameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                  ),
                  pageController: _pageController,
                ),
                StepPage(
                  page: 2,
                  content: SecondPage(
                    accountTypeController: _accountTypeController,
                    whatsappNumberController: _whatsappNumberController,
                    linkedinProfileController: _linkedinProfileController,
                    designationController: _designationController,
                    companyController: _companyController,
                    websiteController: _websiteController,
                  ),
                  pageController: _pageController,
                ),
                StepPage(
                  page: 3,
                  content: ThirdPage(
                      aboutCompanyController: _aboutCompanyController,
                      lookingForController: _lookingForController,
                      sectorController: _sectorController,
                      websiteReviewController: _websiteReviewController),
                  pageController: _pageController,
                ),
                StepPage(
                  page: 4,
                  content: FourthPage(
                      additionalInfoController: _additionalInfoController,
                      categoryController: _categoryController,
                      typeOfStartupController: _typeOfStartupController,
                      cityController: _cityController),
                  pageController: _pageController,
                ),
              ],
            ),
          ),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          if (currentStep > 0)
            ElevatedButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.ease,
                );
                setState(() {
                  currentStep--;
                });
              },
              child: Text('Back'),
            ),
          if (currentStep < 3)
            ElevatedButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.ease,
                );
                setState(() {
                  currentStep++;
                });
              },
              child: Text('Next'),
            ),
          if (currentStep == 3)
            ElevatedButton(
              onPressed: () async {
                bool _isVerified = false;
                ProgressDialog pd = ProgressDialog(context: context);

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
                String name = _nameController.text;
                String email = _emailController.text;
                String phone = _phoneController.text;
                String password = _passwordController.text;

                String accountType = _accountTypeController.text;
                String whatsappNumber = _whatsappNumberController.text;
                String linkedinProfile = _linkedinProfileController.text;
                String designation = _designationController.text;
                String company = _companyController.text;
                String website = _websiteController.text;

                String aboutCompany = _aboutCompanyController.text;
                String lookingFor = _lookingForController.text;
                String sector = _sectorController.text;
                String websiteReview = _websiteReviewController.text;

                String additionalInfo = _additionalInfoController.text;
                String category = _categoryController.text;
                String typeOfStartup = _typeOfStartupController.text;
                String city = _cityController.text;

                Signup newSignup = Signup(
                  email: email,
                  name: name,
                  phone: "+91" + phone,
                  accountType: accountType,
                  whatsappNumber: whatsappNumber,
                  linkedinProfile: linkedinProfile,
                  designation: designation,
                  password: password,
                  company: company,
                  website: website,
                  aboutCompany: aboutCompany,
                  lookingFor: lookingFor,
                  sector: sector,
                  websiteReview: websiteReview,
                  additionalInfo: additionalInfo,
                  category: category,
                  typeOfStartup: typeOfStartup,
                  city: city,
                  isVerified: _isVerified,
                  fcmtoken: fcmToken,
                );

                String jsonData = jsonEncode(newSignup.toJson());
                print(jsonData);
                String url = 'http://165.232.176.210:5000/create';
                pd.show(msg: 'Creating your Account....');
                Map<String, String> headers = {
                  'Content-Type': 'application/json'
                };
                try {
                  Uri uri = Uri.parse(url);
                  http.Response response =
                      await http.post(uri, headers: headers, body: jsonData);
                  if (response.statusCode == 200) {
                    String message = response.body;
                    if (message == 'Successfully Registered And mail sent!!!') {
                      pd.close();
                      Fluttertoast.showToast(
                        msg: message,
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.green,
                        textColor: Colors.white,
                      );
                      try {
                        int rowId =
                            await DatabaseHelper.instance.insertUserData(
                          email: email,
                          name: name,
                          phone: "+91" + phone,
                          whatsappNumber: whatsappNumber,
                          linkedinProfile: linkedinProfile,
                          designation: designation,
                          company: company,
                          website: website,
                          aboutCompany: aboutCompany,
                          lookingFor: lookingFor,
                          sector: sector,
                          websiteReview: websiteReview,
                          additionalInfo: additionalInfo,
                          category: category,
                          typeOfStartup: typeOfStartup,
                          city: city,
                          role: accountType,
                          isVerified: _isVerified,
                        );
                        print('Data inserted with row id: $rowId');
                      } catch (error) {
                        print('Error inserting data: $error');
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VerificationScreen(),
                        ),
                      );
                    } else {
                      pd.close();
                      Fluttertoast.showToast(
                        msg: message,
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                    }
                  } else {
                    pd.close();
                    print(
                        'Failed to send data. Status code: ${response.statusCode}');
                  }
                } catch (error) {
                  print('Error: $error');
                }
              },
              child: Text('Sign Up'),
            ),
        ],
      ),
    );
  }
}

class StepPage extends StatelessWidget {
  final int page;
  final Widget content;
  final PageController pageController;

  StepPage({
    required this.page,
    required this.content,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: content),
        ],
      ),
    );
  }
}

class FirstPage extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  FirstPage({
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildTextField('Name *', nameController),
              _buildTextField('Email *', emailController),
              _buildTextField('Phone *', phoneController),
              _buildTextField('Password *', passwordController),
              _buildTextField('Confirm Password *', confirmPasswordController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String labelText, TextEditingController controller) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.blue,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          contentPadding: EdgeInsets.all(10),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  final TextEditingController accountTypeController;
  final TextEditingController whatsappNumberController;
  final TextEditingController linkedinProfileController;
  final TextEditingController designationController;
  final TextEditingController companyController;
  final TextEditingController websiteController;
  SecondPage({
    required this.accountTypeController,
    required this.whatsappNumberController,
    required this.linkedinProfileController,
    required this.designationController,
    required this.companyController,
    required this.websiteController,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildTextField('Account Type', accountTypeController),
              _buildTextField('Whatsapp Number', whatsappNumberController),
              _buildTextField('Linkedin Profile', linkedinProfileController),
              _buildTextField('Designation', designationController),
              _buildTextField('Company ', companyController),
              _buildTextField('Website', websiteController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String labelText, TextEditingController controller) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.blue,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          contentPadding: EdgeInsets.all(10),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class ThirdPage extends StatelessWidget {
  final TextEditingController aboutCompanyController;
  final TextEditingController lookingForController;
  final TextEditingController sectorController;
  final TextEditingController websiteReviewController;

  ThirdPage({
    required this.aboutCompanyController,
    required this.lookingForController,
    required this.sectorController,
    required this.websiteReviewController,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildTextField('About Company', aboutCompanyController),
              _buildTextField('Looking For', lookingForController),
              _buildTextField('Sector', sectorController),
              _buildTextField('Website Review', websiteReviewController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String labelText, TextEditingController controller) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.blue,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          contentPadding: EdgeInsets.all(10),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class FourthPage extends StatelessWidget {
  final TextEditingController additionalInfoController;
  final TextEditingController categoryController;
  final TextEditingController typeOfStartupController;
  final TextEditingController cityController;

  FourthPage({
    required this.additionalInfoController,
    required this.categoryController,
    required this.typeOfStartupController,
    required this.cityController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildTextField(
                  'Additional Information', additionalInfoController),
              _buildTextField('Category', categoryController),
              _buildTextField('Type Of Startup', typeOfStartupController),
              _buildTextField('City', cityController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String labelText, TextEditingController controller) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.blue,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          contentPadding: EdgeInsets.all(10),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class Signup {
  final String phone;
  final String email;
  final String name;
  final String whatsappNumber;
  final String linkedinProfile;
  final String designation;
  final String company;
  final String website;
  final String accountType;
  final String aboutCompany;
  final String lookingFor;
  final String sector;
  final String websiteReview;
  final String password;
  final String additionalInfo;
  final String category;
  final String typeOfStartup;
  final String city;
  final bool isVerified;
  final String fcmtoken;

  Signup({
    required this.phone,
    required this.email,
    required this.name,
    required this.accountType,
    required this.whatsappNumber,
    required this.linkedinProfile,
    required this.designation,
    required this.company,
    required this.website,
    required this.aboutCompany,
    required this.lookingFor,
    required this.password,
    required this.sector,
    required this.websiteReview,
    required this.additionalInfo,
    required this.category,
    required this.typeOfStartup,
    required this.city,
    required this.isVerified,
    required this.fcmtoken,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'whatsappNumber': whatsappNumber,
      'linkedinProfile': linkedinProfile,
      'designation': designation,
      'company': company,
      'website': website,
      'password': password,
      'aboutCompany': aboutCompany,
      'accountType': accountType,
      'lookingFor': lookingFor,
      'sector': sector,
      'websiteReview': websiteReview,
      'additionalInfo': additionalInfo,
      'category': category,
      'typeOfStartup': typeOfStartup,
      'city': city,
      'isVerified': isVerified,
      'fcmtoken': fcmtoken,
    };
  }
}
