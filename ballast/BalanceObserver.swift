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
import SimplyCoreAudio
@_implementationOnly import SimplyCoreAudioC

struct AudioAddress {
    static var mainBalance = AudioObjectPropertyAddress(mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainBalance,
                                                          mScope: kAudioDevicePropertyScopeOutput,
                                                          mElement: kAudioObjectPropertyElementMain)
}

extension Notification.Name {
    static let deviceBalanceDidChange = Notification.Name("deviceBalanceDidChange")
}

struct AudioListener {
    static var balance: AudioObjectPropertyListenerProc = {_, _, _, _ in
        NotificationCenter.default.post(name: .deviceBalanceDidChange, object: nil)
        return 0
    }
}

class BalanceObserver: NSObject {
    var deviceObserver: NSObjectProtocol? = nil
    var balanceChangeHandler: (()->()?)? = nil
    var balanceDeviceID: AudioObjectID? = nil
    let simplyCA = SimplyCoreAudio()

    override init () {
        super.init()
    }

    deinit {
        self.stopObserving()
    }
    
    func startObserving (onChange: @escaping () -> Void) {
        self.balanceChangeHandler = onChange

        deviceObserver = NotificationCenter.default.addObserver(forName: .defaultOutputDeviceChanged,
                                                                object: nil,
                                                                 queue: .main) { (notification) in
            let currentDevice: AudioObjectID = self.simplyCA.defaultOutputDevice?.id ?? kAudioDeviceUnknown

            if  currentDevice != kAudioDeviceUnknown {
                self.updateBalanceListener(nextDeviceID: currentDevice)
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification(notification:)), name: .deviceBalanceDidChange, object: nil)
    }

    func stopObserving () {
        self.balanceChangeHandler = nil
        NotificationCenter.default.removeObserver(self)

        if (deviceObserver != nil) {
            NotificationCenter.default.removeObserver(deviceObserver!)
            deviceObserver = nil
        }
    }

    func updateBalanceListener (nextDeviceID: AudioObjectID) {
        if (self.balanceDeviceID != nil) {
            self.removeBalanceListener(deviceID: self.balanceDeviceID!)
        }
        
        self.balanceDeviceID = nextDeviceID
        
        self.addBalanceListener(deviceID: self.balanceDeviceID!)
    }

    private func addBalanceListener (deviceID: AudioObjectID) {
        AudioObjectAddPropertyListener(deviceID, &AudioAddress.mainBalance, AudioListener.balance, nil)
    }

    private func removeBalanceListener (deviceID: AudioObjectID) {
        AudioObjectRemovePropertyListener(deviceID, &AudioAddress.mainBalance, AudioListener.balance, nil)
    }

    @objc func handleNotification(notification: Notification) {
        switch notification.name {
        case .deviceBalanceDidChange:
            os_log("[Balance observer] Device balance changed", type: .debug)
            self.balanceChangeHandler!()
            break
        default :
            break
        }
    }
}
