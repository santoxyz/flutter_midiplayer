import Flutter
import UIKit

public class SwiftFlutterMidiplayerPlugin: NSObject, FlutterPlugin {

  var sound: SynthSequence!

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
    } else {
        result("unknown " + call.method + UIDevice.current.systemVersion)
    }
  }
}
