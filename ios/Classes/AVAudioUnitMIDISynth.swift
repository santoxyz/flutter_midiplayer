//
//  AVAudioUnitMIDISynth.swift
//  MIDISynth
//
//  Created by Gene De Lisa on 2/6/16.
//  Copyright © 2016 Gene De Lisa. All rights reserved.
//

import Foundation
import AVFoundation

// swiftlint:disable line_length


 /// # An AVAudioUnit example.
 ///
 /// A multi-timbral implementation of `AVAudioUnitMIDIInstrument` as an `AVAudioUnit`.
 /// This will use the polyphonic `kAudioUnitSubType_MIDISynth` audio unit.
 ///
 /// - author: Gene De Lisa
 /// - copyright: 2016 Gene De Lisa
 /// - date: February 2016
 /// - requires: AVFoundation
 /// - seealso:
 ///[The Swift Standard Library Reference](https://developer.apple.com/library/prerelease/ios//documentation/General/Reference/SwiftStandardLibraryReference/index.html)
 ///
 /// - seealso:
 ///[Constructing Audio Unit Apps](https://developer.apple.com/library/ios/documentation/MusicAudio/Conceptual/AudioUnitHostingGuide_iOS/ConstructingAudioUnitApps/ConstructingAudioUnitApps.html)
 ///
 /// - seealso:
 ///[Audio Unit Reference](https://developer.apple.com/library/ios/documentation/AudioUnit/Reference/AudioUnit_Framework/index.html)
@objcMembers class AVAudioUnitMIDISynth: AVAudioUnitMIDIInstrument {
    
    func setTempo(tempo:Int32) {
        var status = OSStatus(noErr)
        print ("sending tempo value \(UInt32(tempo))")
        let t1 = UInt8(tempo >> 16 & 0xff)
        let t2 = UInt8(tempo >> 8 & 0xff)
        let t3 = UInt8(tempo & 0xff)
        
        let data:[UInt8] = [0xFF /*metaEvent*/, 51, 03, t1,t2,t3 ]
        
        print ("data = \(data)")

        status = MusicDeviceSysEx(self.audioUnit, data, UInt32(data.count));
        AudioUtils.CheckError(status)
    }
    
    func setVolume(channel:UInt32, v:Double) {
        let controlModeChange = UInt32(0xB0 | channel) //Control Change
        var status = OSStatus(noErr)
        //print ("sending value \(UInt32(v)) to channel \(channel)")
        status = MusicDeviceMIDIEvent(self.audioUnit, controlModeChange, 0x7 /*Channel Volume*/, UInt32(v), 0)
        AudioUtils.CheckError(status)
    }
    
    func sendProgramChange(channel: UInt32, d1: UInt32){
        let pC = UInt32(0xC0 | channel) //Program Change | Channel 9s
        var status = OSStatus(noErr)
        print ("sending d1 \(d1) to channel \(channel)")
        status = MusicDeviceMIDIEvent(self.audioUnit, pC, d1 , 0 /*not used in program change message*/, 0)
        AudioUtils.CheckError(status)
    
    }
    
    override init() {
        var description = AudioComponentDescription()
        description.componentType         = kAudioUnitType_MusicDevice
        description.componentSubType      = kAudioUnitSubType_MIDISynth
        description.componentManufacturer = kAudioUnitManufacturer_Apple
        description.componentFlags        = 0
        description.componentFlagsMask    = 0
        
        super.init(audioComponentDescription: description)

        //name parameter is in the form "Company Name:Unit Name"
        //AUAudioUnit.registerSubclass(AVAudioUnitMIDISynth.self, as: description, name: "foocom:myau", version: 1)

    }
    
    /// Loads the specified sound font.
    /// - parameter bankURL: A URL to the sound font.
    func loadMIDISynthSoundFont(_ bankURL: URL) {
        var bankURL = bankURL
        
        let status = AudioUnitSetProperty(
            self.audioUnit,
            AudioUnitPropertyID(kMusicDeviceProperty_SoundBankURL),
            AudioUnitScope(kAudioUnitScope_Global),
            0,
            &bankURL,
            UInt32(MemoryLayout<URL>.size))
        
        if status != OSStatus(noErr) {
            print("error \(status)")
        }
        
        print("loaded sound font")
    }
    
     /// Pre-load the patches you will use.
     ///
     /// Turn on `kAUMIDISynthProperty_EnablePreload` so the midisynth will load the patch data from the file into memory.
     /// You load the patches first before playing a sequence or sending messages.
     /// Then you turn `kAUMIDISynthProperty_EnablePreload` off. It is now in a state where it will respond to MIDI program
     /// change messages and switch to the already cached instrument data.
     ///
     /// - precondition: the graph must be initialized
     ///
     /// [Doug's post](http://prod.lists.apple.com/archives/coreaudio-api/2016/Jan/msg00018.html)
    func loadPatches( patches: [UInt32], channels:[UInt32]) throws {
        
        if let e = engine {
            if !e.isRunning {
                print("audio engine needs to be running")
                throw AVAudioUnitMIDISynthError.engineNotStarted
            }
        }
        
        var enabled = UInt32(1)
        
        var status = AudioUnitSetProperty(
            self.audioUnit,
            AudioUnitPropertyID(kAUMIDISynthProperty_EnablePreload),
            AudioUnitScope(kAudioUnitScope_Global),
            0,
            &enabled,
            UInt32(MemoryLayout<UInt32>.size))
        if status != noErr {
            print("error \(status)")
        }
        //        let bankSelectCommand = UInt32(0xB0 | 0)
        //        status = MusicDeviceMIDIEvent(self.midisynthUnit, bankSelectCommand, 0, 0, 0)
        
        for (i,patch) in patches.enumerated() {
            let pcCommand = UInt32(0xC0 | channels[i])
            print("preloading patch \(patch) on channel \(channels[i])")
            status = MusicDeviceMIDIEvent(self.audioUnit, pcCommand, patch, 0, 0)
            if status != noErr {
                print("error \(status)")
                AudioUtils.CheckError(status)
            }
        }
        
        enabled = UInt32(0)
        status = AudioUnitSetProperty(
            self.audioUnit,
            AudioUnitPropertyID(kAUMIDISynthProperty_EnablePreload),
            AudioUnitScope(kAudioUnitScope_Global),
            0,
            &enabled,
            UInt32(MemoryLayout<UInt32>.size))
        if status != noErr {
            print("error \(status)")
        }
        
        // at this point the patches are loaded. You still have to send a program change at "play time" for the synth
        // to switch to that patch
    }

    /* C'è già nella classe padre (AVFundation)*/
    func sendMyProgramChange( patch: UInt32, channel: UInt32 ){
        let pcCommand = UInt32(0xC0 | channel)
        print("sending program change: patch \(patch) on channel \(channel)")
        let status = MusicDeviceMIDIEvent(self.audioUnit, pcCommand, patch, 0, 0)
        if status != noErr {
            print("error \(status)")
            AudioUtils.CheckError(status)
        }
    }

}


/// Possible Errors for this `AVAudioUnit`.
///
/// - EngineNotStarted:
/// The AVAudioEngine needs to be started
///
/// - BadSoundFont:
/// The specified sound font is no good
enum AVAudioUnitMIDISynthError: Error {
    /// The AVAudioEngine needs to be started and it's not.
    case engineNotStarted
    /// The specified sound font is no good.
    case badSoundFont
}
