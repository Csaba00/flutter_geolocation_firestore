import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'main.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Completer<GoogleMapController> _controller = Completer();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  Geoflutterfire geo = Geoflutterfire();
  Location location = Location();
  final Set<Marker> _markers = <Marker>{};
  BehaviorSubject<double> radius = BehaviorSubject<double>.seeded(100.0);
  late Stream<dynamic> query;
  late StreamSubscription subscription;

  void _animateToUser() async {
    LocationData pos = await location.getLocation();
    print(pos.latitude);
    print(pos.longitude);
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(pos.latitude!, pos.longitude!),
          zoom: 11.0,
        ),
      ),
    );
    print(_controller);
  }

  void _updateMarker(List<DocumentSnapshot> documentList) async {
    String? deviceId = await _getId();
    //var pos = await location.getLocation();
    //double lat = pos.latitude!;
    //double lng = pos.longitude!;

    // Make a referece to firestore
    //var ref = firestore.collection('locations');
    //GeoFirePoint center = geo.point(latitude: lat, longitude: lng);
    _markers.clear();
    documentList.forEach((DocumentSnapshot document) {
      var asd = documentList.last.id;
      var pinPosition = LatLng(document['position']['geopoint'].latitude,
          document['position']['geopoint'].longitude);

      // GeoPoint geopoint = document['position']['geopoint'];
      // // double distance = center.distance(lat: geopoint.latitude, lng: geopoint.longitude);

      setState(() {
        _markers.removeWhere((m) => m.markerId.value == document.id);
        _markers.add(
          Marker(
            markerId: MarkerId(document.id),
            position: pinPosition,
            icon: BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(title: 'Device ID: $deviceId'),
          ),
        );
        // _markers.clear();
        //print(document.id);
      });
    });
  }

  _startQuery() async {
    // Get users location
    var pos = await location.getLocation();
    double lat = pos.latitude!;
    double lng = pos.longitude!;

    // Make a referece to firestore
    var ref = firestore.collection('locations');
    GeoFirePoint center = geo.point(latitude: lat, longitude: lng);
    // subscribe to query
    subscription = radius.switchMap((rad) {
      print(rad);
      return geo.collection(collectionRef: ref).within(
            center: center,
            radius: rad,
            field: 'position',
            strictMode: true,
          );
    }).listen(_updateMarker);
  }

  _updateQuery(value) async {
    print(value);
    final zoomMap = {
      100.0: 12.0,
      200.0: 10.0,
      300.0: 7.0,
      400.0: 6.0,
      500.0: 5.0
    };
    final zoom = zoomMap[value];
    final GoogleMapController controller = await _controller.future;
    controller.moveCamera(CameraUpdate.zoomTo(zoom!));

    setState(() {
      radius.add(value);
    });
  }

  @override
  dispose() {
    subscription.cancel();
    super.dispose();
  }

  Future<DocumentReference> _addGeoPoint() async {
    LocationData pos = await location.getLocation();
    GeoFirePoint point =
        geo.point(latitude: pos.latitude!, longitude: pos.longitude!);
    return firestore
        .collection('locations')
        .add({'position': point.data, 'name': 'Yay I can be queried'});
  }

  Future<String?> _getId() async {
    var deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;

    return androidDeviceInfo.model; // unique ID on Android
  }

  void initState() {
    _animateToUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Stack(children: [
        SafeArea(
          child: GoogleMap(
            markers: Set.of((_markers != null) ? _markers : []),
            initialCameraPosition: const CameraPosition(
              target: LatLng(21.1458, 79.2882),
              zoom: 11.0,
            ),
            myLocationEnabled: true,
            compassEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              _startQuery();
            },
          ),
        ),
        Positioned(
            bottom: 50,
            right: 50,
            child: FlatButton(
                child: const Icon(
                  Icons.pin_drop,
                  color: Colors.white,
                ),
                color: Colors.black,
                onPressed: () {
                  _addGeoPoint();
                })),
        Positioned(
          bottom: 50,
          left: 10,
          child: Material(
            child: Slider(
              min: 100.0,
              max: 500.0,
              divisions: 4,
              value: radius.value,
              label: 'Radius ${radius.value}km',
              activeColor: Colors.green,
              inactiveColor: Colors.green.withOpacity(0.2),
              onChanged: _updateQuery,
            ),
          ),
        )
      ]),
    );
  }
}
