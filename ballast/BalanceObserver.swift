//
//  BalanceObserver.swift
//  ballast
//
//  Created by James Sinclair on 16/08/18.
//  Copyright © 2018 Jamie Sinclair. All rights reserved.
//

import Foundation
import AVFoundation
import CoreAudio
import os.log

extension Notification.Name {
    static let audioBalanceDidChange = Notification.Name("audioBalanceDidChange")
    static let audioOutputDeviceDidChange = Notification.Name("audioOutputDeviceDidChange")
}

struct AudioListener {
    static var outputDevice: AudioObjectPropertyListenerProc = {_, _, _, _ in
        #if DEBUG
        os_log("[AudioListener]: Output Device Changed", type: .debug)
        #endif
        NotificationCenter.default.post(name: .audioOutputDeviceDidChange, object: nil)
        return 0
    }
    static var balance: AudioObjectPropertyListenerProc = {_, _, _, _ in
        #if DEBUG
        os_log("[AudioListener]: Balance Changed", type: .debug)
        #endif
        NotificationCenter.default.post(name: .audioBalanceDidChange, object: nil)
        return 0
    }
}

class BalanceObserver: NSObject {
    var balanceDeviceID: AudioObjectID? = nil
    var balanceChangeHandler: (()->()?)? = nil
    
    override init () {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification(notification:)), name: .audioBalanceDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification(notification:)), name: .audioOutputDeviceDidChange, object: nil)
    }

    deinit {
        self.stopObserving()
        NotificationCenter.default.removeObserver(self)
    }
    
    func startObserving (onChange: @escaping () -> Void) {
        self.balanceChangeHandler = onChange
        self.updateBalanceListener()
        self.addOutputDeviceListener()
    }
    
    func stopObserving () {
        self.balanceChangeHandler = nil
        
        if (self.balanceDeviceID != nil) {
            self.removeBalanceListener(deviceID: self.balanceDeviceID!)
        }
        self.removeOutputDeviceListener()
    }
    
    func updateBalanceListener () {
        if (self.balanceDeviceID != nil) {
            self.removeBalanceListener(deviceID: self.balanceDeviceID!)
        }
        
        let activeDefaultDevice = AudioAPI.getDefaultDevice()
        self.balanceDeviceID = activeDefaultDevice
        
        self.addBalanceListener(deviceID: self.balanceDeviceID!)
    }
    
    private func addBalanceListener (deviceID: AudioObjectID) {
        AudioObjectAddPropertyListener(deviceID, &AudioAddress.masterBalance, AudioListener.balance, nil)
    }
    
    private func removeBalanceListener (deviceID: AudioObjectID) {
        AudioObjectRemovePropertyListener(deviceID, &AudioAddress.masterBalance, AudioListener.balance, nil)
    }
    
    private func addOutputDeviceListener () {
        AudioObjectAddPropertyListener(AudioObjectID(kAudioObjectSystemObject), &AudioAddress.outputDevice, AudioListener.outputDevice, nil)
    }
    
    private func removeOutputDeviceListener () {
        AudioObjectRemovePropertyListener(AudioObjectID(kAudioObjectSystemObject), &AudioAddress.outputDevice, AudioListener.outputDevice, nil)
    }
    
    @objc func handleNotification(notification: Notification) {
        #if DEBUG
        os_log("[BalanceObserver]: Got us a notification", type: .debug)
        #endif
        
        switch notification.name {
        case .audioBalanceDidChange:
            #if DEBUG
            os_log("[BalanceObserver]: Balance notification received", type: .debug)
            #endif
            self.balanceChangeHandler!()
            break
        case .audioOutputDeviceDidChange:
            #if DEBUG
            os_log("[BalanceObserver]: Output Device notification received", type: .debug)
            #endif
            self.balanceChangeHandler!()
            self.updateBalanceListener()
            break
        default :
            #if DEBUG
            os_log("[BalanceObserver] Unknown Notfication: %v", type: .debug, notification.name.rawValue as CVarArg)
            #endif
        }
    }
}
