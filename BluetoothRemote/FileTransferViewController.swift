//
//  FileTransferViewController.swift
//  BluetoothRemote
//
//  Created by Ifrim Tudor on 06/04/2020.
//  Copyright © 2020 tudor. All rights reserved.
//

import UIKit

class MyDocument: UIDocument {
    var data: Data?
    var name: String?
    
    let udpConnection = UDPClient(address: "192.168.100.34", port: 5005)
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        print("Loaded!")
        if let userContent = contents as? Data {
            data = userContent
            //print(data)
        }
    }
}

class FileTransferViewController: UIViewController, UIDocumentPickerDelegate {
    //MARK: Variables
    let importMenu: UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: [String("public.data")], in: .import)
    
    var fileBroadCastConnection: UDPBroadcastConnection!
    
    var udpServer: UDPServer? = nil
    var receveingFile: Bool = false
    var bytesReceived: Int = 0
    var receivedFile: Data = Data()
    var fileSizeInBytes: Int = 0
    var receivedFileName: String?
    
    //MARK: Outlets
    
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var progressPercentage: UILabel!
    @IBOutlet weak var fileSize: UILabel!
    @IBOutlet weak var fileInfoView: UIView!
    @IBOutlet weak var serverSwitch: UISwitch!
    
    //MARK: Actions
    @IBAction func AddDocument(_ sender: UIBarButtonItem) {
        self.present(importMenu, animated: true, completion: nil)
    }
        
    @IBAction func serverChangedState(_ sender: UISwitch) {
        
        if ( sender.isOn ) {
            print("server on")
            udpServer = UDPServer(address: "255.255.255.255", port: 5006)
            receivedFile = Data()
            DispatchQueue.global(qos: .background).async {
                self.receiveData()
            }
        } else {
            print("server off")
            udpServer?.close()
            receivedFile = Data()
            //fileBroadCastConnection.closeConnection()
            //serverSwitchOutlet.isEnabled = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .formSheet
        importMenu.shouldShowFileExtensions = true
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        
        /*do { fileBroadCastConnection = try UDPBroadcastConnection(
        port: 5005,
        handler: { [weak self] (ipAddress: String, port: Int, response: Data) -> Void in
            print(response)
            if ( !self!.receveingFile ) {
                let packet = String(bytes: response, encoding: String.Encoding.utf8)
                let fileDescription = packet?.components(separatedBy: "/")
                
                self!.receivedFileName = fileDescription![0]
                self!.fileSizeInBytes = Int(fileDescription![1])!
                
                print("\(String(describing: self!.receivedFileName)) -> \(self!.fileSizeInBytes)")
                
                self!.receveingFile = true
            } else if ( self!.receveingFile ) {
                print(String(bytes: response, encoding: String.Encoding.utf8) as Any)
                self!.receivedFile += response
                print(self!.receivedFile.count)
                if ( self!.receivedFile.count == self!.fileSizeInBytes ) {
                    self!.receveingFile = false
                    
                    let activityViewController = UIActivityViewController(activityItems: [self!.receivedFile], applicationActivities: nil)
                    activityViewController.popoverPresentationController?.sourceView = self!.view // so that iPads won't crash
                    
                    // exclude some activity types from the list (optional)
                    activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.postToFacebook ]

                    // present the view controller
                    self!.present(activityViewController, animated: true, completion: nil)
                }
            }
        },
        errorHandler: { (error) in
          print(error)
        })} catch {
            print("error setting up broadcast connection")
        }*/
    }
    
    //MARK: DocumentPicker callbacks
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print(urls)
        let url = urls[0]
        let document = MyDocument(fileURL: url)
        document.open(completionHandler: { (Bool) -> Void in
            document.name = url.lastPathComponent
            
            self.progressPercentage.text = "0%"
            self.progressBar.progress = 0
            
            self.fileNameLabel.text = document.name
            
            let size: Double = Double(document.data!.count) / (1024*1024)
            self.fileSize.text = "\( String(format: "%.2f", size) )MB"
            
            self.fileInfoView.isHidden = false
            
            DispatchQueue.main.async {
                self.sendData(document: document)
            }
            
            document.close(completionHandler: { (Bool) -> Void in
                print("Closed!")
            })
        })
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Big Oof")
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    //MARK: Methods
    func sendData(document: MyDocument) {
        let packet = document.data!
        var tempPacket = Data()
        
        let _ = document.udpConnection.send(string: "\(document.name!)/\(document.data!.count)")
        
        var i = 0
        var bytesSent = 0
        for byte in packet {
            tempPacket.append(byte)
            if ( i != 999 ) {
                i += 1
            } else {
                let _ = document.udpConnection.send(data: tempPacket)
                tempPacket = Data()
                i = 0
                
                bytesSent += 1000
                let percentage = ( 100 * bytesSent ) / packet.count
                progressPercentage.text = "\(percentage)%"
                progressBar.progress = Float(percentage) / 100
            }
        }
        
        if ( i != 0 ) {
            let lastBytes = packet.advanced(by: packet.count - i)
            print(lastBytes)
            let _ = document.udpConnection.send(data: lastBytes)
        }
        
        document.udpConnection.close()
        
        progressPercentage.text = "100%"
        progressBar.progress = 1
    }
    
    func receiveData() {
        let (buff, _, _) = udpServer?.recv(1000) ?? ([0x0], "", 1)
        if ( !receveingFile ) {
            let packet = String(bytes: buff ?? [], encoding: String.Encoding.utf8)
            let fileDescription = packet?.components(separatedBy: "/")
            
            receivedFileName = fileDescription![0]
            fileSizeInBytes = Int(fileDescription![1]) ?? 0
            
            print("\(String(describing: receivedFileName)) -> \(fileSizeInBytes)")
            
            receveingFile = true
            
            receiveData()
            return
        } else if ( receveingFile ) {
            print(buff as Any)
            receivedFile += buff!
            print(receivedFile.count)
            if ( receivedFile.count == fileSizeInBytes ) {
                receveingFile = false
                
                DispatchQueue.main.async {
                    let activityViewController = UIActivityViewController(activityItems: [self.receivedFile], applicationActivities: nil)
                    activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
                    
                    // exclude some activity types from the list (optional)
                    activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.postToFacebook ]

                    // present the view controller
                    self.present(activityViewController, animated: true, completion: nil)
                    
                    self.serverSwitch.setOn(false, animated: true)
                    self.udpServer?.close()
                }
                return
            } else if ( receivedFile.count < fileSizeInBytes) {
                receiveData()
            }
        }
    }
    
    /*func receiveData() {
        do { fileBroadCastConnection = try UDPBroadcastConnection(
        port: 5006,
        handler: { [weak self] (ipAddress: String, port: Int, response: Data) -> Void in
            print(response)
            if ( !self!.receveingFile ) {
                let packet = String(bytes: response, encoding: String.Encoding.utf8)
                let fileDescription = packet?.components(separatedBy: "/")
                
                self!.receivedFileName = fileDescription![0]
                self!.fileSizeInBytes = Int(fileDescription![1])!
                
                print("\(self!.receivedFileName) -> \(self!.fileSizeInBytes)")
                
                self!.receveingFile = true
            } else if ( self!.receveingFile ) {
                print(String(bytes: response, encoding: String.Encoding.utf8))
                self!.receivedFile += response
                print(self!.receivedFile.count)
                if ( self!.receivedFile.count == self!.fileSizeInBytes ) {
                    self!.receveingFile = false
                    
                    let activityViewController = UIActivityViewController(activityItems: [self!.receivedFile], applicationActivities: nil)
                    activityViewController.popoverPresentationController?.sourceView = self!.view // so that iPads won't crash
                    
                    // exclude some activity types from the list (optional)
                    activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.postToFacebook ]

                    // present the view controller
                    self!.present(activityViewController, animated: true, completion: nil)
                }
            }
        },
        errorHandler: { (error) in
          print(error)
        })} catch {
            print("error setting up broadcast connection")
        }
    }*/
}
