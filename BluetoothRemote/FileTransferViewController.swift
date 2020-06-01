//
//  FileTransferViewController.swift
//  BluetoothRemote
//
//  Created by Ifrim Tudor on 06/04/2020.
//  Copyright © 2020 tudor. All rights reserved.
//

import UIKit
import Network

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

///TODO: Open the files in a different way when receiving a file from a PC, so I don't need to store the files temporarily in memory
///TODO: Add another view for inserting the IP of the PC, or make a broadcast so the PC responds and shows itself in a table view
///TODO: Analyze why some files don't get sent to the PC all the way through (maybe a python issue, maybe a swift issue)
///TODO: Finish implementing the mouse

class FileTransferViewController: UIViewController, UIDocumentPickerDelegate {
    //MARK: Variables
    let importMenu: UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: [String("public.data")], in: .open)
    
    //var fileBroadCastConnection: UDPBroadcastConnection!
    
    var udpServer: UDPServer? = nil
    var receveingFile: Bool = false
    //var bytesReceived: Int = 0
    var receivedFile: Data = Data()
    var fileSizeInBytes: Int = 0
    var receivedFileName: String?
    
    var connection: NWConnection?
    var hostUDP: NWEndpoint.Host = "255.255.255.255"
    var portUDP: NWEndpoint.Port = 9093
    
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
            connectToUDP(hostUDP, portUDP)
            //udpServer = UDPServer(address: "255.255.255.255", port: 5006)
            //receivedFile = Data()
            //DispatchQueue.global(qos: .background).async {
            //    self.receiveData()
            //}
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
    }
    
    //MARK: DocumentPicker callbacks
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print(urls)
        //let url = urls[0]
        for url in urls {
            let document = MyDocument(fileURL: url)
            document.open(completionHandler: { (Bool) -> Void in
                document.name = url.lastPathComponent
                
                self.progressPercentage.text = "0%"
                self.progressBar.progress = 0
                
                self.fileNameLabel.text = document.name
                
                let size: Double = Double(document.data!.count) / (1024*1024)
                self.fileSize.text = "\( String(format: "%.2f", size) )MB"
                
                self.fileInfoView.isHidden = false
                
                DispatchQueue.global(qos: .background).async {
                    self.sendData(document: document)
                    
                    DispatchQueue.main.async {
                        document.close(completionHandler: { (Bool) -> Void in
                            print("Closed!")
                        })
                    }
                }

            })
        }
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
                DispatchQueue.main.async {
                    self.progressPercentage.text = "\(percentage)%"
                    self.progressBar.progress = Float(percentage) / 100
                }
            }
        }
        
        if ( i != 0 ) {
            let lastBytes = packet.advanced(by: packet.count - i)
            print(lastBytes)
            let _ = document.udpConnection.send(data: lastBytes)
        }
        
        document.udpConnection.close()
        
        DispatchQueue.main.async {
            self.progressPercentage.text = "100%"
            self.progressBar.progress = 1
        }
    }
    
    func receiveData() {
        let (receivingUDPBuffer, _, _) = udpServer?.recv(1000) ?? ([0x0], "", 1)
        if ( receivingUDPBuffer != nil ) {
            if ( !receveingFile ) {
                let packet = String(bytes: receivingUDPBuffer ?? [], encoding: String.Encoding.utf8)
                let fileDescription = packet?.components(separatedBy: "/")
                
                receivedFileName = (fileDescription ?? ["", ""])[0]
                fileSizeInBytes = Int(fileDescription![1]) ?? 0
                
                print("\(String(describing: receivedFileName)) -> \(fileSizeInBytes)")
                
                receivedFile = Data(capacity: fileSizeInBytes)
                
                receveingFile = true
                
                receiveData()
                return
            } else if ( receveingFile ) {
                print(receivingUDPBuffer as Any)
                receivedFile += receivingUDPBuffer ?? [Byte()]
                print(receivedFile.count)
                if ( receivedFile.count == fileSizeInBytes || receivedFile.count > fileSizeInBytes ) {
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
                    return
                }
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
    
    
    
    
    
    func connectToUDP(_ hostUDP: NWEndpoint.Host, _ portUDP: NWEndpoint.Port) {
        // Transmited message:
        let messageToUDP = "Test message"

        self.connection = NWConnection(host: hostUDP, port: portUDP, using: .udp)
        
        self.connection?.stateUpdateHandler = { (newState) in
            print("This is stateUpdateHandler:")
            switch (newState) {
                case .ready:
                    print("State: Ready\n")
                    self.sendUDP(messageToUDP)
                    self.receiveUDP()
                case .setup:
                    print("State: Setup\n")
                case .cancelled:
                    print("State: Cancelled\n")
                case .preparing:
                    print("State: Preparing\n")
                default:
                    print("ERROR! State not defined!\n")
            }
        }

        self.connection?.start(queue: .global())
    }

    /*func sendUDP(_ content: Data) {
        self.connection?.send(content: content, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
            if (NWError == nil) {
                print("Data was sent to UDP")
            } else {
                print("ERROR! Error when data (Type: Data) sending. NWError: \n \(NWError!)")
            }
        })))
    }*/

    func sendUDP(_ content: String) {
        let contentToSendUDP = content.data(using: String.Encoding.utf8)
        self.connection?.send(content: contentToSendUDP, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
            if (NWError == nil) {
                print("Data was sent to UDP")
            } else {
                print("ERROR! Error when data (Type: Data) sending. NWError: \n \(NWError!)")
            }
        })))
    }

    func receiveUDP() {
        self.connection?.receiveMessage { (data, context, isComplete, error) in
            if (isComplete) {
                print("Receive is complete")
                if (data != nil) {
                    let backToString = String(decoding: data!, as: UTF8.self)
                    print("Received message: \(backToString)")
                } else {
                    print("Data == nil")
                }
            }
        }
    }
}
