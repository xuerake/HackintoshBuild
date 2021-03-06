//
//  DailyBuild.swift
//  HackintoshBuild
//
//  Created by wbx on 2020/8/28.
//  Copyright © 2020 bugprogrammer. All rights reserved.
//

import Cocoa
import Alamofire

class DailyBuild: OutBaseObject {
        
    @IBOutlet weak var downloadPathController: NSPathControl!
    @IBOutlet weak var downloadButton: NSButton!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var downloadProgress: NSProgressIndicator!
    @IBOutlet weak var fillButton: NSButton!
    @IBOutlet weak var openButton: NSButton!
    @IBOutlet weak var refreshButton: NSButton!
    
    let filemanager = FileManager.default
    var downloadPath: String = ""
    var tag: String = ""
    var name: String = ""

    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let url = UserDefaults.standard.url(forKey: "url") {
            if filemanager.fileExists(atPath: url.path) {
                downloadPathController.url = url
                downloadPath = url.path
            }
        }
        
        fillButton.isHidden = true
        downloadProgress.isHidden = true
        downloadButton.isBordered = false
        downloadButton.bezelStyle = .recessed
        let image = MyAsset.download.image
        image.isTemplate = true
        downloadButton.image = image
        
        let image1 = MyAsset.open1.image
        image1.isTemplate = true
        openButton.isBordered = false
        openButton.bezelStyle = .recessed
        openButton.image = image1
        
        let image2 = MyAsset.refresh1.image
        image2.isTemplate = true
        refreshButton.isBordered = false
        refreshButton.bezelStyle = .recessed
        refreshButton.image = image2
        refreshButton.isHidden = true
        
        getLatest()
        
        if filemanager.fileExists(atPath: downloadPath + "/" + nameLabel.stringValue) {
            openButton.isEnabled = true
        } else {
            openButton.isEnabled = false
        }
    }
        
    @IBAction func refresh(_ sender: Any) {
        refreshButton.isHidden = true
        
        getLatest()
    }
    
    func getLatest() {
        let headers: HTTPHeaders = [
            "Accept": "application/json"
        ]

        AF.request("https://github.com/bugprogrammer/HackinPlugins/releases/latest", method: .get, headers: headers).validate().responseJSON { response in
            switch response.result {
                case .success(let dict):
                    self.tag = (dict as! NSDictionary)["tag_name"] as! String
                    self.nameLabel.textColor = NSColor.labelColor
                    self.nameLabel.stringValue = "HackinPlugins_" + self.tag.replacingOccurrences(of: "-", with: "") + ".zip"
                    self.downloadButton.isEnabled = true
                case .failure(_):
                    self.nameLabel.textColor = NSColor.systemRed
                    self.nameLabel.stringValue = "网络错误"
                    self.downloadButton.isEnabled = false
                    self.refreshButton.isHidden = false
                }
                
        }
    }
    
    @IBAction func setPath(_ sender: Any) {
        if let url = downloadPathController.url {
            UserDefaults.standard.set(url, forKey: "url")
            downloadPath = url.path
        }
    }
    @IBAction func download(_ sender: Any) {
        name = nameLabel.stringValue
        setStatus(true, true)
        if filemanager.fileExists(atPath: downloadPath + "/" + name) {
            try! filemanager.removeItem(atPath: downloadPath + "/" + nameLabel.stringValue)
        }
            
        let destination: DownloadRequest.Destination = { _, _ in
            let fileURL = URL(fileURLWithPath: self.downloadPath + "/" + self.name)
                
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }

        AF.download("https://github.com/bugprogrammer/HackinPlugins/releases/download/" + tag + "/HackinPlugins_" + tag.replacingOccurrences(of: "-", with: "") + ".zip", to: destination).downloadProgress{ progress in
            self.downloadProgress.isHidden = false
            self.downloadProgress.isIndeterminate = false
            self.downloadProgress.minValue = 0.0
            self.downloadProgress.maxValue = 1.0
            self.downloadProgress.doubleValue = progress.fractionCompleted
        }.responseData { response in
            debugPrint(response)
            switch response.result {
            case .success(_):
                self.setStatus(false, true)
                let alert = NSAlert()
                alert.messageText = "下载成功"
                alert.runModal()
            case .failure(_):
                self.setStatus(false, false)
                let alert = NSAlert()
                alert.messageText = "下载失败"
                alert.runModal()
            }
        }
        
    }
        
    @IBAction func open(_ sender: Any) {
        NSWorkspace.shared.selectFile(downloadPath + "/" + nameLabel.stringValue, inFileViewerRootedAtPath: "")
    }
    
    func setStatus(_ isRunning: Bool, _ isComplace: Bool) {
        if isRunning {
            downloadProgress.doubleValue = 0.0
            downloadPathController.isEnabled = false
            downloadButton.isEnabled = false
            downloadProgress.isHidden = false
            fillButton.isHidden = true
            openButton.isEnabled = false
        } else {
            downloadPathController.isEnabled = true
            downloadButton.isEnabled = true
            downloadProgress.isHidden = true
            let image1 = MyAsset.full.image
            let image2 = MyAsset.failed.image
            fillButton.isBordered = false
            fillButton.bezelStyle = .recessed
            if isComplace {
                fillButton.image = image1
                fillButton.bezelColor = NSColor(named: "ColorGreen")
                openButton.isEnabled = true
            } else {
                fillButton.image = image2
                fillButton.bezelColor = NSColor.systemRed
                openButton.isEnabled = false
            }
            
            fillButton.isHidden = false
        }
    }
}
