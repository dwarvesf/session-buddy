//
//  DetailViewController.swift
//  SessionRestore Extension
//
//  Created by phucld on 4/27/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import SafariServices

class DetailViewController: NSViewController {
    
    @IBOutlet weak var sessionName: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    
    @IBOutlet weak var btnAddUrl: NSButton!
    @IBOutlet weak var containerEditview: NSView!
    @IBOutlet weak var txtfieldURL: NSTextField!
    @IBOutlet weak var btnAdd: NSButton!
    
    @IBOutlet weak var containerViewActions: NSStackView!
    @IBOutlet weak var containerViewActionInput: NSView!
    @IBOutlet weak var btnAction: NSButton!
    @IBOutlet weak var txtfieldAction: NSTextField!
    
    private var onNavigationBack: ((_ shouldReload: Bool) -> Void)?
    private var onOpenSession: (() -> Void)?
    
    private let session: Session
    private lazy var tabs = session.tabs
    
    /// Update this to true whenever change the data
    private var shouldReload: Bool = false
    
    private var isMultiFuncViewShowing = false
    
    init(session: Session) {
        self.session = session
        super.init(nibName: "DetailViewController", bundle: Bundle.main)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        txtfieldURL.delegate = self
        txtfieldAction.delegate = self
    }
    
    func set(sessionName: String,
             onNavigationBack: @escaping ((Bool) -> Void),
             onOpenSession: @escaping (() -> Void)
    ) {
        self.sessionName.stringValue = sessionName
        self.onNavigationBack = onNavigationBack
        self.onOpenSession = onOpenSession
    }
    
    @IBAction func navigationBack(_ sender: Any) {
        self.onNavigationBack?(self.shouldReload)
        self.view.removeFromSuperview()
        self.removeFromParent()
    }
    
    @IBAction func openSession(_ sender: Any) {
        self.onOpenSession?()
    }
    
    @IBAction func closeActionInput(_ sender: Any) {
        containerViewActionInput.isHidden = true
        containerViewActions.isHidden = false
        txtfieldAction.stringValue = ""
    }
    
    @IBAction func triggerRenameInput(_ sender: Any) {
        btnAction.title = "Rename"
        btnAction.isEnabled = true
        containerViewActionInput.isHidden = false
        containerViewActions.isHidden = true
        
        txtfieldAction.stringValue = session.title
        txtfieldAction.becomeFirstResponder()
    }
    
    @IBAction func triggerShareInput(_ sender: Any) {
        btnAction.title = "Share"
        btnAction.isEnabled = false
        containerViewActionInput.isHidden = false
        containerViewActions.isHidden = true
        txtfieldAction.becomeFirstResponder()
    }
    
    @IBAction func doAction(_ sender: NSButton) {
        let nameOrEmail = txtfieldAction.stringValue
        switch sender.title {
        case "Rename": self.rename(newName: nameOrEmail)
        case "Share": self.share(with: nameOrEmail)
        default: break
        }
        
        self.closeActionInput(self)
    }
    
    private func rename(newName: String) {
        guard
            !newName.isEmpty,
            newName != session.title
            else {return}
        
        self.sessionName.stringValue = newName
        
        let localSessions = LocalStorage.sessions
        guard let sessionIndex = localSessions.firstIndex(where: { $0.id == self.session.id }) else {return}
        
        LocalStorage.sessions[sessionIndex].title = newName
        
        self.shouldReload = true
    }
    
    private func share(with email: String) {
        do {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .prettyPrinted
            let data = try jsonEncoder.encode(ImportExportData(data: [session]))
            
            let tempDir = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = tempDir.appendingPathComponent("\(Date().saveFileStringFormat()).json")
            
            try data.write(to: fileURL)
            
            let sharingService = NSSharingService(named: .composeEmail)
            sharingService?.delegate = self
            
            sharingService?.recipients = [email]
            sharingService?.subject = "Sharing my Session Buddy session"
            let items: [Any] = ["see attachment", fileURL]
            sharingService?.perform(withItems: items)
            
        } catch {
            NSLog(error.localizedDescription)
            Util.showErrorDialog(text: "Data is corrupted, please contact us for more support")
        }
    }
    
