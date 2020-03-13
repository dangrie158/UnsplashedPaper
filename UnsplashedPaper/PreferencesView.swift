//
//  ContentView.swift
//  UnsplashedPaper
//
//  Created by Daniel Grießhaber on 12.03.20.
//  Copyright © 2020 Daniel Grießhaber. All rights reserved.
//
import AppKit

class Preferences: NSViewController {
    @IBOutlet weak var updateInterval: NSTextFieldCell!
    @IBOutlet weak var scaleImages: NSButton!
    @IBOutlet weak var seperateImages: NSButton!
    @IBOutlet weak var collection: NSTextField!
    @IBOutlet weak var queryString: NSTokenField!
    
    override func viewDidLoad() {
        let defaults = UserDefaults.standard
        scaleImages.state = NSControl.StateValue.init(defaults.bool(forKey: "scaleImages") ? 1 : 0)
        seperateImages.state = NSControl.StateValue.init(defaults.bool(forKey: "imagePerScreen") ? 1 : 0)
        collection.stringValue = defaults.string(forKey: "collectionId") ?? ""
        queryString.stringValue = defaults.string(forKey: "searchQuery") ?? ""
        let savedUpdateInterval = Int32(defaults.integer(forKey: "updateInterval"))
        updateInterval.intValue = savedUpdateInterval != 0 ? savedUpdateInterval : 60
    }
    
    
    @IBAction func settingChanged(_ sender: Any) {
        let defaults = UserDefaults.standard
        defaults.set(scaleImages.state.rawValue == 1, forKey: "scaleImages")
        defaults.set(seperateImages.state.rawValue == 1, forKey: "imagePerScreen")
        defaults.set(collection.stringValue, forKey: "collectionId")
        defaults.set(queryString.stringValue, forKey: "searchQuery")
        print(queryString.stringValue)
        defaults.set(updateInterval.intValue, forKey: "updateInterval")
    }
    
    @IBAction func quitApp(_ sender: Any) {
        NSApp.terminate(self)
    }
    
    @IBAction func refreshNow(_ sender: Any) {
        (NSApp.delegate as! AppDelegate).updateWallpaper(reschedule: false)
    }
}
