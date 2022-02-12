// ignore_for_file: avoid_print, import_of_legacy_library_into_null_safe

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Music Bee'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FlutterAudioQuery audioQuery = FlutterAudioQuery();
  final player = AudioPlayer();
  List songlist = [];
  bool isPlaying = false;
  double currentVal = 0.0;
  double songPos = 0.0;
  double sliderValue = 0.0;
  late Uint8List albumArt;
  List songs = [];

  void getMusicFiles() async {
    try {
       songs =
          await audioQuery.getSongs(sortType: SongSortType.RECENT_YEAR);
      albumArt =
          await audioQuery.getArtwork(type: ResourceType.SONG, id: songs[0].id);
          print(audioQuery);
      setState(() {
        songlist = songs;
      });
    } catch (err) {
      print(err);
    }
  }

  double i = 0;
  Stream<double> getRandomValues() async* {
    for (i = 0; i <= player.duration!.inMilliseconds.toDouble(); i++) {
      await Future.delayed(const Duration(milliseconds: 1000));
      yield player.position.inSeconds.toDouble();
    }
  }

  Future<void> checkPermission() async {
    if (await Permission.storage.request().isGranted) {
      print(".......Storage permission Granted......");
    } else {
      print(".......Storage permission NOT Granted......");
    }
  }

  @override
  void initState() {
    super.initState();
    getMusicFiles();
    checkPermission();
  }

  double valu = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: ListView.builder(
        itemCount: songlist.length - songlist.length + 1,
        itemBuilder: (BuildContext context, int idx) {
          return Card(
            child: TextButton(
                onPressed: () async {
                  await player.setFilePath(songlist[idx].filePath);
                  print(songlist[idx].toString());
                  setState(() {
                    isPlaying = !isPlaying;
                  });
                  print(isPlaying);
                  if (isPlaying) {
                    player.seek(Duration(seconds: sliderValue.toInt()));
                    player.play();
                  } else {
                    player.pause();
                    player.seek(Duration(seconds: sliderValue.toInt()));
                  }
                },
                child: Column(
                  children: [
                    Text(
                      songlist[idx].displayName.toString(),
                      style: const TextStyle(color: Colors.black),
                    ),
                    StreamBuilder(
                      initialData: 0,
                      stream: getRandomValues(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          sliderValue = snapshot.data as double;
                        } else {
                          sliderValue = 0.0;
                        }
                        if (snapshot.hasData) {
                          return Column(
                            children: [
                              snapshot.hasData
                                  ? Text(sliderValue.toString())
                                  : Text(0.0.toString()),
                              Image.memory(albumArt),
                              FlutterSlider(
                                values: [sliderValue],
                                min: 0,
                                max: snapshot.hasData
                                    ? player.duration!.inSeconds.toDouble()
                                    : 100.0,
                                trackBar: const FlutterSliderTrackBar(
                                    activeTrackBar: BoxDecoration(
                                        color: Colors.lightGreenAccent)),
                                onDragging:
                                    (handlerIndex, lowerValue, upperValue) {
                                  print("lowerValue: " + lowerValue.toString());
                                  print("upperValue: " + upperValue.toString());
                                  setState(() {
                                    sliderValue = lowerValue.roundToDouble();
                                    player.seek(
                                        Duration(seconds: sliderValue.toInt()));
                                  });
                                },
                              ),
                            ],
                          );
                        } else {
                          return const LinearProgressIndicator(
                              color: Colors.transparent,
                              backgroundColor: Colors.transparent);
                        }
                      },
                    ),
                    // Image.asset("assets/1.png"),
                  ],
                )),
          );
        },
      )),
    );
  }
}
