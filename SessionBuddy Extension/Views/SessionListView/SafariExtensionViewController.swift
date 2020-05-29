//
//  SafariExtensionViewController.swift
//  SessionRestore Extension
//
//  Created by phucld on 4/13/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController {
    
    @IBOutlet weak var outlineView: SidebarView!
    @IBOutlet weak var constaintViewHeight: NSLayoutConstraint!
    @IBOutlet weak var mainView: NSView!
    @IBOutlet weak var searchBar: NSSearchField!
    @IBOutlet weak var searchTableView: NSTableView!
    @IBOutlet weak var btnSaveSession: NSButton!
    @IBOutlet weak var outlineScrollView: NSScrollView!
    @IBOutlet weak var searchScrollView: NSScrollView!
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        return shared
    }()
    
    private var viewHeight: CGFloat = 262
    
    private var searchResult = [String]() {
        didSet {
            self.searchTableView.reloadData()
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        outlineView.delegate = self
        outlineView.dataSource = self
        outlineView.selectionHighlightStyle = .none
        
        searchTableView.delegate = self
        searchTableView.dataSource = self
        searchTableView.selectionHighlightStyle = .none
        
        searchBar.delegate = self
        
        viewHeight = self.view.frame.height
    }
    
    @objc
    private func showImport() {
        let child = ImportViewController()
        
        self.push(vc: child)
        
        child.set(onNavigationBack: self.onNavigationBack)
    }
    
    @objc
    private func showExport() {
        let child = ExportViewController()
        
        self.push(vc: child)
        
        child.set(onNavigationBack: self.onNavigationBack)
    }
    
    @objc
    private func showAbout() {
        openWeb(url: URL(string: "https://github.com/dwarvesf/session-buddy")!)
    }
    
    @objc
    private func showHelp() {
        openWeb(url: URL(string: "https://github.com/dwarvesf/session-buddy/issues")!)
    }
    
    @IBAction func openContextMenu(_ sender: NSButton) {
        let menu = NSMenu()
        
        menu.addItem(withTitle: "Import...", action: #selector(showImport), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Export...", action: #selector(showExport), keyEquivalent: "").target = self
        
        menu.addItem(.separator())
        
        menu.addItem(withTitle: "About", action: #selector(showAbout), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Help", action: #selector(showHelp), keyEquivalent: "").target = self
        
        menu.popUp(positioning: nil, at: .init(x: 0, y: 26), in: sender)
    }
    
    @IBAction func searchSession(_ sender: NSSearchField) {
        let hideSearching = sender.stringValue.isEmpty
        outlineScrollView.isHidden = !hideSearching
        btnSaveSession.isHidden = !hideSearching
        
        searchScrollView.isHidden = hideSearching
        
        searchResult = LocalStorage.sessions
            .map { $0.tabs }
            .flatMap { $0 }
            .filter { $0.url.lowercased().contains(sender.stringValue.lowercased()) }
            .map(\.url)
    }
    
    @IBAction func saveCurrenSession(_ sender: Any) {
        SFSafariApplication.getActiveWindow { window in
            window?.getAllTabs { tabs in
                var sessionTabs = [Tab]()
                
                for (index, tab) in tabs.enumerated() {
                    tab.getActivePage { page in
                        page?.getPropertiesWithCompletionHandler { properties in
                            if let url = properties?.url?.absoluteString,
                                let title = properties?.title {
                                sessionTabs.append(Tab(title: title, url: url))
                            }
                            
                            // Last element
                            if index == tabs.count - 1 {
                                let title = Date().commonStringFormat()
                                let newSession = Session(title: title, tabs: sessionTabs)
                                newSession.save()
                                DispatchQueue.main.async {
                                    self.outlineView.insertItems(at: .init(integer: LocalStorage.sessions.count - 1), inParent: nil, withAnimation: .effectFade)
                                    self.outlineView.scrollToEndOfDocument(self)
                                }
                            }
                                                  
                        }
                    }
                }
            }
        }
    }
    
    private func openWeb(url: URL) {
        SFSafariApplication.getActiveWindow { window in
            window?.openTab(with: url, makeActiveIfPossible: true, completionHandler: nil)
        }
    }
}


extension SafariExtensionViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let session = item as? Session {
            return session.tabs.count
        }
        
        return LocalStorage.sessions.count
    }
}

