import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

import '../widgets/animations.dart';
import '../widgets/my_textfield.dart';
import 'drivers_current_locations_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const userAddPersonalInfoToRDB());
}

class userAddPersonalInfoToRDB extends StatelessWidget {
  const userAddPersonalInfoToRDB({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,


      home: const UserAddPersonalInfoToRDB(),
    );
  }
}

class UserAddPersonalInfoToRDB extends StatefulWidget {
  const UserAddPersonalInfoToRDB({super.key});

  @override
  _UserAddPersonalInfoToRDBState createState() => _UserAddPersonalInfoToRDBState();
}

class _UserAddPersonalInfoToRDBState extends State<UserAddPersonalInfoToRDB> {
  final TextEditingController _nameSurnameTextEditingController = TextEditingController();
  final TextEditingController _cityInfoTextEditingController = TextEditingController();
  final TextEditingController _userNationalIDTextEditingController = TextEditingController();
  final databaseReference = FirebaseDatabase(databaseURL: "https://follow-the-txii-default-rtdb.firebaseio.com/").reference();

  void _addNote() async {
    Position position = await _determinePosition();
    databaseReference.child('ilan açan müşteriler').push().set({
      'Müşteri Ad Soyad': _nameSurnameTextEditingController.text,
      'Müşteri Şehir Bilgisi': _cityInfoTextEditingController.text,
      'Müşteri TC Kimlik Numarası': _userNationalIDTextEditingController.text,
      'Müşteri Konum': {
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
        backgroundColor: Colors.amber,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
                context,
                SlideLeftRoute(  widget: const MapThatIncDrivers(driverList: [],)) // MapThatIncDrivers sayfasına yönlendirme
            );
          },
        ),
      ),

      body: Container(
        decoration: BoxDecoration(
          color: Colors.amber, // Amber rengini kullanıyoruz
          image: DecorationImage(
            image: AssetImage("images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: 393,
                  height: 336,
                  child: IconButton(
                    icon: Icon(Icons.taxi_alert), // İstediğiniz bir ikonu buraya ekleyebilirsiniz
                    iconSize: 100, // İkon boyutunu ayarlayabilirsiniz
                    onPressed: () {
                      // İkon butonuna tıklandığında yapılacak işlemler buraya yazılır
                    },
                  ),
                ),

                SizedBox(height: 25),

                Text(
                  'İlan için bilgileri doldurunuz ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 25),

                MyTextField(
                  controller: _nameSurnameTextEditingController,
                  hintText: 'isim Soyisim',
                  obscureText: false,
                ),

                SizedBox(height: 10,),

                MyTextField(
                    controller: _cityInfoTextEditingController,
                    hintText: 'find The taxi şifreniz',
                    obscureText: true
                ),

                SizedBox(height: 10,),
                MyTextField(
                    controller: _userNationalIDTextEditingController,
                    hintText: 'Şehir',
                    obscureText: true
                ),

                SizedBox(height: 10,),
                ElevatedButton(
                  onPressed: () {
                    if(_userNationalIDTextEditingController.text.isNotEmpty)
                      _addNote(); //
                    if(_userNationalIDTextEditingController.text.isNotEmpty)
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MapThatIncDrivers(driverList: [],)), // MapThatIncDrivers sayfasına yönlendirme
                      );


                    if (_userNationalIDTextEditingController.text.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'İlan açma işlemi başarıyla gerçekleştirildi.',
                            style: TextStyle(color: Colors.black), // İçerik metni rengi
                          ),
                          backgroundColor: Colors.amber, // Arka plan rengi
                          behavior: SnackBarBehavior.floating, // Ekranın üstünde yüzen kart gibi görünme
                          action: SnackBarAction(
                            label: 'Kapat',
                            onPressed: () {
                              // Snackbar'ı kapatma işlemi
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            },
                            textColor: Colors.black, // Eylem metni rengi
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'İlan açmak için lütfen bilgileri doldurunuz.',
                            style: TextStyle(color: Colors.black), // İçerik metni rengi
                          ),
                          backgroundColor: Colors.red, // Arka plan rengi
                          behavior: SnackBarBehavior.floating, // Ekranın üstünde yüzen kart gibi görünme
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0), // 8 birimlik radius
                          ),
                          action: SnackBarAction(
                            label: 'Kapat',
                            onPressed: () {
                              // Snackbar'ı kapatma işlemi
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            },
                            textColor: Colors.black, // Eylem metni rengi
                          ),
                        ),

                      );
                    }

                  },

                  child: Text('İlan Aç'),
                ),


              ],
            ),
          ),
        ),
      ),

    );

  }
}
