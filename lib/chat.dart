import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';

class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Page'),
      ),
      body: Center(
        child: Text('This is the Chat page.'),
      ),
    );
  }
}
