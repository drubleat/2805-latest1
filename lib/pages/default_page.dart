import 'package:flutter/material.dart';

void main() {
  runApp(const defaultPage());
}

class defaultPage extends StatelessWidget {
  const defaultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Boş Sayfa'),
        ),
        body: const Center(
          child: Text(
            'Bu sayfa boş.',
            style: TextStyle(fontSize: 20.0),
          ),
        ),
      ),
    );
  }
}
