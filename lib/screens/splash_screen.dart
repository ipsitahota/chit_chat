import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:frnds_chat/api/apis.dart';
import 'package:frnds_chat/main.dart';
import 'package:frnds_chat/screens/auth/login_screen.dart';
import 'package:frnds_chat/screens/home_screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge
          );//exit full screen
      SystemChrome.setSystemUIOverlayStyle(
         const SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.white,statusBarColor: Colors.white
          ));//changing the style of top clock and mobile notification bar
      if(APIS.auth.currentUser!=null){
            debugPrint('\nUser:${APIS.auth.currentUser}');
          Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen ()),//navigate to home screen
      );
      }else{
           Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),//navigate to home screen
      );
      }
     
    });
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size; // fits in any mobile of any size

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 197, 192, 198),
               Color.fromARGB(255, 200, 119, 214), // Start color
               // End color
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: mq.height * 0.15,
              left: mq.width * 0.25,
              width: mq.width * 0.5,
              child: Image.asset("images/icon.png"),
            ),
            Positioned(
              bottom: mq.height * 0.15,
              width: mq.width,
              child: Text(
                'MADE IN INDIA WITH 💌',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.purple, // Text color
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
