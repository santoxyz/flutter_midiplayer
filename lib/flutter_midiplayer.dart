
import 'dart:async';

import 'package:flutter/services.dart';

class FlutterMidiplayer {
  static const MethodChannel _channel =
      const MethodChannel('flutter_midiplayer');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> load(String path,[int bpm = 60]) async {
    final String res = await _channel.invokeMethod('LOAD', {
      "path":path,
      "bpm":bpm,
    });
    return res;
  }

  static Future<String> start() async {
    final String res = await _channel.invokeMethod('START');
    return res;
  }

  static Future<String> stop() async {
    final String res = await _channel.invokeMethod('STOP');
    return res;
  }

  static Future<String> pause(bool p) async {
    final String res = await _channel.invokeMethod('PAUSE',p);
    return res;
  }

  static Future<String> position() async {
    final String res = await _channel.invokeMethod('POSITION');
    return res;
  }

  static Future<String> setVolume(double v) async {
    final String res = await _channel.invokeMethod('SETVOLUME',{"volume":v});
    return res;
  }

  static Future<String> setTempo(double rate) async {
    final String res = await _channel.invokeMethod('SETTEMPO',{"rate":rate});
    return res;
  }
}
