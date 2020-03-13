//
//  AppDelegate.swift
//  UnsplashedPaper
//
//  Created by Daniel Grießhaber on 12.03.20.
//  Copyright © 2020 Daniel Grießhaber. All rights reserved.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!
    var statusBarItem: NSStatusItem!
    var timer: Timer!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        
        statusBarItem.button?.image = NSImage(named: "MenuIcon")
        statusBarItem.button?.image?.isTemplate = true
        
        let statusBarMenu = NSMenu(title: "UnsplashedPaper")
        
        statusBarItem.menu = statusBarMenu
        let preferencesItem = NSMenuItem(
            title: "Preferences",
            action: #selector(AppDelegate.showPreferences),
            keyEquivalent: ",")
        preferencesItem.keyEquivalentModifierMask = .command
        
        let updateNowItem = NSMenuItem(
            title: "Refresh Now",
            action: #selector(AppDelegate.updateWallpaperSingleShot),
            keyEquivalent: "R")
        updateNowItem.keyEquivalentModifierMask = .command
        
        let openCacheFolderItem = NSMenuItem(
            title: "Open Cache Folder",
            action: #selector(AppDelegate.openCacheFolder),
            keyEquivalent: "O")
        openCacheFolderItem.keyEquivalentModifierMask = .command
        
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.shared.terminate),
            keyEquivalent: "")
        
        statusBarMenu.addItem(preferencesItem)
        statusBarMenu.addItem(updateNowItem)
        statusBarMenu.addItem(openCacheFolderItem)
        statusBarMenu.addItem(NSMenuItem.separator())
        statusBarMenu.addItem(quitItem)
        
        updateWallpaper()
        scheduleUpdateJob()
    }
    
    func scheduleUpdateJob() {
        if timer != nil {
            timer.invalidate()
        }
        
        let defaults = UserDefaults.standard
        
        let updateInterval = defaults.object(forKey: "updateInterval") as? Int ?? 60
        timer = Timer(timeInterval: TimeInterval(updateInterval), target: self, selector: #selector(AppDelegate.updateWallpaper), userInfo: nil, repeats: false)
        
        
        RunLoop.main.add(timer, forMode: .common)
    }
    
    func getRandomWallpaper(withSize size: NSSize, fromCollection: String? = nil, forSearchterm: String? = nil, completion: @escaping (_ result: URL)->()) {
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let temporaryFilename = UUID().uuidString
        let destinationFileUrl = temporaryDirectoryURL.appendingPathComponent(temporaryFilename)
        
        var fileUrlComponents = URLComponents(string: "https://source.unsplash.com")!
        if let collection = fromCollection, !collection.isEmpty {
            fileUrlComponents.path.append("/collection/\(collection)")
        }else{
            fileUrlComponents.path.append("/random")
        }
        
        fileUrlComponents.path.append("/\(Int(size.width))x\(Int(size.height))/")
        
        if let query = forSearchterm, !query.isEmpty {
            fileUrlComponents.query = query
        }
        
        let sourceFileUrl = fileUrlComponents.url!
        print("Downloading image from: \(sourceFileUrl)")
           
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)

        let request = URLRequest(url: sourceFileUrl)

        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                // Success
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Successfully downloaded. Status code: \(statusCode)")
                }

                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileUrl)
                    completion(destinationFileUrl)
                } catch (let writeError) {
                    print("Error creating a file \(destinationFileUrl) : \(writeError)")
                }

            } else {
                print("Error took place while downloading a file. Error description: %@", error!);
            }
        }
        task.resume()
        
    }
    
    @objc
    func updateWallpaper(reschedule: Bool = true) {
        let defaults = UserDefaults.standard
        let scaleImages = defaults.object(forKey: "scaleImages") as? Bool ?? true
        let imagePerScreen = defaults.object(forKey: "imagePerScreen") as? Bool ?? true
        let collectionId = defaults.object(forKey: "collectionId") as? String
        let searchQuery = defaults.object(forKey: "searchQuery") as? String
        
        do {
            let workspace = NSWorkspace.shared

            if (imagePerScreen) {
                for screen in NSScreen.screens {
                    let screenSize = screen.visibleFrame.size
                    getRandomWallpaper(withSize: screenSize, fromCollection: collectionId, forSearchterm: searchQuery) { url in
                        var screenOptions = workspace.desktopImageOptions(for: screen)!
                        screenOptions[NSWorkspace.DesktopImageOptionKey.imageScaling] = scaleImages
                        do {
                            try workspace.setDesktopImageURL(url, for: screen, options: screenOptions)
                        } catch {
                            NSLog("\(error)")
                        }
                    }
                }
            } else {
                
                let maxWidth = NSScreen.screens.map{$0.visibleFrame.width}.max()!
                let maxHeight = NSScreen.screens.map{$0.visibleFrame.height}.max()!
                let size =  NSSize(width: maxWidth, height: maxHeight)
                    
                getRandomWallpaper(withSize: size, fromCollection: collectionId, forSearchterm: searchQuery) { url in
                    for screen in NSScreen.screens {
                        var screenOptions = workspace.desktopImageOptions(for: screen)!
                        screenOptions[NSWorkspace.DesktopImageOptionKey.imageScaling] = scaleImages
                        do {
                            try workspace.setDesktopImageURL(url, for: screen, options: screenOptions)
                        } catch {
                            NSLog("\(error)")
                        }
                    }
                }
            }
        }
        if(reschedule) {
            scheduleUpdateJob()
        }
    }
    
    @objc
    func updateWallpaperSingleShot() {
        updateWallpaper(reschedule: false)
    }
    
    
    @objc
    func showPreferences() {
        let storyBoard = NSStoryboard(name:"Main", bundle:nil);
        let controller = storyBoard.instantiateController(withIdentifier: "PreferencesController") as! NSWindowController
        controller.showWindow(self)
    }
    
    @objc
    func openCacheFolder() {
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: temporaryDirectoryURL.absoluteString)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

