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
    
    @IBOutlet weak var viewContainerFunctions: NSView!
    @IBOutlet weak var viewContainerConstaintHeight: NSLayoutConstraint!
    
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
    
    @IBAction func triggerMultiFunc(_ sender: Any) {
        isMultiFuncViewShowing.toggle()
        
        DispatchQueue.main.async {
            NSAnimationContext.runAnimationGroup({ context  in
                context.duration = 0.25
                self.viewContainerConstaintHeight.animator().constant = self.isMultiFuncViewShowing ? 20 : 0
            }) { self.viewContainerConstaintHeight.constant = self.isMultiFuncViewShowing ? 20 : 0 }
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
                        }
                    }
                })
            })
        }
    }
    
    
    @IBAction func addURL(_ sender: Any) {
        containerEditview.isHidden = true
        btnAddUrl.isHidden = false
        
        guard !txtfieldURL.stringValue.isEmpty else {return}
        
        let newTab = Tab(title: txtfieldURL.stringValue, url: txtfieldURL.stringValue)
        self.tabs.append(newTab)
        self.updateSession(with: self.tabs)
        
        DispatchQueue.main.async {
            self.tableView.insertRows(at: .init(integer: self.tabs.count - 1), withAnimation: .effectFade)
        }
        
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
        
        SFSafariApplication.openWindow(with: url)
        return true
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
