import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';

import '../widgets/animations.dart';
import 'menu_page.dart';

class FavTripsPage extends StatefulWidget {
  const FavTripsPage({super.key});

  @override
  _FavTripsPageState createState() => _FavTripsPageState();
}

class _FavTripsPageState extends State<FavTripsPage> {
  final TextEditingController _nationalIDController = TextEditingController();
  late GoogleMapController _controller;
  final Set<Marker> _markers = {};
  late List<LatLng> _routeCoordinates; // Rota koordinatları
  late Polyline _routePolyline; // Rota polyline

  final DatabaseReference _database = FirebaseDatabase(databaseURL: "https://follow-the-txii-default-rtdb.firebaseio.com/").reference();

  @override
  void initState() {
    super.initState();
    _routeCoordinates = [];
    _routePolyline = Polyline(
      polylineId: const PolylineId('route'),
      color: Colors.blue,
      width: 5,
      points: _routeCoordinates,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: LatLng(40.113835, 26.421846),
                zoom: 12,
              ),
              markers: _markers,
              polylines: {_routePolyline}, // Sadece polyline'ı haritaya ekleyin
            ),
          ),
          Positioned(
            top: 50,
            left: 15,
            right: 15,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0), // Köşeleri yuvarlatıyoruz
                  border: Border.all(color: Colors.cyanAccent, width: 2.0), // Kenarlık ekliyoruz
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              SlideLeftRoute(  widget: const NavBar()));
                        },
                        icon: Icon(Icons.arrow_back, color: Colors.black), // Geri ikonu
                      ),
                      Expanded(
                        child: TextField(
                          obscureText: true,
                          controller: _nationalIDController,
                          keyboardType: TextInputType.number,
                          maxLength: 6, // 6 haneli kod için sınırlama
                          decoration: InputDecoration(
                            hintText: 'Rota oluşturma şifresi', // Hint text'i
                            hintStyle: TextStyle(color: Colors.grey), // Hint text'in rengi gri olsun
                            border: InputBorder.none, // TextField'in kendi kenarlığını kaldırıyoruz
                            suffixIcon: IconButton(
                              onPressed: () {
                                _showRoute(); // Butona tıklanınca yapılacak işlemler buraya gelecek
                              },
                              icon: Icon(Icons.send, color: Colors.amber),
                            ),
                            counterText: '', // Girilen karakter sayısını gösteren alt kısmı kaldırıyoruz
                          ),
                          style: TextStyle(color: Colors.black), // Yazı rengi siyah yapılıyor
                          cursorColor: Colors.black, // Cursor rengi siyah yapılıyor
                          onSubmitted: (value) {
                            _showRoute(); // Enter tuşuna basıldığında _showRoute() fonksiyonu çalıştırılıyor
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),





        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
  }

  void _showRoute() {
    String nationalID = _nationalIDController.text;

    _database.child('favorites').orderByChild('national_id').equalTo(nationalID).onValue.listen((event) {
      var snapshot = event.snapshot;
      if (snapshot.value != null) {
        Map<dynamic, dynamic>? values = snapshot.value as Map<dynamic, dynamic>?; // Dönüşüm işlemi
        if (values != null) {
          values.forEach((key, value) {
            List coordinates = value['route']['coordinates'];
            _updateRoute(coordinates); // Rota koordinatlarını güncelle
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu kod ile eşleşen bir rota bulunamadı!')),
        );
      }
    }, onError: (error) {
      print('Hata: $error');
    });
  }





  void _updateRoute(List coordinates) {
    _routeCoordinates.clear(); // Önceki rota koordinatlarını temizleyin
    for (var coordinate in coordinates) {
      double latitude = double.parse(coordinate['latitude'].toString());
      double longitude = double.parse(coordinate['longitude'].toString());
      _routeCoordinates.add(LatLng(latitude, longitude)); // Yeni koordinatları ekle
    }
    _routePolyline = Polyline(
      polylineId: const PolylineId('route'),
      color: Colors.blue,
      width: 5,
      points: _routeCoordinates,
    );
    setState(() {});
  }
}

void main() {
  runApp(const MaterialApp(
    home: FavTripsPage(),
  ));
}
