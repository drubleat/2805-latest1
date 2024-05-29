import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:users_app/authentication/login_screen.dart';
import 'package:users_app/methods/common_methods.dart';

import 'package:users_app/widgets/loading_dialog.dart';
import 'package:users_app/widgets/my_button_1.dart';


import '../pages/drivers_current_locations_page.dart';
import '../widgets/animations.dart';
import '../widgets/my_button.dart';
import '../widgets/my_textfield.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController userNameEditingController = TextEditingController();
  TextEditingController emailEditingController = TextEditingController();
  TextEditingController passwordEditingController = TextEditingController();
  CommonMethods cMethods = CommonMethods();

  void checkIfNetworkIsAvailable() {
    cMethods.checkConnectivity(context);
    signupFormValidation();
  }

  void signupFormValidation() {
    if (userNameEditingController.text.trim().length < 4) {
      cMethods.displaySnackBar("Kullanıcı adınız en az dört karakter olmalı", context);
    } else if (!emailEditingController.text.contains("@")) {
      cMethods.displaySnackBar("Lütfen geçerli bir e-posta giriniz", context);
    } else if (passwordEditingController.text.trim().length < 6) {
      cMethods.displaySnackBar("Şifreniz en az altı karakter olmalı", context);
    } else {
      registerNewUser();
    }
  }

  void registerNewUser() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(mesaggeText: "Hesabınız Kaydediliyor..."),
    );

    try {
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailEditingController.text.trim(),
        password: passwordEditingController.text.trim(),
      );

      final User? userFirebase = userCredential.user;

      if (userFirebase != null) {
        Navigator.pop(context);

        DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users").child(userFirebase.uid);
        Map<String, dynamic> userDataMap = {
          'name': userNameEditingController.text.trim(),
          'email': emailEditingController.text.trim(),
          'id': userFirebase.uid,
          'blockStatus': "no",
        };
        userRef.set(userDataMap);

        Navigator.push(
            context,
            SlideLeftRoute(  widget: const LoginScreen()));
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
                const SizedBox(height: 25),

                const Text(
                  'Hoş geldiniz. Haydi kayıt olalım',
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

                const SizedBox(height: 10,),

                MyTextField(
                    controller: passwordEditingController,
                    hintText: 'Şifre',
                    obscureText: true
                ),

                const SizedBox(height: 50,),


                MyButton1(
                    onTap: registerNewUser
                ),

                const SizedBox(height: 50,),


              ],
            ),
          ),
        ),
      ),
    );
  }
}
