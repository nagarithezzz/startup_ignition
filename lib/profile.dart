import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:signup/database_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(ProfileApp());
}

class ProfileApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Profile',
      theme: ThemeData(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        textTheme: TextTheme(
          bodyText1: TextStyle(
            color: Colors.black,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: UserProfile(),
    );
  }
}

class UserProfile extends StatefulWidget {
  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  void _updateUserData() async {
    final dbHelper = DatabaseHelper.instance;

    final updatedUserData = {
      'name': nameController.text,
      'email': emailController.text,
      'phone': phoneController.text,
      'whatsapp_no': whatsappController.text,
      'linkedin': linkedinController.text,
      'designation': designationController.text,
      'company': companyController.text,
      'website': websiteController.text,
      'aboutCompany': aboutCompanyController.text,
      'lookingfor': lookingForController.text,
      'sector': sectorController.text,
      'websiteReview': websiteReviewController.text,
      'additionalInfo': additionalInfoController.text,
      'category': categoryController.text,
      'typeOfStartup': typeOfStartupController.text,
      'city': cityController.text,
      'role': typeOfAccountController.text,
    };
    await dbHelper.updateUserData(1, updatedUserData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile updated successfully')),
    );
    String jsonData = jsonEncode(updatedUserData);
    print(jsonData);
    try {
      final response = await http.post(
        Uri.parse('http://165.232.176.210:5000/updateData'),
        headers: {'Content-Type': 'application/json'},
        body: jsonData,
      );
    } catch (error) {
      print('Error sending data to the server: $error');
    }
  }

  List<Map<String, dynamic>> userDataList = [];
  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    final dbHelper = DatabaseHelper.instance;
    final userMapList = await dbHelper.getAllUserData();
    setState(() {
      userDataList = userMapList;
      if (userDataList.isNotEmpty) {
        print(userDataList.first);
        populateControllers(userDataList.first);
      }
    });
  }

  void populateControllers(Map<String, dynamic> userMap) {
    nameController.text = userMap['name'];
    emailController.text = userMap['email'];
    phoneController.text = userMap['phone'];
    whatsappController.text = userMap['whatsapp_no'];
    linkedinController.text = userMap['linkedin'];
    designationController.text = userMap['designation'];
    companyController.text = userMap['company'];
    websiteController.text = userMap['website'];
    aboutCompanyController.text = userMap['aboutCompany'];
    lookingForController.text = userMap['lookingfor'];
    sectorController.text = userMap['sector'];
    websiteReviewController.text = userMap['websiteReview'];
    additionalInfoController.text = userMap['additionalInfo'];
    categoryController.text = userMap['category'];
    typeOfStartupController.text = userMap['typeOfStartup'];
    cityController.text = userMap['city'];
    typeOfAccountController.text = userMap['role'];
  }

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController whatsappController = TextEditingController();
  TextEditingController linkedinController = TextEditingController();
  TextEditingController designationController = TextEditingController();
  TextEditingController companyController = TextEditingController();
  TextEditingController websiteController = TextEditingController();
  TextEditingController aboutCompanyController = TextEditingController();
  TextEditingController lookingForController = TextEditingController();
  TextEditingController sectorController = TextEditingController();
  TextEditingController websiteReviewController = TextEditingController();
  TextEditingController additionalInfoController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController typeOfStartupController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController typeOfAccountController = TextEditingController();

  bool isEditing = false;

  void _toggleEditing() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.done : Icons.edit),
            onPressed: () {
              if (isEditing) {
                _toggleEditing();
                _updateUserData();
              } else {
                _toggleEditing();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircleAvatar(
                backgroundImage: AssetImage('android/app/images/user.png'),
                radius: 80.0,
              ),
              SizedBox(height: 20.0),
              infoChild(Icons.person, nameController, 'Name'),
              infoChild(Icons.email, emailController, 'Email'),
              infoChild(Icons.phone, phoneController, 'Phone'),
              infoChild(Icons.phone_android, whatsappController, 'WhatsApp'),
              infoChild(Icons.link, linkedinController, 'LinkedIn'),
              infoChild(Icons.work, designationController, 'Designation'),
              infoChild(Icons.business, companyController, 'Company'),
              infoChild(Icons.web, websiteController, 'Website'),
              infoChild(Icons.info, aboutCompanyController, 'About Company'),
              infoChild(Icons.search, lookingForController, 'Looking For'),
              infoChild(Icons.category, sectorController, 'Sector'),
              infoChild(
                  Icons.rate_review, websiteReviewController, 'Website Review'),
              infoChild(
                  Icons.info, additionalInfoController, 'Additional Info'),
              infoChild(Icons.category, categoryController, 'Category'),
              infoChild(
                  Icons.category, typeOfStartupController, 'Startup Type'),
              infoChild(Icons.location_city, cityController, 'City'),
              infoChild(
                  Icons.category, typeOfAccountController, 'Account Type'),
            ],
          ),
        ),
      ),
    );
  }

  Widget infoChild(
      IconData icon, TextEditingController controller, String label) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon,
            color: Colors.black,
            size: 30.0,
          ),
          SizedBox(width: 10.0),
          Expanded(
            child: TextFormField(
              controller: controller,
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.black,
              ),
              readOnly: !isEditing,
            ),
          ),
        ],
      ),
    );
  }
}
