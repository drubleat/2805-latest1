import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:users_app/pages/users_current_locations_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const displayUserInfo());
}

class displayUserInfo extends StatelessWidget {
  const displayUserInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Realtime Database Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const UserListScreen(),
    );
  }
}

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final databaseReference = FirebaseDatabase(databaseURL: "https://follow-the-txii-default-rtdb.firebaseio.com/").reference();
  List<Map<dynamic, dynamic>> userList = [];

  @override
  void initState() {
    super.initState();
    _getDrivers();
  }

  void _getDrivers() async {
    DatabaseReference ref = databaseReference.child('ilan açan müşteriler');
    DataSnapshot snapshot = await ref.get();
    if (snapshot.value != null) {
      Map<dynamic, dynamic> drivers = Map<dynamic, dynamic>.from(snapshot.value as Map);
      List<Map<dynamic, dynamic>> tempList = [];
      drivers.forEach((key, value) {
        tempList.add(Map<dynamic, dynamic>.from(value));
      });
      setState(() {
        userList = tempList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşteri Listesi'),
      ),
      body: ListView.builder(
        itemCount: userList.length,
        itemBuilder: (context, index) {
          return FutureBuilder<String?>(
            future: GeocodingService.getAddress(
              userList[index]['Müşteri Konum']['latitude'],
              userList[index]['Müşteri Konum']['longitude'],
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(
                  title: Text('Yükleniyor...'),
                );
              } else if (snapshot.hasError) {
                return ListTile(
                  title: Text('Hata: ${snapshot.error}'),
                );
              } else {
                return ListTile(
                  title: Text(userList[index]['Müşteri Ad Soyad']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Şehir Bilgisi: ${userList[index]['Müşteri Şehir Bilgisi']}'),
                      Text('Konum Bilgisi : ${snapshot.data ?? 'Müşteri Konum'}'),
                    ],
                  ),
                );
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MapThatIncUsers(userList: userList)),
          );
        },
        child: const Icon(Icons.map),
      ),
    );
  }
}

class GeocodingService {
  static Future<String?> getAddress(double latitude, double longitude) async {
    const apiKey = "AIzaSyCJyfiuKLbutjuG3NDXMQyPkf2D5OjkCFE"; // Google Maps Geocoding API key
    final url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final results = decoded['results'];
        if (results.isNotEmpty) {
          return results[0]['formatted_address'];
        }
      }
    } catch (e) {
      print('Error getting address: $e');
    }

    return null;
  }
}


