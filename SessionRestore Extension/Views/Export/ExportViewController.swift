//
//  ExportViewController.swift
//  Session Buddy Extension
//
//  Created by phucld on 5/15/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Cocoa


class ExportViewController: NSViewController {
    
    struct ExportItem {
        let id: String
        let title: String
        var isSelected: Bool
    }
    
    @IBOutlet weak var btnExport: NSButton!
    @IBOutlet weak var comboBoxFormat: NSComboBox!
    @IBOutlet weak var tableView: NSTableView!
    
    var onNavigationBack: ((Bool) -> Void)?
    
    private var exportItems = [ExportItem]()
    private var selectedCount = 0 {
        didSet {
            btnExport.isEnabled = selectedCount > 0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        exportItems = LocalStorage.sessions.map {
            ExportItem(id: $0.id, title: $0.title, isSelected: false)
        }
        
        btnExport.isEnabled = false
        
        comboBoxFormat.selectItem(at: 0)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.selectionHighlightStyle = .none
    }
    
    func set(onNavigationBack: @escaping ((Bool) -> Void)) {
        self.onNavigationBack = onNavigationBack
    }
    
    @IBAction func export(_ sender: Any) {
        guard selectedCount > 0 else {return}
        
        let selectedItemIDs = exportItems.filter(\.isSelected).map(\.id)
        let needExportedItems = LocalStorage.sessions.filter { selectedItemIDs.contains($0.id) }
        
        do {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .prettyPrinted
            let data = try jsonEncoder.encode(ImportExportData(data: needExportedItems))
            
            saveFile(with: data)
        } catch {
            NSLog(error.localizedDescription)
            Util.showErrorDialog(text: "Data is corrupted, please contact us for more support")
        }
    }
    
    @IBAction func checkAll(_ sender: NSButton) {
        self.toggleCheckAll(isChecked: sender.state == .on)
    }
    
    @IBAction func back(_ sender: Any) {
        self.onNavigationBack?(false)
        self.view.removeFromSuperview()
        self.removeFromParent()
    }
    
    private func saveFile(with content: Data) {
        let dialog = NSSavePanel()
        dialog.title = "Save export file"
        dialog.nameFieldStringValue = "\(Date().saveFileStringFormat()).json"
        
        if dialog.runModal() == .OK {
            guard let fileURL = dialog.url else {return}
            do {
                try content.write(to: fileURL, options: .atomic)
            } catch {
                NSLog(error.localizedDescription)
                Util.showErrorDialog(text: "Couldn't save the file, please try again")
            }
        }
    }
    
    private func toggleCheckAll(isChecked: Bool) {
        for idx in 0 ..< exportItems.count {
            exportItems[idx].isSelected = isChecked
        }
        
        selectedCount = isChecked ? exportItems.count : 0
        
        tableView.reloadData()
    }
}

extension ExportViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return exportItems.count
    }
}

extension ExportViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("exportCell"), owner: self) as? ExportCellView else {return nil}
        
        cell.set(title: exportItems[row].title,isChecked: exportItems[row].isSelected) { isSelected in
            self.updateItem(at: row, isSelected: isSelected)
        }
        
        return cell
    }
    
    private func updateItem(at index: Int, isSelected: Bool) {
        exportItems[index].isSelected = isSelected
        selectedCount = isSelected ? selectedCount + 1 : selectedCount - 1
    }
}