extension SafariExtensionViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let session = item as? Session {
            return session.tabs[index]
        }
        
        return LocalStorage.sessions[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let session = item as? Session {            
            return session.tabs.count > 0
        }
        
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        guard
            let tab = item as? Tab,
            let url = URL(string: tab.url)
            else {return false}
        
        openWeb(url: url)
        
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var view: NSTableCellView?
        
        if let session = item as? Session {
            
            let sessionCell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "sessionCell"), owner: self) as? SessionCellView
            
            let row = outlineView.row(forItem: item)
            
            sessionCell?.set(
                title: session.title,
                tabCount: session.tabs.count,
                onDetailClick: onDetailClick(at: row),
                onRestoreSession: onRestore(at: row),
                onUpdateSession: onUpdateSession(at: row))
            
            view = sessionCell
            
        }
        
        if let tab = item as? Tab {
            let tabCell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "sessionTabCell"), owner: self) as? SessionTabCellView
            
            tabCell?.set(title: tab.title)
            
            view = tabCell
        }
        
        return view
    }
    
    private func onRestore(at index: Int) -> (()->Void) {
        return {
            let urls = LocalStorage.sessions[index].tabs.map { $0.url }
            guard let firstURL = URL(string: urls.first ?? "") else {return}
            
            DispatchQueue.main.async {
                SFSafariApplication.openWindow(with: firstURL) { window in
                    let restURLString = urls.dropFirst(1)
                    
                    for urlString in restURLString {
                        guard let url = URL(string: urlString) else {break}
                        window?.openTab(with: url, makeActiveIfPossible: true)
                    }
                }
                
            }
        }
    }
    
    private func onUpdateSession(at index: Int) -> ((String)->Void) {
        return  { newSessionName in
            LocalStorage.sessions[index].title = newSessionName
            LocalStorage.sessions[index].isBackup = false
        }
    }
    
    private func onDetailClick(at index: Int) -> (() -> Void) {
        return {
            let child = DetailViewController(session: LocalStorage.sessions[index])
            
            self.push(vc: child)
            
            child.set(
                sessionName: LocalStorage.sessions[index].title,
                onNavigationBack: self.onNavigationBack,
                onOpenSession: self.onRestore(at: index)
            )
        }
    }
    
    private func push(vc: NSViewController) {
        self.addChild(vc)
        self.view.addSubview(vc.view)
        self.animateContainerView(height: vc.view.frame.height, isHidden: true)
    }
    
    private func onNavigationBack(_ shouldReload: Bool) {
        
        animateContainerView(height: 262, isHidden: false)
        
        if shouldReload {
            self.outlineView.reloadData()
        }
    }
    
    private func animateContainerView(height: CGFloat, isHidden: Bool) {
        self.mainView.isHidden = true
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            self.constaintViewHeight.animator().constant = height
            
        }) {
            self.constaintViewHeight.constant = height
            self.mainView.isHidden = isHidden
        }
    }
}


extension SafariExtensionViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return searchResult.count
    }
}

extension SafariExtensionViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "searchCell"), owner: self) as? SearchCellView
        cell?.set(title: searchResult[row], with: searchBar.stringValue.lowercased())
        return cell
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        guard let url = URL(string: searchResult[row]) else {return false}
        openWeb(url: url)
        return true
    }
}

extension SafariExtensionViewController: NSSearchFieldDelegate {
    
    func searchFieldDidEndSearching(_ sender: NSSearchField) {
        self.outlineScrollView.isHidden = false
        self.btnSaveSession.isHidden = false
        self.searchScrollView.isHidden = true
    }
}
