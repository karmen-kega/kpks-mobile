import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class MapWidget extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MapWidget({super.key, required this.userData});

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final Completer<GoogleMapController> _controller = Completer();
  double? currentLatitude;
  double? currentLongitude;
  StreamSubscription<LocationData>? locationSubscription;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    locationSubscription = Location().onLocationChanged.listen((location) {
      setState(() {
        currentLatitude = location.latitude;
        currentLongitude = location.longitude;
      });
    });
    _timer = Timer.periodic(const Duration(minutes: 1), (Timer t) {
      _sendLocationData();
    });
  }

  @override
  void dispose() {
    super.dispose();
    locationSubscription?.cancel();
    _timer?.cancel();
  }

  Future<void> _requestPermission() async {
    var location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        // Le GPS est désactivé, ne récupérez pas la position
        return;
      }
    }

    // Le GPS est activé, vérifiez la permission
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        // La permission a été refusée, ne récupérez pas la position
        return;
      }
    }

    // Si le GPS est activé et la permission est accordée,
    // vous pouvez commencer à récupérer la position ici
  }

  Future<String> getCityFromLatLng(double latitude, double longitude) async {
    const apiKey = "AIzaSyCrNjtdg4UoWB6JaAKQPOzZJgCvOHdP9I4";
    final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["status"] == "OK" && data["results"].isNotEmpty) {
          // Récupérez la ville à partir des résultats de la requête
          return data["results"][0]["formatted_address"];
        } else {
          return "Ville non trouvée";
        }
      } else {
        return "Erreur lors de la requête de géocodage";
      }
    } catch (e) {
      return "Erreur lors de la requête de géocodage: $e";
    }
  }

  Future<void> _sendLocationData() async {
    if (currentLatitude != null && currentLongitude != null) {
      final url =
          Uri.parse("https://kpks-76bbd2eed811.herokuapp.com/api/position");
      final headers = {"Content-Type": "application/json"};
      final city = await getCityFromLatLng(currentLatitude!, currentLongitude!);

      String userId = widget.userData["id"].toString();
      final data = jsonEncode({
        "utilisateur": userId,
        "latitude": currentLatitude,
        "longitude": currentLongitude,
        "localite": city, // Ajoutez la ville à votre requête
      });

      try {
        final response = await http.post(url, headers: headers, body: data);
        if (response.statusCode == 200) {
          print("Location data sent successfully");
        } else {
          print("Error sending location data: ${response.statusCode}");
        }
      } catch (e) {
        print("Error sending location data: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps Location'),
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        initialCameraPosition: const CameraPosition(
          target: LatLng(7.365302, 12.343439),
          zoom: 10.0,
        ),
        myLocationEnabled: true,
      ),
    );
  }
}
