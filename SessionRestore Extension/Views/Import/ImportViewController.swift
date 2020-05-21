//
//  ImportViewController.swift
//  Session Buddy Extension
//
//  Created by phucld on 5/18/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Cocoa

class ImportViewController: NSViewController {
    
    @IBOutlet weak var lblFileName: NSTextField!
    @IBOutlet weak var btnRemoveFile: NSButton!
    @IBOutlet weak var btnImport: NSButton!
    
    private var fContent: Data? = nil {
        didSet {
            updateViews()
        }
    }
    
    var onNavigationBack: ((Bool) -> Void)?
    
    private var shouldUpdate = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    func set(onNavigationBack: @escaping ((Bool) -> Void)) {
        self.onNavigationBack = onNavigationBack
    }
    
    private func setupViews() {
        btnRemoveFile.isHidden = true
        btnImport.isEnabled = false
    }
    
    private func updateViews() {
        btnRemoveFile.isHidden = fContent == nil
        lblFileName.stringValue = fContent == nil ? "" : lblFileName.stringValue
        btnImport.isEnabled = fContent != nil
    }
    
    @IBAction func back(_ sender: Any) {
        self.onNavigationBack?(shouldUpdate)
        self.view.removeFromSuperview()
        self.removeFromParent()
    }
    
    @IBAction func `import`(_ sender: Any) {
        guard let data = fContent else {return}
        
        // Handle import logic here
        let decoder = JSONDecoder()
        
        do {
            let importedData = try decoder.decode(ImportExportData.self, from: data)
            self.merge(importedData: importedData.data)
        } catch {
            NSLog(error.localizedDescription)
            Util.showErrorDialog(text: "Imported Data is invalid, please try again")
        }
        
        // Remove file
        fContent = nil
    }
    
    private func merge(importedData: [Session]) {
        var newSessions = [Session]()
        
        for session in importedData {
            guard let idx = LocalStorage.sessions.firstIndex(where: { $0.id == session.id }) else {
                newSessions.append(session)
                continue
            }
            
            // Update old Session
            var newTabs = [Tab]()
            
            for newTab in session.tabs {
                if LocalStorage.sessions[idx].tabs.contains(where: { $0.id == newTab.id }) {
                    // Don't touch old tab
                    continue
                }
                
                newTabs.append(newTab)
            }
            
            var updatedSession = LocalStorage.sessions[idx]
            updatedSession.tabs.append(contentsOf: newTabs)
            
            LocalStorage.sessions[idx] = updatedSession

        }
        
        LocalStorage.sessions = LocalStorage.sessions + newSessions
        self.shouldUpdate = true
    }
    
    @IBAction func removeFile(_ sender: Any) {
        self.fContent = nil
    }
    
    @IBAction func uploadFile(_ sender: Any) {
        let dialog = NSOpenPanel()
        
        dialog.title                   = "Choose a .json file"
        dialog.canChooseDirectories    = false
        dialog.showsHiddenFiles        = false
        dialog.showsResizeIndicator    = false
        dialog.allowedFileTypes        = ["json"]
        
        if dialog.runModal() == .OK {
            guard let fileURL = dialog.url else {return}
            do {
                self.fContent = try Data(contentsOf: fileURL)
                self.lblFileName.stringValue = fileURL.lastPathComponent
            } catch {
                NSLog(error.localizedDescription)
                Util.showErrorDialog(text: "Couldn't read the file, please try again")
            }
        }
    }
}
