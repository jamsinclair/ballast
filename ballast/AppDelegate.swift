//
//  AppDelegate.swift
//  ballast
//
//  Created by Jamie Sinclair on 24/10/2017.
//  Copyright © 2017 Jamie Sinclair. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if (sharedStatusMenuController.isRunningInBackground()) {
            sharedStatusMenuController.showRunningInBackgroundPrompt()
        }

        return true
    }
}
