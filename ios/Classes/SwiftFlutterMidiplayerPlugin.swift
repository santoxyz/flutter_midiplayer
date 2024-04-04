import Flutter
import UIKit

public class SwiftFlutterMidiplayerPlugin: NSObject, FlutterPlugin {

  var sound: SynthSequence!
  var volume: Double = 100
  var timerLoopForever: Timer?
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_midiplayer", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterMidiplayerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

    @objc func checkPlaybackPosition() {
        guard let sequencer = sound.sequencer else { return }
        // Check if playback has reached the end
        let beats = sound.sequencer.beats(forSeconds: sequencer.currentPositionInSeconds)
        let total = sound.sequencer.tracks.first?.lengthInSeconds ?? 0
        //print ("currentPosInSeconds=\(sequencer.currentPositionInSeconds) tot=\(total)")
        if sequencer.currentPositionInSeconds >= total {
            // Restart playback
            sequencer.currentPositionInBeats = 0
            sound.play()
        }
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
        let dict = call.arguments as? Dictionary<String, Any>
        let loopForever = (dict?["loopForever"] as? Bool) ?? false
        result(call.method + UIDevice.current.systemVersion)
        sound.play()
        

        if #available(iOS 10.0, *) {
            var count = 0;
            print("Timer to send setVolume=\(self.volume) for 10 times to all channels but 9")
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (timer) in

                //set volume of other tracks
                for i in 1...15 {
                    if(i != 9){
                        self.sound.midiSynth.setVolume(channel: UInt32(i), v: Double(self.volume));
                    }
                }
                //mute rendered track
                self.sound.midiSynth.setVolume(channel: UInt32(0), v: Double(0.0));
                count+=1;
                //print("count \(count)");
                if (count > 10) {
                    timer.invalidate()
                }
            }
        } else {
            // Fallback on earlier versions
        }
        
        if loopForever{
            timerLoopForever = Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(checkPlaybackPosition), userInfo: nil, repeats: true)
        }
    } else if (call.method == "STOP"){
        timerLoopForever?.invalidate()
        result(call.method + UIDevice.current.systemVersion)
        sound?.stop()
    } else if (call.method == "PAUSE"){
        timerLoopForever?.invalidate()
        result(call.method + UIDevice.current.systemVersion)
        sound?.pause()
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
                //mute rendered track
                sound.midiSynth.setVolume(channel: UInt32(0), v: Double(0.0));
                //set volume of other tracks
                for i in 1...15 {
                    if(i != 9){
                        sound.midiSynth.setVolume(channel: UInt32(i), v: Double(v));
                    }
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
