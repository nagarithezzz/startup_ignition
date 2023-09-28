import 'package:flutter/material.dart';
import 'package:signup/chat.dart';
import 'package:connectivity/connectivity.dart';
import 'package:signup/login.dart';
import 'package:signup/database_helper.dart';
import 'package:signup/notifications.dart';
import 'package:signup/story.dart';

import 'package:signup/profile.dart';

void main() async {
  runApp(DashboardApp());
}

class DashboardApp extends StatelessWidget {
  Future<String> _getUserName() async {
    final dbHelper = DatabaseHelper.instance;
    final userData = await dbHelper.getAllUserData();

    if (userData.isNotEmpty) {
      String useremail = userData[0]['email'] as String;
      return userData[0]['name'] as String;
    } else {
      return "Guest";
    }
  }

  void logout(BuildContext context) async {
    await DatabaseHelper.instance.deleteUserTable();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: FutureBuilder<String>(
                future: _getUserName(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Text(
                      'Welcome, ${snapshot.data}',
                      style: const TextStyle(color: Colors.white),
                    );
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile Page'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileApp()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chat Option'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.post_add),
              title: const Text('Create Post'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                logout(context);
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            DashboardItem(
              icon: Icons.search,
              label: 'Search Users',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DisplaySuccessStoryPage()),
                );
              },
            ),
            DashboardItem(
              icon: Icons.person,
              label: 'Profile Page',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileApp()),
                );
              },
            ),
            DashboardItem(
              icon: Icons.chat,
              label: 'Chat',
              onPressed: () {
                // Handle chat action
              },
            ),
            DashboardItem(
              icon: Icons.settings,
              label: 'Settings',
              onPressed: () {
                // Handle settings action
              },
            ),
            DashboardItem(
              icon: Icons.help,
              label: 'Help Desk',
              onPressed: () {
                // Handle help desk action
              },
            ),
            DashboardItem(
              icon: Icons.calendar_today,
              label: 'Calendar',
              onPressed: () {
                // Handle calendar action
              },
            ),
            DashboardItem(
              icon: Icons.notifications,
              label: 'Notifications',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          NotificationsPage()), // Navigate to the NotificationsPage
                );
              },
            ),
            DashboardItem(
              icon: Icons.post_add,
              label: 'Create Post',
              onPressed: () {
                // Handle create post action
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  DashboardItem({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
