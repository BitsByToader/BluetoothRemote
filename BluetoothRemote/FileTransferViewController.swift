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
    
    let udp = UDPClient(address: "192.168.100.30", port: 5005)
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        print("Loaded!")
        if let userContent = contents as? Data {
            data = userContent
            print(data)
        }
    }
    
    func sendData() {
        let packet = data!
        var tempPacket = Data()
        
        var i = 0
        for byte in packet {
            if ( i != 9 ) {
                tempPacket.append(byte)
                i += 1
            } else {
                tempPacket.append(byte)
                udp.send(data: tempPacket)
                tempPacket = Data()
                i = 0
            }
        }
        if ( i != 0 ) {
            let lastBytes = packet.advanced(by: packet.count - i)
            print(lastBytes)
            udp.send(data: lastBytes)
        }
        
        let result = udp.send(data: [0xFF])
        print(result)
        udp.close()
    }
}

class FileTransferViewController: UIViewController, UIDocumentPickerDelegate {
    let importMenu: UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: [String("public.data")], in: .import)
    
    

    @IBAction func openDocumentPicker(_ sender: UIButton) {
        print("Hello")
        self.present(importMenu, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .formSheet
        importMenu.shouldShowFileExtensions = true
    }
    
    //MARK: DocumentPicker callbacks
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print(urls)
        let url = urls[0]
        let document = MyDocument(fileURL: url)
        document.open(completionHandler: { (Bool) -> Void in
            print("Opened!")
            print(document)
            
            document.sendData()
            
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
}
