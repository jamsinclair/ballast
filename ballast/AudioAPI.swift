//
//  BalanceAPI.swift
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

class AudioAPI {
    static func getDefaultDevice () -> AudioObjectID  {
        var deviceID: AudioObjectID = AudioObjectID(0)
        var size: UInt32 = UInt32(MemoryLayout<AudioObjectID>.size)
        
        var address: AudioObjectPropertyAddress = AudioObjectPropertyAddress()
        address.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
        address.mScope = kAudioObjectPropertyScopeGlobal;
        address.mElement = kAudioObjectPropertyElementMaster;
        
        let result: OSStatus = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        
        if (kAudioHardwareNoError != result) {
            os_log("Error getting default device id. Status code of: %@", result)
        }
        
        return deviceID
    }
    
    
    static func getDeviceBalance(deviceID: AudioObjectID) -> Float32 {
        var balanceValue: Float32 = 0
        var size: UInt32 = UInt32(MemoryLayout<Float32>.size)
        
        var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress()
        address.mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterBalance
        address.mScope = kAudioDevicePropertyScopeOutput
        address.mElement = kAudioObjectPropertyElementMaster
        
        let result: OSStatus = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &balanceValue)
        
        if (kAudioHardwareNoError != result) {
            os_log("Error getting default device balance. Status code of: %@", result)
            // Pretend the device is centered
            balanceValue = 0.5
        }
        
        return balanceValue
    }
    
    
    static func setDeviceBalance(deviceID: AudioObjectID, balance: Float32) -> OSStatus {
        var balanceCopy: Float32 = balance
        let size: UInt32 = UInt32(MemoryLayout<Float32>.size)
        
        var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress()
        address.mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterBalance
        address.mScope = kAudioDevicePropertyScopeOutput
        address.mElement = kAudioObjectPropertyElementMaster
        
        return AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &balanceCopy)
    }
}

