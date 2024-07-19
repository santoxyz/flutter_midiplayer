import Flutter
import AudioToolbox
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
        let patches = dict["patches", default: [74,0]] as? Array<UInt32>
        let channels = dict["channels", default: [0,1]] as? Array<UInt32>
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
            sound = SynthSequence(fileURL: fileURL!, bankUrl: bankURL!, patches: patches ?? [74,0] ,channels: channels ?? [0,1])
        } else {
            sound.loadFile(fileURL: fileURL!)
        }

        sound.sequencer.currentPositionInBeats = 0
        sound.prepareToPlay()
    } else if (call.method == "START"){
        result(call.method + UIDevice.current.systemVersion)
        if (sound == nil){
            return
        }
        
        //self.addVolumeMidiMessageInTrack(currentBeat: sound.sequencer.currentPositionInBeats)
        sound.play()

    } else if (call.method == "STOP"){
        result(call.method + UIDevice.current.systemVersion)
        sound?.stop()
    } else if (call.method == "PAUSE"){
        result(call.method + UIDevice.current.systemVersion)
        sound?.pause()
    } else if (call.method == "POSITION"){
        if (sound != nil) {
            result("\(sound.sequencer.currentPositionInBeats)")
        } else {
            result("0.0")
        }
    } else if (call.method == "SEEK"){
        let dict = call.arguments as! Dictionary<String, Any>
        let p = (dict["position"] as! Double)
        if (sound != nil) {
          //print("setting currentPostitionInBeats \(p)")
          sound?.sequencer.currentPositionInBeats = p
          result("\(sound.sequencer.currentPositionInBeats)")
        } else {
          result("0.0")
        }
    } else if (call.method == "SETVOLUME") {
        let dict = call.arguments as! Dictionary<String, Any>
        let v = (dict["volume"] as! Double)
        if((sound) != nil){
            sound.engine.mainMixerNode.outputVolume = Float((v / 127.0))
            //print ("v=\(v) outVol=\(sound.engine.mainMixerNode.outputVolume)")
        }
    
        result(call.method)
    } else if (call.method == "SETTEMPO") {
        let dict = call.arguments as! Dictionary<String, Any>
        let rate = (dict["rate"] as! Double)/100
        if(sound != nil){
            sound.sequencer.rate = Float(rate);
        }
        result(call.method)
    } else if (call.method == "SETMETRONOMEVOL") {
        let dict = call.arguments as! Dictionary<String, Any>
        let vol = (dict["vol"] as! Double)
        if(sound != nil){
          sound.midiSynth.setVolume(channel: 9, v: vol);
        }
        result(call.method)
    } else {
        result("unknown " + call.method + UIDevice.current.systemVersion)
    }
  }
}
