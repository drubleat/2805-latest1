import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const driverAddPersonalInfoToRDB());
}

class driverAddPersonalInfoToRDB extends StatelessWidget {
  const driverAddPersonalInfoToRDB({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SÜRÜCÜ İLAN ACMA',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DriverAddPersonalInfoToRDB(),
    );
  }
}

class DriverAddPersonalInfoToRDB extends StatefulWidget {
  const DriverAddPersonalInfoToRDB({super.key});

  @override
  _DriverAddPersonalInfoToRDBState createState() => _DriverAddPersonalInfoToRDBState();
}

class _DriverAddPersonalInfoToRDBState extends State<DriverAddPersonalInfoToRDB> {
  final TextEditingController _nameSurnameTextEditingController = TextEditingController();
  final TextEditingController _vehicleModelTextEditingController = TextEditingController();
  final TextEditingController _vehicleLicanceTextEditingController = TextEditingController();
  final TextEditingController _cityInfoTextEditingController = TextEditingController();
  final TextEditingController _driverNationalIDTextEditingController = TextEditingController();
  final databaseReference = FirebaseDatabase(databaseURL: "https://follow-the-txii-default-rtdb.firebaseio.com/").reference();

  void _addNote() async {
    Position position = await _determinePosition();
    databaseReference.child('ilan açan sürücüler').push().set({
      'Ad Soyad': _nameSurnameTextEditingController.text,
      'Araba Modeli': _vehicleModelTextEditingController.text,
      'Araba Plakası': _vehicleLicanceTextEditingController.text,
      'Şehir Bilgisi': _cityInfoTextEditingController.text,
      'TC Kimlik Numarası': _driverNationalIDTextEditingController.text,
      'Konum': {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameSurnameTextEditingController,
              decoration: const InputDecoration(
                labelText: 'İsim Soyisim:',
              ),
            ),
            TextField(
              controller: _vehicleModelTextEditingController,
              decoration: const InputDecoration(
                labelText: 'Araba Modeli:',
              ),
            ),
            TextField(
              controller: _vehicleLicanceTextEditingController,
              decoration: const InputDecoration(
                labelText: 'Plakanız:',
              ),
            ),
            TextField(
              controller: _driverNationalIDTextEditingController,
              decoration: const InputDecoration(
                labelText: 'TC Kimlik Numaranız:',
              ),
            ),


            TextField(
              controller: _cityInfoTextEditingController,
              decoration: const InputDecoration(
                labelText: 'Şehir Bilgisi:',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addNote,
              child: const Text('Sürücü Bilgilerini Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}
