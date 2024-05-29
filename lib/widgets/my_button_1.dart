import 'package:flutter/material.dart';

class MyButton1 extends StatelessWidget {

  final Function()? onTap;

  const MyButton1({super.key,required this.onTap});
  @override
  Widget build(BuildContext context){
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
          color:  Colors.amberAccent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Center(
          child: Text(
            "Kayıt Ol",
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