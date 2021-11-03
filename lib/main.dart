import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

late GoogleMapController mapController;

Location userLocation = Location();
List<Marker> markers = [];

class _HomeState extends State<Home> {
  static const LatLng showLocation =
      LatLng(27.7089427, 85.3086209); //location to show in map

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: GoogleMap(
            zoomGesturesEnabled: true,
            initialCameraPosition: const CameraPosition(
              target: showLocation,
              zoom: 15.0,
            ),
            markers: Set.from(markers),
            onTap: _addMarker,
            onMapCreated: _onMapCreated,
          ),
        ),
        Positioned(
          bottom: 50,
          right: 40,
          child: TextButton(
            child: const Icon(Icons.pin_drop),
            onPressed: () {
              _animateToUser();
              print('Hello');
              //sleep(const Duration(seconds: 7));
            },
          ),
        )
      ],
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  void _addMarker(LatLng tappedPoint) {
    setState(() {
      //markers = [];
      markers.add(Marker(
        position: tappedPoint,
        icon: BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(title: 'Elso'),
        markerId: MarkerId(
          tappedPoint.toString(),
        ),
      ));
    });
  }

  void _animateToUser() async {
    sleep(const Duration(seconds: 5));
    print('Position');
    var pos = await userLocation.getLocation();
    print(pos);
    print('Position: $pos');
    setState(() {
      markers = [];
      markers.add(
        Marker(
          position: LatLng(pos.latitude!.toDouble(), pos.longitude!.toDouble()),
          markerId: const MarkerId('Home'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    });

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            pos.latitude!.toDouble(),
            pos.longitude!.toDouble(),
          ),
          zoom: 17,
        ),
      ),
    );
  }
}
