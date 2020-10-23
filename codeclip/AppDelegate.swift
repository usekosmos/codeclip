//
//  AppDelegate.swift
//  gist-copy
//
//  Created by Kevin Unkrich on 10/21/20.
//

import Cocoa
import SwiftUI
import HotKey

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    private var gist: Gist = Gist()
    private var hotkey: HotKey?
    
    private var userCode: String = "Retrieving code."
    private var verificationUri: String = "Retrieving verification URI."
    
    private let helpUrl: String = "https://www.notion.so/unkrich/CodeClip-Help-60d255a5739d478a9db08a6cb2ea2aad"
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("codeclip-logo-menubar"))
            button.action = #selector(self.constructMenu)
            button.target = self
        }
    }
    
    @objc func constructMenu() {
        if gist.isAuthenticated() == false {
            gist.login(completionHandler: { data in
                guard let userCodeResponse = data["user_code"] as? String, let verificationUriResponse = data["verification_uri"] as? String else {
                    print("Could not parse GitHub response for device auth flow code and link.")
                    return
                }
                self.userCode = userCodeResponse
                self.verificationUri = verificationUriResponse
                
                self.constructAuthenticationMenu()
            }, pollCompletion: {
                self.constructHelpMenu()
            })
        } else {
            constructHelpMenu()
        }
    }
    
    func constructAuthenticationMenu() {
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(NSMenuItem(title: "You need to authenticate with GitHub.", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "User Code: " + userCode, action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Activation Link: " + verificationUri, action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Copy Code & Open Link", action: #selector(self.copyCodeAndOpenLink), keyEquivalent: "C"))
        statusItem.menu = menu
    }
    
    @objc func copyCodeAndOpenLink() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(self.userCode, forType: .string)
        let url = URL(string: self.verificationUri)!
        NSWorkspace.shared.open(url)
    }
    
    func constructHelpMenu() {
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(NSMenuItem(title: "You're authenticated.", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Use CMD+OPT+G to create gists.", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Help", action: #selector(openHelpLink), keyEquivalent: "H"))
        statusItem.menu = menu
        
        hotkey = HotKey(key: .g, modifiers: [.command, .option])
        hotkey?.keyDownHandler = {
            self.gist.create()
        }
    }
    
    @objc func openHelpLink() {
        let url = URL(string: helpUrl)!
        NSWorkspace.shared.open(url)
    }
}
