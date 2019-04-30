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

var sharedStatusMenuController = StatusMenuController()

class StatusMenuController: NSObject {
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var balanceCorrectedItem: NSMenuItem!
    @IBOutlet weak var disableBallastItem: NSMenuItem!
    @IBOutlet weak var launchAtLoginItem: NSMenuItem!
    @IBOutlet weak var aboutWindow: NSWindow!
    @IBOutlet weak var runningInBackgroundWindow: NSWindow!
    @IBOutlet weak var runningInBackgroundWindowIcon: NSImageView!
    @IBOutlet weak var aboutWindowVersionText: NSTextField!
    
    var isCenteringEnabled = true
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let centerBalance: Float32 = 0.5
    let balanceObserver = BalanceObserver()
    let debouncedCenterDefaultDeviceBalance = Debouncer(.seconds(1.1))

    // User Defaults Keys
    let balanceCorrectedKey = "balanceChanged"
    let runInBackgroundKey = "runInBackground"
    
    deinit {
        balanceObserver.stopObserving()
    }
    
    override func awakeFromNib() {
        let icon = NSImage(named: "statusIcon")
        
        // Update shared instance of Status Menu Controller
        // @todo Must be a better way of doing this
        sharedStatusMenuController = self

        // Update Icons
        icon?.isTemplate = true
        statusItem.image = icon
        runningInBackgroundWindowIcon.image = NSImage(named: "AppIcon")


        statusItem.menu = statusMenu
        isCenteringEnabled = true

        aboutWindowVersionText.stringValue = "Ballast @ Version \(Bundle.main.releaseVersionNumber!)"
        
        // Continue hiding status menu icon, if set to run in background
        if (self.isRunningInBackground()) {
            self.toggleRunInBackground(true);
        }

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

    func isRunningInBackground () -> Bool {
        return UserDefaults.standard.bool(forKey: runInBackgroundKey)
    }

    func showRunningInBackgroundPrompt () {
        // Attempting to always bring prompt to front
        runningInBackgroundWindow?.close()
        runningInBackgroundWindow.setIsVisible(true)
        runningInBackgroundWindow.orderFrontRegardless()
    }

    @objc func centerDefaultDeviceBalance () {
        let currentDefaultDeviceID = AudioAPI.getDefaultDevice()
        let deviceBalance = AudioAPI.getDeviceBalance(deviceID: currentDefaultDeviceID)

        if (deviceBalance != centerBalance) {
            updateBalanceCorrectedCount()
            // @TODO error handling for when set fails?
            let _ = AudioAPI.setDeviceBalance(deviceID: currentDefaultDeviceID, balance: centerBalance)
            #if DEBUG
            os_log("Successfully centered default device Balance")
            #endif
        } else {
            #if DEBUG
            os_log("Skip centering balance, already centered")
            #endif
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

    private func toggleStatusMenuIcon (show: Bool) {
        statusItem.isVisible = show
    }

    private func updateBalanceCorrectedItemTitle () {
        if (self.isCenteringEnabled) {
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
        disableBallastItem.state = self.isCenteringEnabled ? NSControl.StateValue.off : NSControl.StateValue.on
    }
    
    private func toggleRunInBackground (_ toggle: Bool) {
        UserDefaults.standard.set(toggle, forKey: runInBackgroundKey)
        self.toggleStatusMenuIcon(show: !toggle)
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
        self.isCenteringEnabled = !self.isCenteringEnabled
        self.updateDisabledState()

        if (self.isCenteringEnabled) {
            self.startBalanceObserving()
            self.updateBalanceCorrectedItemTitle()
        } else {
            self.balanceObserver.stopObserving()
            balanceCorrectedItem.title = "Ballast is Disabled"
        }
    }
    
    @IBAction func keepRunningInBackgroundClicked(_ sender: NSButton) {
        runningInBackgroundWindow?.close()
    }
    
    @IBAction func stopRunningInBackgroundClicked(_ sender: NSButton) {
        runningInBackgroundWindow?.close()
        self.toggleRunInBackground(false)
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

    @IBAction func hideStatusMenuIcon(_ sender: NSMenuItem) {
        toggleRunInBackground(true)
    }

    @IBAction func viewOnGitHubClicked(_ sender: NSButton) {
        if let url = URL(string: "https://github.com/jamsinclair/ballast"), NSWorkspace.shared.open(url) {
            #if DEBUG
            os_log("Github link was successfully opened", type: .debug)
            #endif
        }
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
}
