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
import Repeat

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}

class StatusMenuController: NSObject {
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var balanceCorrectedItem: NSMenuItem!
    @IBOutlet weak var disableBallastItem: NSMenuItem!
    @IBOutlet weak var launchAtLoginItem: NSMenuItem!
    @IBOutlet weak var aboutWindow: NSWindow!
    @IBOutlet weak var aboutWindowVersionText: NSTextField!
    
    var isEnabled = true

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let balanceCorrectedKey = "balanceChanged"
    let centerBalance: Float32 = 0.5
    let balanceObserver = BalanceObserver()
    let debouncedCenterDefaultDeviceBalance = Debouncer(.seconds(1))
    
    deinit {
        balanceObserver.stopObserving()
    }
    
    override func awakeFromNib() {
        let icon = NSImage(named: NSImage.Name(rawValue: "statusIcon"))
        
        icon?.isTemplate = true
        statusItem.image = icon

        statusItem.menu = statusMenu
        isEnabled = true

        aboutWindowVersionText.stringValue = "Ballast @ Version \(Bundle.main.releaseVersionNumber!)"

        self.updateLaunchAtLoginItemState()
        self.startBalanceObserving()
        self.updateBalanceCorrectedItemTitle()

        // We want to debounce centerDefaultDeviceBalance call because:
        // When the volume is changed rapidly it invokes multiple calls to the function
        // Sometimes causing false positives for when the balance is incorrect
        debouncedCenterDefaultDeviceBalance.callback = {
            self.centerDefaultDeviceBalance()
        }
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
    
    private func startBalanceObserving () {
        self.centerDefaultDeviceBalance()

        // Start Observeration of Balance, callback gets called whenever balance changes
        // @Note for some reason balance event also gets invoked when volume is changed?
        balanceObserver.startObserving(onChange: { () in
            self.debouncedCenterDefaultDeviceBalance.call()
        })
    }

    private func updateBalanceCorrectedItemTitle () {
        if (self.isEnabled) {
            let count = UserDefaults.standard.integer(forKey: balanceCorrectedKey)
            balanceCorrectedItem.title = "Balance has been corrected \(count) time\(count == 1 ? "" : "s")"
        }
    }

    private func updateBalanceCorrectedCount () {
        // Hacks, use UserDefaults to persist and keep track of how many times the balance has drifted
        let count = UserDefaults.standard.integer(forKey: balanceCorrectedKey)
        UserDefaults.standard.set(count + 1, forKey: balanceCorrectedKey)

        updateBalanceCorrectedItemTitle()
    }

    private func updateLaunchAtLoginItemState () {
        launchAtLoginItem.state = LaunchAtLogin.isEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
    }
    
    private func updateDisabledState () {
        disableBallastItem.state = self.isEnabled ? NSControl.StateValue.off : NSControl.StateValue.on
    }

    @IBAction func launchAtLoginClicked(_ sender: NSMenuItem) {
        LaunchAtLogin.isEnabled = !LaunchAtLogin.isEnabled
        LaunchAtLogin.isEnabled ? os_log("LaunchAtLogin is now enabled") : os_log("LaunchAtLogin is now disabled")

        self.updateLaunchAtLoginItemState()
    }
    
    @IBAction func centerBalanceClicked(_ sender: NSMenuItem) {
        self.centerDefaultDeviceBalance()
    }
    
    @IBAction func disableClicked(_ sender: NSMenuItem) {
        self.isEnabled = !self.isEnabled
        self.updateDisabledState()

        if (self.isEnabled) {
            self.startBalanceObserving()
            self.updateBalanceCorrectedItemTitle()
        } else {
            self.balanceObserver.stopObserving()
            balanceCorrectedItem.title = "Ballast is Disabled"
        }
    }

    @IBAction func aboutClicked(_ sender: NSMenuItem) {
        // Attempting to always bring about window to front
        aboutWindow?.close()
        aboutWindow.setIsVisible(true)
        aboutWindow.orderFrontRegardless()
    }

    @IBAction func resetCorrectionCountClicked(_ sender: NSMenuItem) {
        UserDefaults.standard.set(0, forKey: balanceCorrectedKey)
        updateBalanceCorrectedItemTitle()
    }

    @IBAction func viewOnGitHubClicked(_ sender: NSButton) {
        if let url = URL(string: "https://github.com/jamsinclair/ballast"), NSWorkspace.shared.open(url) {
            os_log("Github link was successfully opened", type: .debug)
        }
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
}
