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
            print(data)
        }
    }
}

class FileTransferViewController: UIViewController, UIDocumentPickerDelegate {
    //MARK: Variables
    let importMenu: UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: [String("public.data")], in: .import)
    
    //MARK: Outlets
    
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var progressPercentage: UILabel!
    @IBOutlet weak var fileSize: UILabel!
    @IBOutlet weak var fileInfoView: UIView!
    
    //MARK: Actions
    @IBAction func AddDocument(_ sender: UIBarButtonItem) {
        self.present(importMenu, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .formSheet
        importMenu.shouldShowFileExtensions = true
        
        navigationController?.navigationBar.prefersLargeTitles = true
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
}
