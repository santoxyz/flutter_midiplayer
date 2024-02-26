//
//  AVSound.swift
//  MIDISynth
//
//  Created by Gene De Lisa on 2/6/16.
//  Copyright © 2016 Gene De Lisa. All rights reserved.
//


import Foundation
import AVFoundation
import AudioToolbox
import CoreAudio

// swiftlint:disable function_body_length
// swiftlint:disable type_body_length
// swiftlint:disable line_length
// swiftlint:disable file_length


/// # An AVFoundation example to test our `AVAudioUnit`.
///
///
///
///
/// - author: Gene De Lisa
/// - copyright: 2016 Gene De Lisa
/// - date: February 2016
@available(iOS 9.0, *)
@objcMembers class SynthSequence: NSObject {
    
    var engine: AVAudioEngine!
    var sequencer: AVAudioSequencer!
    var midiSynth: AVAudioUnitMIDISynth!
    var patches = [UInt32]()

    //override
    init(fileURL:URL, bankUrl:URL, patches:[UInt32], channels:[UInt32]) {
        super.init()
        
        engine = AVAudioEngine()

        midiSynth = AVAudioUnitMIDISynth()
        midiSynth.loadMIDISynthSoundFont(bankUrl)
        
        engine.attach(midiSynth)
        engine.connect(midiSynth, to: engine.mainMixerNode, format: nil)

        //print("audio auaudiounit \(midiSynth.auAudioUnit)")
        //print("audio audiounit \(midiSynth.audioUnit)")
        //print("audio descr \(midiSynth.audioComponentDescription)")

        addObservers()
        startEngine()
        
///SANTOX serve solo per setupSequencer?

        if(patches.count>0){
            do {
                try midiSynth.loadPatches(patches:patches,channels: channels)
            } catch AVAudioUnitMIDISynthError.engineNotStarted {
                print("Start the engine first!")
                fatalError("setting patches")
            } catch let e as NSError {
                print("\(e)")
                print("\(e.localizedDescription)")
                fatalError("setting patches")
            }
        }


        setupSequencerFile(fileURL: fileURL)
        //print(self.engine)
        
        // since we have created an AVAudioSequencer, the engine's musicSequence is set.
        //CAShow(UnsafeMutablePointer<MusicSequence>(engine.musicSequence!))
        
        setSessionPlayback()
        
    }

    func getMidiDisplayName (obj:MIDIObjectRef)  -> String{
        var property : Unmanaged<CFString>?
        if (noErr != MIDIObjectGetStringProperty(obj, kMIDIPropertyDisplayName, &property)){ return "" }
        return property!.takeRetainedValue() as String;
    }

    ///  Create an `AVAudioSequencer`.
    ///  The `MusicSequence` it uses read from a standard MIDI file.
    func setupSequencerFile(fileURL:URL) {
        
        self.sequencer = AVAudioSequencer(audioEngine: self.engine)
        let options = AVMusicSequenceLoadOptions()

        loadFile(fileURL: fileURL, options: options)
        
        //print(sequencer)


    }
    
    func loadFile(fileURL:URL){
        loadFile(fileURL: fileURL, options: nil)
    }
    
    func loadFile(fileURL:URL, options:AVMusicSequenceLoadOptions?){
        do {
            try sequencer.load(from: fileURL, options: options ?? AVMusicSequenceLoadOptions())
            print("loaded \(fileURL)")
        } catch {
            print("something screwed up \(error)")
            return
        }
    }
    
    func prepareToPlay() {
        sequencer.prepareToPlay()
    }
    
    ///  Play the sequence.
    func play() {
        if sequencer.isPlaying {
            stop()
        }
        
        print("attempting to play")
        do {
            //print ("sequencer.currentPositionInBeats \(sequencer.currentPositionInBeats )")

            try sequencer.start()
            print("playing")
            
            //print ("sequencer.currentPositionInBeats \(sequencer.currentPositionInBeats )")

        } catch {
            print("cannot start \(error)")
        }
    }
    
    ///  Stop the sequence playing.
    func stop() {
        sequencer.stop()
        sequencer.currentPositionInBeats = TimeInterval(0)
    }
    
    func pause() {
        sequencer.stop()
        print ("sequencer.currentPositionInBeats \(sequencer.currentPositionInBeats )")
    }
    
    ///  Put the `AVAudioSession` into playback mode and activate it.
    func setSessionPlayback() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try
                audioSession.setCategory(.playback, options: .mixWithOthers)
        } catch {
            print("couldn't set category \(error)")
            return
        }
        
        do {
            try audioSession.setActive(true)
        } catch {
            print("couldn't set category active \(error)")
            return
        }
    }
    
    ///  Start the `AVAudioEngine`
    func startEngine() {
        
        if engine.isRunning {
            print("audio engine already started")
            return
        }
        
        do {
            engine.prepare()
            try engine.start()
            print("audio engine started")
        } catch {
            print("oops \(error)")
            print("could not start audio engine")
        }
    }
    
    // MARK: - Notifications
    
    func addObservers() {
        NotificationCenter.default.addObserver(self,
            selector: #selector(SynthSequence.engineConfigurationChange(_:)),
            name: NSNotification.Name.AVAudioEngineConfigurationChange,
            object: engine)
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(SynthSequence.sessionInterrupted(_:)),
            name: AVAudioSession.interruptionNotification,
            object: engine)
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(SynthSequence.sessionRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: engine)
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self,
            name: NSNotification.Name.AVAudioEngineConfigurationChange,
            object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: AVAudioSession.interruptionNotification,
            object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: AVAudioSession.routeChangeNotification,
            object: nil)
    }
    
    
    // MARK: notification callbacks
    @objc func engineConfigurationChange(_ notification: Notification) {
        print("engineConfigurationChange")
    }
    
    @objc func sessionInterrupted(_ notification: Notification) {
        print("audio session interrupted")
        if let engine = notification.object as? AVAudioEngine {
            engine.stop()
        }
        
        if let userInfo = (notification as NSNotification).userInfo as? [String: AnyObject?] {
            if let reason = userInfo[AVAudioSessionInterruptionTypeKey] as? AVAudioSession.InterruptionType {
                switch reason {
                case .began:
                    print("began")
                case .ended:
                    print("ended")
                }
            }
        }
    }
    
    @objc func sessionRouteChange(_ notification: Notification) {
        print("sessionRouteChange")
        if let engine = notification.object as? AVAudioEngine {
            engine.stop()
        }
        
        if let userInfo = (notification as NSNotification).userInfo as? [String: AnyObject?] {
            
            if let reason = userInfo[AVAudioSessionRouteChangeReasonKey] as? AVAudioSession.RouteChangeReason {
                
                print("audio session route change reason \(reason)")
                
                switch reason {
                case .categoryChange: print("CategoryChange")
                case .newDeviceAvailable:print("NewDeviceAvailable")
                case .noSuitableRouteForCategory:print("NoSuitableRouteForCategory")
                case .oldDeviceUnavailable:print("OldDeviceUnavailable")
                case .override: print("Override")
                case .wakeFromSleep:print("WakeFromSleep")
                case .unknown:print("Unknown")
                case .routeConfigurationChange:print("RouteConfigurationChange")
                }
            }
            
            let previous = userInfo[AVAudioSessionRouteChangePreviousRouteKey]
            print("audio session route change previous \(String(describing: previous))")
        }
    }
    
}
