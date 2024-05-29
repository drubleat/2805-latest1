import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'driverViewRouteScreen.dart';

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
      home: const MapThatIncUsers(userList: []), // Bu örnekte driverList boş
    );
  }
}

class MapThatIncUsers extends StatefulWidget {
  final List userList;

  const MapThatIncUsers({super.key, required this.userList});

  @override
  _MapThatIncUsersState createState() => _MapThatIncUsersState();
}

class _MapThatIncUsersState extends State<MapThatIncUsers> {
  late GoogleMapController _controller;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  late Location _location;
  late LatLng _currentPosition;
  LatLng? startPoint;
  LatLng? destPoint;
  final TextEditingController _typeAheadController = TextEditingController();

  double? totalDistance;
  List<LatLng> routeCoordinates = [];

  String? selectedUserName;
  LatLng? selectedUserPosition;
  String? selectedUserPhoneNumber;

  bool _isDrawerOpen = false; // Drawer durumunu takip etmek için bir değişken

  @override
  void initState() {
    super.initState();
    _location = Location();
    _getCurrentLocation();
  }

  // Firebase Realtime Database referansı
  final DatabaseReference _database = FirebaseDatabase(databaseURL: "https://follow-the-txii-default-rtdb.firebaseio.com/").reference();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşteri Konumları Haritası'),
        leading: IconButton(
          icon: const Icon(Icons.directions_bike_sharp),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RouteMapScreen(databaseReference: _database)),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // Drawer'ı açma/kapatma işlemi
              setState(() {
                _isDrawerOpen = !_isDrawerOpen;
              });
            },
          ),
        ],
      ),
      endDrawer: _buildDrawer(), // endDrawer özelliği ile sağ tarafta kayan panel ekleniyor
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
            myLocationButtonEnabled: true,
          ),
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TypeAheadField(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _typeAheadController,
                      decoration: InputDecoration(
                        hintText: 'Adres Ara',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                    suggestionsCallback: (pattern) async {
                      return await _getSuggestions(pattern);
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text(suggestion['description']),
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
                          CameraUpdate.newLatLng(destPoint!));
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
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 10,
            left: 15,
            right: 15,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Buraya istediğiniz widget'ları ekleyebilirsiniz
              ],
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
    if (widget.userList.isNotEmpty) {
      for (var users in widget.userList) {
        if (users.containsKey('Müşteri Konum')) {
          double? latitude = users['Müşteri Konum']?['latitude'];
          double? longitude = users['Müşteri Konum']?['longitude'];
          String? name = users['Müşteri Ad Soyad'];
          String? phoneNumber= users['Müşteri TC Kimlik Numarası'];

          if (latitude != null && longitude != null && name != null) {
            _markers.add(
              Marker(
                markerId: MarkerId(latitude.toString() + longitude.toString()),
                position: LatLng(latitude, longitude),
                infoWindow: InfoWindow(
                  title: name,
                  snippet: 'Konum Bilgisi',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                onTap: () {
                  setState(() {
                    selectedUserName = name;
                    selectedUserPosition = LatLng(latitude, longitude);
                    selectedUserPhoneNumber= phoneNumber;


                  });
                  // Drawer'ı açma işlemi
                  setState(() {
                    _isDrawerOpen = true;
                  });
                },
              ),
            );
          }
        }
      }
      setState(() {});
    }
  }
  Future<String?> getAddressFromLatLng(double lat, double lng) async {
    const apiKey = 'AIzaSyCJyfiuKLbutjuG3NDXMQyPkf2D5OjkCFE'; // Google Places API key
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>;

        if (results.isNotEmpty) {
          return results[0]['formatted_address'];
        } else {
          return null;
        }
      } else {
        throw Exception('Failed to load address');
      }
    } catch (e) {
      print('Error: $e');
      return null;
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

  Widget _buildDrawer() {
    return Drawer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(_isDrawerOpen ? 0 : 250, 0, 0),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Müşteri Bilgisi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text('Ad Soyad: $selectedUserName'),
            ),
            ListTile(
              title: Text('Enlem: ${selectedUserPosition?.latitude}'),
            ),
            ListTile(
              title: Text('Boylam: ${selectedUserPosition?.longitude}'),
            ),
          ],
        ),
      ),
    );
  }
}
