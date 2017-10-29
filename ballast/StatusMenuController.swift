//
//  StatusMenuController.swift
//  ballast
//
//  Created by Jamie Sinclair on 26/10/2017.
//  Copyright © 2017 Jamie Sinclair. All rights reserved.
//

import Cocoa
import LaunchAtLogin
import os.log

class StatusMenuController: NSObject {
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var balanceCorrectedItem: NSMenuItem!
    @IBOutlet weak var launchAtLoginItem: NSMenuItem!
    @IBOutlet weak var aboutWindow: NSWindow!
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let balanceCorrectedKey = "balanceChanged"
    let centerBalance: Float32 = 0.5
    let autoCenterBalanceDelayInSeconds: TimeInterval = 600
    
    override func awakeFromNib() {
        let icon = NSImage(named: NSImage.Name(rawValue: "statusIcon"))
        
        icon?.isTemplate = true
        statusItem.image = icon

        statusItem.menu = statusMenu
        
        self.centerDefaultDeviceBalance()
        self.updateBalanceCorrectedItemTitle()
        self.updateLaunchAtLoginItemState()

        
        let balanceTimer = Timer.scheduledTimer(timeInterval: autoCenterBalanceDelayInSeconds, target: self, selector: #selector(centerDefaultDeviceBalance), userInfo: nil, repeats: true)
        RunLoop.main.add(balanceTimer, forMode: RunLoopMode.commonModes)
    }
    
    @objc func centerDefaultDeviceBalance () {
        let currentDefaultDeviceID = AudioAPI.getDefaultDevice()
        let deviceBalance = AudioAPI.getDeviceBalance(deviceID: currentDefaultDeviceID)
        
        if (deviceBalance != centerBalance) {
            updateBalanceCorrectedCount()
            // @TODO error handling for when set fails?
            let _ = AudioAPI.setDeviceBalance(deviceID: currentDefaultDeviceID, balance: centerBalance)
            os_log("Successfully centered default device Balance")
        } else {
            os_log("Skip centering balance, already centered")
        }
    }
    
    private func updateBalanceCorrectedItemTitle () {
        let count = UserDefaults.standard.integer(forKey: balanceCorrectedKey)
        balanceCorrectedItem.title = "Balance has been corrected \(count) time\(count == 1 ? "" : "s")"
    }
    
    private func updateBalanceCorrectedCount () {
        // Hacks, use UserDefaults to persist and keep track of how many times the balance has drifted
        let count = UserDefaults.standard.integer(forKey: balanceCorrectedKey)
        UserDefaults.standard.set(count + 1, forKey: balanceCorrectedKey)
        
        updateBalanceCorrectedItemTitle()
    }
    
    private func updateLaunchAtLoginItemState() {
        launchAtLoginItem.state = LaunchAtLogin.isEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
    }
    
    @IBAction func launchAtLoginClicked(_ sender: NSMenuItem) {
        LaunchAtLogin.isEnabled = !LaunchAtLogin.isEnabled
        LaunchAtLogin.isEnabled ? os_log("LaunchAtLogin is now enabled") : os_log("LaunchAtLogin is now disabled")
        
        self.updateLaunchAtLoginItemState()
    }
    
    @IBAction func centerBalanceClicked(_ sender: NSMenuItem) {
        self.centerDefaultDeviceBalance()
    }
    
    @IBAction func aboutClicked(_ sender: NSMenuItem) {
        aboutWindow.setIsVisible(true)
    }
    
    @IBAction func viewOnGitHubClicked(_ sender: NSButton) {
        if let url = URL(string: "https://github.com/jamsinclair/ballast"), NSWorkspace.shared.open(url) {
            print("Github link was successfully opened")
        }
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
}
