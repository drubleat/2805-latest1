import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:location/location.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:users_app/pages/user_add_personalInfoToRDB.dart';
import 'package:users_app/pages/users_current_locations_page.dart';

import '../widgets/animations.dart';
import 'driverViewRouteScreen.dart';
import 'menu_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapThatIncDrivers(driverList: []), // Bu örnekte driverList boş
    );
  }
}

class MapThatIncDrivers extends StatefulWidget {
  final List driverList;

  const MapThatIncDrivers({super.key, required this.driverList});

  @override
  _MapThatIncDriversState createState() => _MapThatIncDriversState();
}

class _MapThatIncDriversState extends State<MapThatIncDrivers> {
  late GoogleMapController _controller;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  late Location _location;
  late LatLng _currentPosition;
  LatLng? startPoint;
  LatLng? destPoint;
  final TextEditingController _typeAheadController = TextEditingController();
  final TextEditingController _nationalIDController = TextEditingController();

  double? totalDistance;
  List<LatLng> routeCoordinates = [];

  String? selectedDriverName;
  LatLng? selectedDriverPosition;
  String? selectedDriverCarModel;
  String? selectedDriverNationalID;

  @override
  void initState() {
    super.initState();
    _location = Location();
    _getCurrentLocation();
  }
  void _uploadRouteToDatabase() {
    if (routeCoordinates.isNotEmpty && selectedDriverName != null && selectedDriverNationalID != null) {
      final routeData = {
        'driver_name': selectedDriverName,
        'national_id': selectedDriverNationalID,
        'start': {
          'latitude': routeCoordinates.first.latitude,
          'longitude': routeCoordinates.first.longitude,
        },
        'end': {
          'latitude': routeCoordinates.last.latitude,
          'longitude': routeCoordinates.last.longitude,
        },
        'coordinates': routeCoordinates.map((e) => {'latitude': e.latitude, 'longitude': e.longitude}).toList(),
        'total_distance': totalDistance,
      };

      _database.child('favorites').push().set(routeData).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rota favorilere eklendi!')),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Favorilere ekleme sırasında hata oluştu: $error')),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TC Kimlik Numarasını girin ve rota oluşturun!')),
      );
    }
  }


  // Firebase Realtime Database referansı
  final DatabaseReference _database = FirebaseDatabase(databaseURL: "https://follow-the-txii-default-rtdb.firebaseio.com/").reference();

  @override
  Widget build(BuildContext context) {
    int selectedIndex;
    return Scaffold(

      drawer: Drawer(
        child: selectedDriverName != null ? _buildDriverInfoDrawer() : const Center(child: Text('Sürücü Seçin')),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(40.113835, 26.421846),
              zoom: 12,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {

                    });
                  },
                  child: GNav(
                    backgroundColor: Colors.white,
                    color: Colors.black,
                    activeColor: Colors.black,
                    tabBackgroundColor: Colors.amber.shade300,
                    gap: 4,
                    selectedIndex: selectedIndex = 1,
                    onTabChange: (index) {
                      // Search butonuna tıklandığında yönlendirme işlemi
                      if (index == 0) {
                        setState(() {
                          selectedIndex = index; // Seçili indeksi güncelleyin

                        });

                      }
                      else if (index == 1) {
                        setState(() {
                          selectedIndex = index; // Seçili indeksi güncelleyin


                        });

                      }
                      else if (index == 2) {
                        setState(() {
                          selectedIndex = index; // Seçili indeksi güncelleyin
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => userAddPersonalInfoToRDB()),
                        );
                      }

                    },
                    padding: const EdgeInsets.all(20),
                    tabBorderRadius: 0,
                    tabs: const [
                      GButton(
                        icon: Icons.route,
                        text: 'Rota',
                      ),
                      GButton(
                        icon: Icons.home,
                        text: 'Ana Menü',
                      ),
                      GButton(
                        icon: Icons.local_taxi_outlined,
                        text: 'İlan',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),




          Positioned(
            top: 50,
            left: 15,
            right: 15,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, // Arka planı beyaz yapar
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: TypeAheadField(
                      textFieldConfiguration: TextFieldConfiguration(
                        controller: _typeAheadController,
                        decoration: InputDecoration(
                          hintStyle: const TextStyle(color: Colors.grey),
                          hintText: 'Adres ara',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: () {
                              Navigator.push(
                                context,
                                SlideRightRoute(  widget: const NavBar()),
                              );
                            },
                          ),

                        ),
                      ),
                      suggestionsCallback: (pattern) async {
                        return await _getSuggestions(pattern);
                      },
                      itemBuilder: (context, suggestion) {
                        return Container(
                          color: Colors.white, // ListTile'ın arka planını beyaz yapar
                          child: ListTile(
                            title: Text(
                              suggestion['description'],
                              style: const TextStyle(color: Colors.black), // Tüm metinleri siyah yapar
                            ),
                          ),
                        );
                      },
                      onSuggestionSelected: (suggestion) async {
                        _typeAheadController.text = suggestion['description'];
                        var placeId = suggestion['place_id'];
                        var details = await _getPlaceDetails(placeId);
                        setState(() {
                          destPoint = LatLng(details['lat'], details['lng']);
                        });
                        _controller.animateCamera(
                          CameraUpdate.newLatLng(destPoint!),
                        );
                        _markers.add(
                          Marker(
                            markerId: const MarkerId('destination'),
                            position: destPoint!,
                            infoWindow: const InfoWindow(
                              title: 'Seçilen Konum',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: 20,
            child: Container(
              decoration: BoxDecoration(color: Colors.amber,
                borderRadius: BorderRadius.circular(50),

              ),
              child: IconButton(
                icon: const Icon(Icons.route),
                onPressed: () {
                  _showRouteDialog(context);
                },
                iconSize: 50,
                padding: const EdgeInsets.all(0), // paddingi kaldırarak butonun boyutunu kontrol edebilirsiniz
                constraints: const BoxConstraints.tightFor(
                  width: 75,
                  height: 75,
                ),
                splashRadius: 25, // splash effect için
                color: Colors.black, // arka plan rengi
                highlightColor: Colors.transparent, // butona basıldığında renk değişimi için
                // border radius
              ),
            ),


          ),
          if (routeCoordinates.isNotEmpty)
            Positioned(
              top: 125,
              left: 80,


              child: Container(
                decoration: BoxDecoration(color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),

                ),
                child: IconButton(

                  iconSize: 50,
                  padding: const EdgeInsets.all(0), // paddingi kaldırarak butonun boyutunu kontrol edebilirsiniz
                  constraints: const BoxConstraints.tightFor(
                    width: 50,
                    height: 50,
                  ),
                  splashRadius: 25, // splash effect için
                  color: Colors.white, // arka plan rengi
                  highlightColor: Colors.transparent,
                  onPressed: () {
                    _uploadRouteToDatabase();

                  },
                  icon: const Icon(
                    Icons.share, // IconButton'a paylaş simgesini ekler
                    size: 50, // IconButton'ın simge boyutunu belirler
                    color: Colors.black, // IconButton'ın rengini belirler
                  ),
                ),
              ),
            ),

          if (routeCoordinates.isNotEmpty)
            Positioned(
              top: 125,
              left: 285,


              child: Container(
                decoration: BoxDecoration(color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),

                ),
                child: IconButton(

                  iconSize: 50,
                  padding: const EdgeInsets.all(0), // paddingi kaldırarak butonun boyutunu kontrol edebilirsiniz
                  constraints: const BoxConstraints.tightFor(
                    width: 50,
                    height: 50,
                  ),
                  splashRadius: 25, // splash effect için
                  color: Colors.white, // arka plan rengi
                  highlightColor: Colors.transparent,
                  onPressed: () {
                    // Realtime Database'e rota bilgilerini yükleyin

                  },
                  icon: const Icon(
                    Icons.save, // IconButton'a paylaş simgesini ekler
                    size: 50, // IconButton'ın simge boyutunu belirler
                    color: Colors.black, // IconButton'ın rengini belirler
                  ),
                ),
              ),
            ),








          if (routeCoordinates.isNotEmpty)
          Positioned(
            top: 125,
            left: 185,


            child: Container(
              decoration: BoxDecoration(color: Colors.amber,
                borderRadius: BorderRadius.circular(8),

              ),
              child: IconButton(
                icon: const Icon(Icons.favorite),
                onPressed: () {
                  _showNationalIDDialog(context);
                },
                iconSize: 50,
                padding: const EdgeInsets.all(0), // paddingi kaldırarak butonun boyutunu kontrol edebilirsiniz
                constraints: const BoxConstraints.tightFor(
                  width: 50,
                  height: 50,
                ),
                splashRadius: 25, // splash effect için
                color: Colors.black, // arka plan rengi
                highlightColor: Colors.transparent, // butona basıldığında renk değişimi için
                // border radius
              ),
            ),


          ),








        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _updateMarkers();
  }

  void _updateMarkers() {
    if (widget.driverList.isNotEmpty) {
      for (var driver in widget.driverList) {
        if (driver.containsKey('Konum')) {
          double? latitude = driver['Konum']?['latitude'];
          double? longitude = driver['Konum']?['longitude'];
          String? name = driver['Ad Soyad'];
          String? carModel= driver['Araba Modeli'];
          String? nationalID= driver['TC Kimlik Numarası'];

          if (latitude != null && longitude != null && name != null) {
            _markers.add(
              Marker(
                markerId: MarkerId(latitude.toString() + longitude.toString()),
                position: LatLng(latitude, longitude),
                infoWindow: InfoWindow(
                  title: name+carModel!,
                  snippet: 'Konum Bilgisi',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                onTap: () {
                  setState(() {
                    selectedDriverName = name;
                    selectedDriverPosition = LatLng(latitude, longitude);
                    selectedDriverCarModel= carModel;
                    selectedDriverNationalID= nationalID;
                  });
                  Scaffold.of(context).openDrawer();
                },
              ),
            );
          }
        }
      }
      setState(() {});
    }
  }

  void _getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    var locationData = await _location.getLocation();
    _currentPosition =
        LatLng(locationData.latitude!, locationData.longitude!);
    _controller.animateCamera(CameraUpdate.newLatLng(_currentPosition));
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: _currentPosition,
          infoWindow: const InfoWindow(
            title: 'Mevcut Konumunuz',
          ),
        ),
      );
    });
  }

  void _createPolylines(LatLng start, LatLng destination) async {
    PolylinePoints polylinePoints = PolylinePoints();
    List<LatLng> polylineCoordinates = [];

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyCJyfiuKLbutjuG3NDXMQyPkf2D5OjkCFE',
      PointLatLng(start.latitude, start.longitude),
      PointLatLng(destination.latitude, destination.longitude),
      travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }

    setState(() {
      _polylines.add(
        Polyline(
          polylineId: PolylineId(start.toString() + destination.toString()),
          color: Colors.blue,
          points: polylineCoordinates,
          width: 5,
        ),
      );
      routeCoordinates = polylineCoordinates;
    });

    // Mesafeyi hesapla
    double distanceInMeters = Geolocator.distanceBetween(
      start.latitude, start.longitude,
      destination.latitude, destination.longitude,
    );

    double distanceInKm = distanceInMeters / 1000;
    String distance = distanceInKm.toStringAsFixed(2);

    // Ücreti hesapla
    double openingPrice = 100;
    double kmPrice = 18;
    double indiBindiPrice = 100;
    double totalPrice = openingPrice + (distanceInKm * kmPrice) +
        indiBindiPrice;

    // Sonuçları güncelle
    setState(() {
      totalDistance = distanceInKm;
    });

    // Mesafeyi yazdır
    setState(() {
      distance = distance;
    });
  }

  Future<List> _getSuggestions(String query) async {
    const String baseUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    final String request = '$baseUrl?input=$query&key=AIzaSyCJyfiuKLbutjuG3NDXMQyPkf2D5OjkCFE&components=country:tr';
    final response = await http.get(Uri.parse(request));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['predictions'];
    } else {
      throw Exception('Failed to load suggestions');
    }
  }

  Future<Map<String, dynamic>> _getPlaceDetails(String placeId) async {
    const String baseUrl = 'https://maps.googleapis.com/maps/api/place/details/json';
    final String request = '$baseUrl?place_id=$placeId&key=AIzaSyCJyfiuKLbutjuG3NDXMQyPkf2D5OjkCFE';
    final response = await http.get(Uri.parse(request));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final location = data['result']['geometry']['location'];
      return {'lat': location['lat'], 'lng': location['lng']};
    } else {
      throw Exception('Failed to load place details');
    }
  }

  void _showRouteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Rota Oluştur',
            style: TextStyle(color: Colors.black), // Başlık metninin rengini siyah yapar
          ),
          content: SizedBox(
            width: 700,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text(
                    'Başlangıç Noktası:',
                    style: TextStyle(color: Colors.black), // Liste başlığının rengini siyah yapar
                  ),
                  subtitle: startPoint != null
                      ? Text(
                    'Enlem: ${startPoint!.latitude}, Boylam: ${startPoint!.longitude}',
                    style: const TextStyle(color: Colors.black), // Alt metnin rengini siyah yapar
                  )
                      : const Text(
                    'Güncel Konum',
                    style: TextStyle(color: Colors.black), // Alt metnin rengini siyah yapar
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.send, color: Colors.amber), // İkon rengini amber yapar
                    onPressed: () async {
                      var selectedLocation = await _selectLocation(
                          context, 'Başlangıç Noktası Seç');
                      if (selectedLocation != null) {
                        setState(() {
                          startPoint = selectedLocation;
                        });
                      }
                    },
                  ),

                ),
                ListTile(
                  title: const Text(
                    'Varış Noktası:',
                    style: TextStyle(color: Colors.black), // Liste başlığının rengini siyah yapar
                  ),
                  subtitle: destPoint != null
                      ? Text(
                    'Enlem: ${destPoint!.latitude}, Boylam: ${destPoint!.longitude}',
                    style: const TextStyle(color: Colors.black), // Alt metnin rengini siyah yapar
                  )
                      : const Text(
                    'Seçilmedi',
                    style: TextStyle(color: Colors.black), // Alt metnin rengini siyah yapar
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.send, color: Colors.amber), // İkon rengini amber yapar
                    onPressed: () async {
                      var selectedLocation = await _selectLocation(
                          context, 'Varış Noktası Seç');
                      if (selectedLocation != null) {
                        setState(() {
                          destPoint = selectedLocation;
                        });
                      }
                    },
                  ),

                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'İptal',
                style: TextStyle(color: Colors.black), // Buton metninin rengini siyah yapar
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (startPoint != null && destPoint != null) {
                  _createPolylines(startPoint!, destPoint!);
                } else if (destPoint != null) {
                  _createPolylines(_currentPosition, destPoint!);
                }
              },
              child: const Text(
                'Rota Oluştur',
                style: TextStyle(color: Colors.black), // Buton metninin rengini siyah yapar
              ),
            ),
          ],
        );

      },
    );
  }

  Future<LatLng?> _selectLocation(BuildContext context, String hintText) async {
    final ScrollController scrollController = ScrollController();
    return showDialog<LatLng>(
      context: context,
      builder: (context) {
        final TextEditingController searchController = TextEditingController();
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            hintText,
            style: const TextStyle(color: Colors.black), // hintText'i gri yapar
          ),
          content: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: TypeAheadField(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Konum giriniz',
                        hintStyle: const TextStyle(color: Colors.grey), // Hint metninin rengini gri yapar
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: const Icon(Icons.location_on, color: Colors.amber), // Icon'un rengini amber yapar ve send ikonunu kullanır
                      ),
                    ),
                    suggestionsCallback: (pattern) async {
                      return await _getSuggestions(pattern);
                    },
                    itemBuilder: (context, suggestion) {
                      return Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text(
                            suggestion['description'],
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      );
                    },
                    onSuggestionSelected: (suggestion) async {
                      searchController.text = suggestion['description'];
                      var placeId = suggestion['place_id'];
                      var details = await _getPlaceDetails(placeId);
                      Navigator.pop(
                        context,
                        LatLng(details['lat'], details['lng']),
                      );
                    },
                  ),



                ),
              ],
            ),
          ),
        );

      },
    );
  }

  void _showNationalIDDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Arka plan rengi beyaz yapılıyor
          title: Text(
            'Şifre',
            style: TextStyle(color: Colors.black), // Başlık rengi siyah yapılıyor
          ),
          content: TextField(
            controller: _nationalIDController,
            keyboardType: TextInputType.number,
            obscureText: true, // Şifrenin görünmez olması için bu özellik ekleniyor
            maxLength: 6, // Şifrenin maksimum uzunluğu 6 karakter olacak şekilde sınırlıyoruz
            decoration: InputDecoration(
              hintText: 'Rota Kayıt Şifresi',
              hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)), // İpucu metni rengi gri tonu yapılıyor
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'İptal',
                style: TextStyle(color: Colors.black), // Buton metni rengi siyah yapılıyor
              ),
            ),
            TextButton(
              onPressed: () {
                _addToFavorites();
                Navigator.of(context).pop();
              },
              child: Text(
                'Ekle',
                style: TextStyle(color: Colors.black), // Buton metni rengi siyah yapılıyor
              ),
            ),
          ],
        );
      },
    );
  }



  void _addToFavorites() {
    if (_nationalIDController.text.length == 6) { // TC Kimlik numarasının uzunluğunu kontrol et
      bool isValid = true;
      for (var char in _nationalIDController.text.runes) {
        // Her karakterin bir rakam olduğunu kontrol et
        if (!(char >= 48 && char <= 57)) {
          isValid = false;
          break;
        }
      }
      if (isValid) {
        // TC Kimlik numarası geçerli ise favorilere ekleme işlemini yap
        if (routeCoordinates.isNotEmpty) {
          final routeData = {
            'route': {
              'start': {
                'latitude': routeCoordinates.first.latitude,
                'longitude': routeCoordinates.first.longitude,
              },
              'end': {
                'latitude': routeCoordinates.last.latitude,
                'longitude': routeCoordinates.last.longitude,
              },
              'coordinates': routeCoordinates.map((e) => {'latitude': e.latitude, 'longitude': e.longitude}).toList(),
              'total_distance': totalDistance,
            },
            'national_id': _nationalIDController.text,
          };

          _database.child('favorites').push().set(routeData).then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rota favorilere eklendi!')),
            );
          }).catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Favorilere ekleme sırasında hata oluştu: $error')),
            );
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lütfen rota oluşturun!')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('TC Kimlik Numarası sadece rakamlardan oluşmalıdır!')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TC Kimlik Numarası 6 karakter olmalıdır!')),
      );
    }
  }


  Widget _buildDriverInfoDrawer() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
          child: Text(
            'Sürücü Bilgisi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
        ),
        ListTile(
          title: Text('Ad Soyad: $selectedDriverName'),
        ),
        ListTile(
          title: Text('Enlem: ${selectedDriverPosition?.latitude}'),
        ),
        ListTile(
          title: Text('Boylam: ${selectedDriverPosition?.longitude}'),
        ),
      ],
    );
  }
}
