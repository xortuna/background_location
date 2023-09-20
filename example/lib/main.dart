import 'dart:async';

import 'package:background_location/background_location.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_barometer/flutter_barometer.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String latitude = 'waiting...';
  String longitude = 'waiting...';
  String altitude = 'waiting...';
  String accuracy = 'waiting...';
  String bearing = 'waiting...';
  String speed = 'waiting...';
  String time = 'waiting...';
  bool _onLift = false;
  bool _useClassicGps = false;
  File? file;
  List<StreamSubscription<dynamic>> _streamSubscriptions = <StreamSubscription<dynamic>>[];

  double currentPressure = 0.0;

  Future<String> get _localPath async {
    String directory = '/storage/emulated/0/Documents/';
    if (Platform.isIOS) {
      directory = (await getApplicationDocumentsDirectory()).path;
    }
    return directory;
  }

  Future<File> get _localFile async {
    final path = await _localPath;

    return File(
        '$path/gis_${DateTime.now().month}_${DateTime.now().day}_${DateTime.now().hour}_${DateTime.now().minute}.txt');
  }

  @override
  void initState() {
    super.initState();
    _localFile.then((value) {
      file = value;
      file?.writeAsString("time,lat,lon,alt,bear,acc,speed,lift,barometer\n");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Background Location Service'),
        ),
        body: Center(
          child: ListView(
            children: <Widget>[
              locationData('Latitude: ' + latitude),
              locationData('Longitude: ' + longitude),
              locationData('Altitude: ' + altitude),
              locationData('Accuracy: ' + accuracy),
              locationData('Bearing: ' + bearing),
              locationData('Speed: ' + speed),
              locationData('Time: ' + time),
              locationData('Pressure:' + currentPressure.toString()),
              ElevatedButton(
                  onPressed: () async {
                    await BackgroundLocation.setAndroidNotification(
                      title: 'Background service is running',
                      message: 'Background location in progress',
                      icon: '@mipmap/ic_launcher',
                    );
                    //await BackgroundLocation.setAndroidConfiguration(1000);
                    await BackgroundLocation.startLocationService(
                        forceAndroidLocationManager: _useClassicGps,
                        activityType: BackgroundLocation.activity_type_fitness);

                    _streamSubscriptions.add(flutterBarometerEvents.listen((event) {
                      currentPressure = event.pressure;
                    }));

                    BackgroundLocation.getLocationUpdates((location) async {
                      setState(() {
                        latitude = location.latitude.toString();
                        longitude = location.longitude.toString();
                        accuracy = location.accuracy.toString();
                        altitude = location.altitude.toString();
                        bearing = location.bearing.toString();
                        speed = location.speed.toString();
                        time = DateTime.fromMillisecondsSinceEpoch(location.time!.toInt()).toString();
                      });
                      print('''\n
                        Latitude:  $latitude
                        Longitude: $longitude
                        Altitude: $altitude
                        Accuracy: $accuracy
                        Bearing:  $bearing
                        Speed: $speed
                        Time: $time
                      ''');
                      await file?.writeAsString(
                          "$time,$latitude,$longitude,$altitude,$bearing,$accuracy,$speed,$_onLift,$currentPressure\n",
                          mode: FileMode.append);
                    });
                  },
                  child: Text('Start Location Service')),
              ElevatedButton(
                  onPressed: () {
                    BackgroundLocation.stopLocationService();
                    for (StreamSubscription<dynamic> subscription in _streamSubscriptions) {
                      subscription.cancel();
                    }
                  },
                  child: Text('Stop Location Service')),
              ToggleButtons(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("Lift"),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("Classic GPS"),
                  )
                ],
                isSelected: [_onLift, _useClassicGps],
                onPressed: (index) {
                  setState(() {
                    if (index == 0) _onLift = !_onLift;
                    if (index == 1) _useClassicGps = !_useClassicGps;
                  });
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget locationData(String data) {
    return Text(
      data,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      textAlign: TextAlign.center,
    );
  }

  void getCurrentLocation() {
    BackgroundLocation().getCurrentLocation().then((location) {
      print('This is current Location ' + location.toMap().toString());
    });
  }

  @override
  void dispose() {
    BackgroundLocation.stopLocationService();
    super.dispose();
  }
}
