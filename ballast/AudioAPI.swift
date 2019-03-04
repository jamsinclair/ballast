//
//  AudioAPI.swift
//  ballast
//
//  Created by Jamie Sinclair on 26/10/2017.
//  Copyright © 2017 Jamie Sinclair. All rights reserved.
//

import Foundation
import AVFoundation
import CoreAudio
import os.log


// Ideas:
// - https://stackoverflow.com/questions/8950727/how-to-get-the-computers-current-volume-level
// - https://stackoverflow.com/questions/170294/change-sound-or-other-system-preferences-in-mac-os-x
// - https://developer.apple.com/documentation/audiotoolbox/1405208-audio_hardware_services_properti?language=objc
// - https://stackoverflow.com/questions/6747016/how-do-i-register-for-a-notification-for-then-the-sound-volume-changes
// - https://developer.apple.com/documentation/coreaudio/1422472-audioobjectaddpropertylistener?language=objc
// - https://github.com/tbrek/AudioDevice2/blob/master/AudioDevice2/AudioDeviceListener.swift

struct AudioAddress {
    static var outputDevice = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                                                         mScope: kAudioObjectPropertyScopeGlobal,
                                                         mElement: kAudioObjectPropertyElementMaster)
    static var masterBalance = AudioObjectPropertyAddress(mSelector: kAudioHardwareServiceDeviceProperty_VirtualMasterBalance,
                                                          mScope: kAudioDevicePropertyScopeOutput,
                                                          mElement: kAudioObjectPropertyElementMaster)
}

class AudioAPI {
    static func getDefaultDevice () -> AudioObjectID  {
        var deviceID: AudioObjectID = AudioObjectID(0)
        var size: UInt32 = UInt32(MemoryLayout<AudioObjectID>.size)
        
        let result: OSStatus = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &AudioAddress.outputDevice, 0, nil, &size, &deviceID)
        
        if (kAudioHardwareNoError != result) {
            if #available(OSX 10.12, *) {
                os_log("Error getting default device id. Status code of: %@", result)
            } else {
                // Fallback on earlier versions
            }
        }
        
        return deviceID
    }
    
    static func getDeviceBalance(deviceID: AudioObjectID) -> Float32 {
        var balanceValue: Float32 = 0
        var size: UInt32 = UInt32(MemoryLayout<Float32>.size)
        
        let result: OSStatus = AudioObjectGetPropertyData(deviceID, &AudioAddress.masterBalance, 0, nil, &size, &balanceValue)
        
        if (kAudioHardwareNoError != result) {
            if #available(OSX 10.12, *) {
                os_log("Error getting default device balance. Status code of: %@", result)
            } else {
                // Fallback on earlier versions
            }
            // Pretend the device is centered
            balanceValue = 0.5
        }
        
        return balanceValue
    }
    
    static func setDeviceBalance(deviceID: AudioObjectID, balance: Float32) -> OSStatus {
        var balanceCopy: Float32 = balance
        let size: UInt32 = UInt32(MemoryLayout<Float32>.size)
        
        return AudioObjectSetPropertyData(deviceID, &AudioAddress.masterBalance, 0, nil, size, &balanceCopy)
    }
}
