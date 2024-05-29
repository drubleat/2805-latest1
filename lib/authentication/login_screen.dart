import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:users_app/authentication/signup_screen.dart';
import 'package:users_app/methods/common_methods.dart';

import 'package:users_app/widgets/loading_dialog.dart';
import 'package:users_app/widgets/my_button_1.dart';

import '../pages/drivers_current_locations_page.dart';
import '../widgets/animations.dart';
import '../widgets/my_button.dart';
import '../widgets/my_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailEditingController = TextEditingController();
  TextEditingController passwordEditingController = TextEditingController();
  CommonMethods cMethods = CommonMethods();

  void checkIfNetworkIsAvailable() {
    cMethods.checkConnectivity(context);
    signinFormValidation();
  }

  void signinFormValidation() {
    if (!emailEditingController.text.contains("@")) {
      cMethods.displaySnackBar("Lütfen geçerli bir e-posta giriniz", context);
    } else if (passwordEditingController.text.trim().length < 6) {
      cMethods.displaySnackBar("Şifreniz en az altı karakter olmalı", context);
    } else {
      signInUser();
    }
  }

  void signInUser() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(mesaggeText: "Giriş yapılıyor..."),
    );

    try {
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailEditingController.text.trim(),
        password: passwordEditingController.text.trim(),
      );

      final User? userFirebase = userCredential.user;

      if (userFirebase != null) {
        DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users").child(userFirebase.uid);
        userRef.once().then((snap) {
          if (snap.snapshot.value != null) {
            if ((snap.snapshot.value as Map)["blockStatus"] == "no") {
              // Kullanıcı adını burada almayı unutmuş olabilirsiniz.
              // userName = (snap.snapshot.value as Map)["name"];
              Navigator.push(
                  context,
                  SlideLeftRoute(  widget: const MapThatIncDrivers(driverList: [],)));
            } else {
              FirebaseAuth.instance.signOut();
              cMethods.displaySnackBar("Hesabınız geçici süreliğine kapatılmıştır", context);
            }
          } else {
            FirebaseAuth.instance.signOut();
            cMethods.displaySnackBar("Kullanıcı kaydınız bulunamadı", context);
          }
        });
      }
    } catch (error) {
      Navigator.pop(context);
      cMethods.displaySnackBar(error.toString(), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(image: DecorationImage(image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover
        )
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: 393,
                  height: 336,
                  decoration: const BoxDecoration(image: DecorationImage(image: AssetImage("assets/images/nblogo.png"),
                      fit: BoxFit.cover
                  ),
                  ),
                ),
                const SizedBox(height: 50),
                //welcome back, you have been missed
                const Text(
                  'Hoş geldiniz giriş yapabilirsiniz',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 25),

                MyTextField(
                  controller: emailEditingController,
                  hintText: 'E-mail',
                  obscureText: false,
                ),
                const SizedBox(height: 10),

                MyTextField(
                  controller: passwordEditingController,
                  hintText: 'Şifre',
                  obscureText: true,
                ),

                const SizedBox(height: 50,),

                MyButton(
                    onTap: signInUser
                ),

                const SizedBox(height: 50,),



                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Üye değilmisiniz",
                      style: TextStyle(color: Colors.black),

                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignUpScreen()),
                          // Navigate to register page action
                        );
                      },
                      child: const Text(
                        'Şimdi üye ol',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
