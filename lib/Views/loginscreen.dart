import 'dart:io';

import 'package:calltrackinh/Views/calenderScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool loading  = false;

  void _submit() async {
    setState(() {
      loading = true;
    });

    String name = _nameController.text.trim();
   try {
     if (name.isNotEmpty) {
       FocusManager.instance.primaryFocus?.unfocus();
       var existingUser = await _firestore
           .collection('users')
           .where('username', isEqualTo: name)
           .get();

       if (existingUser.docs.isNotEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Username already exists. Choose another.')),
         );
         setState(() {
           loading = false;
         });
         return;
       }
       DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
       AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
       String userId = DateTime.now().millisecondsSinceEpoch.toString();
       await _firestore.collection('users').doc(userId).set(
         {'id' : userId,'username': name,'deviceId': androidInfo.id,
           'deviceName': androidInfo.model,
           'created_At': DateTime.now().millisecondsSinceEpoch,
           'updated_At': DateTime.now().millisecondsSinceEpoch},);
       await passUserDataToNative(userId,name);
       await saveUserData(userId,name);
       await stopService();
       await startSilentService();

       setState(() {
         loading = false;
       });
     }else{
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Please enter your name')),
       );
       setState(() {
         loading = false;
       });
     }
   }catch (e){
     setState(() {
       loading = false;
     });
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('${e.toString()}')),
     );
   }
  }


  static Future<void> passUserDataToNative(userId, username) async {
    const platform = MethodChannel('com.example.app/service');

    if (userId != null && username != null) {
      try {
        await platform.invokeMethod('saveUserData', {
          'userId': userId,
          'username': username,
        });
        print('User data passed to native side.');
      } catch (e) {
        print('Error passing user data to native: $e');
      }
    } else {
      print('User data not found in SharedPreferences.');
    }
  }

  // Save user ID and name
  Future<void>  saveUserData(String userId, String name) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('userName', name);
  }

  Future<void> startSilentService() async {
    const platform = MethodChannel('com.example.app/service');
    try {
      final result = await platform.invokeMethod('startSilentService');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result}')),
      );
      Navigator.pop(context);
      // exit(0);
    } on PlatformException catch (e) {
      // Handle the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.code}, Message: ${e.message}')),
      );
    }
  }


  Future<void> stopService() async {
    const platform = MethodChannel('com.example.app/service');
    try {
      await platform.invokeMethod('stopService');
    } on PlatformException catch (e) {
      // Handle the error
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Error: ${e.code}, Message: ${e.message}')),
      // );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Enter your name'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: !loading ? Text('Submit') : SizedBox(
                height: 20,
                  width: 20,
                  child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}