import 'package:dart_midi/dart_midi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_midiplayer/flutter_midiplayer.dart';

import 'dart:io';
//import 'package:path/path.dart' as Path;
import 'package:path_provider/path_provider.dart';
//import 'package:permission_handler/permission_handler.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {

  var pauseState = false;
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  int bpm = 60;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    asyncInit();
  }

  Future asyncInit() async {
    await copyFromAssets();
    await parseMidi("bach_air_2REC.mid");

    Timer.periodic(Duration(milliseconds: 100), (Timer timer) async{
      String r = await FlutterMidiplayer.position();
      setState(() {_platformVersion = r;});
    });

  }

  Future parseMidi(name) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
// Construct a midi parser
    var parser = MidiParser();
    File midiFile = File('${appDocDir.path}/$name');

// Parse midi directly from file. You can also use parseMidiFromBuffer to directly parse List<int>
    MidiFile parsedMidi = parser.parseMidiFromFile(midiFile);

    parsedMidi.tracks[0].forEach((event) {
      print(event);
      if(event is TimeSignatureEvent) {
        print ("TimeSignatureEvent ${event.numerator}/${event.denominator}");
      }
      if(event is SetTempoEvent) {
        print ("SetTempoEvent ${event.microsecondsPerBeat}");
        bpm = (60000000/event.microsecondsPerBeat).toInt();
      }

      });
    /*
     parsedMidi.tracks[2].forEach((event) {
       if(event is NoteOnEvent){
         print ("deltatime: ${event.deltaTime}");
       }
       print(event);
     });
  */

// You can now access your parsed [MidiFile]
    print(parsedMidi.tracks.length.toString());

  }

  Future copyFromAssets_helper(name) async {
    rootBundle.load('assets/$name').then((content) async {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File newFile = File('${appDocDir.path}/$name');
      if(!await newFile.exists()) {
        newFile.writeAsBytesSync(content.buffer.asUint8List());
        print("${newFile.path} file created.");
      }
    });
  }

  Future copyFromAssets() async {
    //copy soundfont to Documents
    await copyFromAssets_helper("soundfont_GM.sf2");
    //copy midi to Documents
    await copyFromAssets_helper("bach_air_2REC.mid");
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await FlutterMidiplayer.platformVersion ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            Center(
              child: Text('Running on: $_platformVersion\n'),
            ),
            ElevatedButton(onPressed: () async {
              var midifilename = "bach_air_2REC.mid";
              String r = await FlutterMidiplayer.load(midifilename,bpm);
              setState(() {
                _platformVersion = r;
              });
            }, child: Text('Load')),
            ElevatedButton(onPressed: () async { String r = await FlutterMidiplayer.start(); setState(() {_platformVersion = r;});}, child: Text('Start')),
            ElevatedButton(onPressed: () async { String r = await FlutterMidiplayer.stop();  setState(() {_platformVersion = r;});},  child: Text('Stop')),
            ElevatedButton(onPressed: () async { String r = await FlutterMidiplayer.pause(widget.pauseState);      setState(() {_platformVersion = r;});},  child: Text('Pause')),
            ElevatedButton(onPressed: () async { String r = await FlutterMidiplayer.position();      setState(() {_platformVersion = r;});},  child: Text('Position')),
          ],
        ),
      ),
    );
  }
}
