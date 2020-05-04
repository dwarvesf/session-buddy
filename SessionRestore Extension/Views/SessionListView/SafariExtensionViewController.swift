//
//  SafariExtensionViewController.swift
//  SessionRestore Extension
//
//  Created by phucld on 4/13/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController {
    
    @IBOutlet weak var mainView: NSView!
    @IBOutlet weak var tableView: NSTableView!
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        return shared
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    @IBAction func saveCurrenSession(_ sender: Any) {
        SFSafariApplication.getActiveWindow { [weak self] window in
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
                                let dateFormatter = DateFormatter()
                                dateFormatter.locale = .current
                                dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
                                let title = dateFormatter.string(from: Date())
                                let newSession = Session(title: title, tabs: sessionTabs)
                                newSession.save()
                                DispatchQueue.main.async {
                                    self?.tableView.insertRows(at: .init(integer: LocalStorage.sessions.count - 1), withAnimation: .effectFade)
                                    self?.tableView.scrollToEndOfDocument(self)
                                }
                            }
                                                  
                        }
                    }
                }
            }
        }
    }
    
}

extension SafariExtensionViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return LocalStorage.sessions.count
    }
}

extension  SafariExtensionViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "sessionCell"), owner: nil) as? SessionCellView else {return nil}
        
        let currentSession = LocalStorage.sessions[row]
        
        cell.set(
            title: currentSession.title,
            tabCount: currentSession.tabs.count,
            onDetailClick: onDetailClick(at: row),
            onRestoreSession: onRestore(at: row),
            onUpdateSession: onUpdateSession(at: row)
        )

        return cell
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        guard let cell = tableView.rowView(atRow: row, makeIfNecessary: false) else { return true }
        
        cell.wantsLayer = true
        cell.layer?.backgroundColor = .clear
        
        return true
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
            var localSessions = LocalStorage.sessions
            let updateSession = Session(title: newSessionName, tabs: localSessions[index].tabs)
            localSessions[index] = updateSession
            LocalStorage.sessions = localSessions
        }
    }
    
    private func onDetailClick(at row: Int) -> (() -> Void) {
        return {
            let child = DetailViewController(session: LocalStorage.sessions[row])
            self.addChild(child)
            self.view.addSubview(child.view)
            child.set(
                sessionName: LocalStorage.sessions[row].title,
                onNavigationBack: self.onNavigationBack,
                onOpenSession: self.onRestore(at: row)
            )
            self.mainView.isHidden = true
        }
    }
    
    private func onNavigationBack(_ shouldReload: Bool) {
        self.mainView.isHidden = false
        if shouldReload {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
}
