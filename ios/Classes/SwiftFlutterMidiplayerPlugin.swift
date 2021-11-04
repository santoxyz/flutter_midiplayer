import Flutter
import UIKit

public class SwiftFlutterMidiplayerPlugin: NSObject, FlutterPlugin {

  var sound: SynthSequence!
  var volume: Double = 100

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_midiplayer", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterMidiplayerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if(call.method == "LOAD"){
        let dict = call.arguments as! Dictionary<String, Any>
        let path = dict["path"] as! String
        result(call.method + UIDevice.current.systemVersion + path)

        let documentDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
        
        let bankURL = documentDirectory?.appendingPathComponent("soundfont_GM.sf2")

        if FileManager.default.fileExists(atPath: bankURL!.path) {
                print("FILE AVAILABLE")
            } else {
                print("FILE NOT AVAILABLE")
            }

        
        let fileURL = documentDirectory?.appendingPathComponent(path)
        
        if (sound == nil){
            sound = SynthSequence(fileURL: fileURL!, bankUrl: bankURL!, patches: [74,0],channels: [0,1])
        }
        sound.sequencer.currentPositionInBeats = 0
        sound.prepareToPlay()
    } else if (call.method == "START"){
        result(call.method + UIDevice.current.systemVersion)
        sound.play()
        for i in 1...15 {
            sound.midiSynth.setVolume(channel: UInt32(i), v: Double(volume));
        }
    } else if (call.method == "STOP"){
        result(call.method + UIDevice.current.systemVersion)
        sound.stop()
    } else if (call.method == "PAUSE"){
        result(call.method + UIDevice.current.systemVersion)
        sound.pause()
    } else if (call.method == "POSITION"){
        if (sound != nil) {
            result("\(sound.sequencer.currentPositionInBeats)")
        } else {
            result("0.0")
        }
    } else if (call.method == "SETVOLUME") {
        let dict = call.arguments as! Dictionary<String, Any>
        let v = (dict["volume"] as! Double)
        if(volume != v){
            volume = v;

            if((sound) != nil){
                /*ogni miditrack ha un array di eventi, ogni evento potenzialmente agisce su un canale diverso. Per evitare di analizzarmi tutti gli eventi, ciclo su tutti i 16 canali possibili.*/
                for i in 1...15 {
                    sound.midiSynth.setVolume(channel: UInt32(i), v: Double(v));
                }
            }
        }
        result(call.method)
    } else if (call.method == "SETTEMPO") {
        let dict = call.arguments as! Dictionary<String, Any>
        let rate = (dict["rate"] as! Double)/100
        if(sound != nil){
            sound.sequencer.rate = Float(rate);
        }
        result(call.method)
    } else {
        result("unknown " + call.method + UIDevice.current.systemVersion)
    }
  }
}