    @IBAction func deleteSession(_ sender: Any) {
        let localSessions = LocalStorage.sessions
        
        guard let sessionIndex = localSessions.firstIndex(where: { $0.id == self.session.id }) else {return}
        
        LocalStorage.sessions.remove(at: sessionIndex)
        
        self.shouldReload = true
        
        self.navigationBack(self)
    }
    
    @IBAction func triggerAddURL(_ sender: Any) {
        btnAddUrl.isHidden = true
        containerEditview.isHidden = false
        SFSafariApplication.getActiveWindow { window in
            window?.getActiveTab(completionHandler: { tab in
                tab?.getActivePage(completionHandler: { page in
                    page?.getPropertiesWithCompletionHandler { properties in
                        DispatchQueue.main.async {
                            self.txtfieldURL.stringValue = properties?.url?.absoluteString ?? ""
                            self.txtfieldURL.becomeFirstResponder()
                            self.btnAdd.isEnabled = !self.txtfieldURL.stringValue.isEmpty
                        }
                    }
                })
            })
        }
    }
    
    @IBAction func cancelAddURL(_ sender: Any) {
        self.txtfieldURL.stringValue = ""
        self.containerEditview.isHidden = true
        self.btnAddUrl.isHidden = false
    }
    
    @IBAction func addURL(_ sender: Any) {
        self.containerEditview.isHidden = true
        self.btnAddUrl.isHidden = false
        
        guard !txtfieldURL.stringValue.isEmpty else {return}
        
        let newTab = Tab(title: txtfieldURL.stringValue, url: txtfieldURL.stringValue)
        self.tabs.append(newTab)
        self.updateSession(with: self.tabs)
        
        DispatchQueue.main.async {
            self.tableView.insertRows(at: .init(integer: self.tabs.count - 1), withAnimation: .effectFade)
        }
        
        self.txtfieldURL.stringValue = ""
        self.shouldReload = true
    }
}

extension DetailViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return tabs.count
    }
}


extension  DetailViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tabCell"), owner: nil) as? TabCellView else {return nil}
        
        cell.set(
            title: tabs[row].title,
            onDelete: self.onDelete(at: row)
        )
        
        return cell
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        guard let url = URL(string: tabs[row].url) else {return true}
        
        SFSafariApplication.getActiveWindow { window in
            window?.openTab(with: url, makeActiveIfPossible: true, completionHandler: nil)
        }
        
        return false
    }
    
    private func onDelete(at index: Int) -> (() -> Void) {
        return {
            self.tabs.remove(at: index)
            self.updateSession(with: self.tabs)
            
            DispatchQueue.main.async {
                self.tableView.removeRows(at: .init(integer: index), withAnimation: .effectFade)
            }
            
            self.shouldReload = true
        }
    }
    
    private func updateSession(with tabs: [Tab]) {
        var newSession = self.session
        newSession.tabs = self.tabs
        
        var localSessions = LocalStorage.sessions
        guard let sessionIndex = localSessions.firstIndex(where: { $0.id == self.session.id }) else {return}
        
        localSessions[sessionIndex] = newSession
        
        LocalStorage.sessions = localSessions
    }
}

extension DetailViewController: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        let isBtnActionEnable = !txtfieldAction.stringValue.isEmpty
        btnAction.isEnabled = isBtnActionEnable
        
        let isBtnURlEnable = !txtfieldURL.stringValue.isEmpty
        btnAdd.isEnabled = isBtnURlEnable
    }
}

extension DetailViewController: NSSharingServiceDelegate {
    //    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
    //
    //    }
}

extension DetailViewController: NSSharingServicePickerDelegate {
    //    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {
    
    //    }
}
