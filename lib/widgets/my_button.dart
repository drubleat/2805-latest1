import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {

  final Function()? onTap;

  const MyButton({super.key,required this.onTap});
  @override
  Widget build(BuildContext context){
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(254, 210, 1, 100),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Center(
          child: Text(
            "Giriş yap",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w400,
              fontSize: 24
            ),
          ),
        ),
      ),
    );
  }
  }
  