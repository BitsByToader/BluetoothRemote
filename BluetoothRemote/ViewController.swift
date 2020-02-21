//
//  ViewController.swift
//  BluetoothRemote
//
//  Created by Ifrim Tudor on 16/02/2020.
//  Copyright © 2020 tudor. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController {
    
    var broadcastConnection: UDPBroadcastConnection!
    
    //MARK: Properties
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var playerTime: UILabel!
    @IBOutlet weak var mediaName: UILabel!
    
    @IBAction func playPauseMedia(_ sender: UIButton) {
        sendUDPCommand(data: "P")
    }
    
    @IBAction func nextItem(_ sender: UIButton) {
        sendUDPCommand(data: "N")
    }
    
    @IBAction func previousItem(_ sender: UIButton) {
        sendUDPCommand(data: "R")
    }
    
    @IBAction func setVolume(_ sender: UISlider) {
        sendUDPCommand( data: "V\( String(Int(volumeSlider.value)) )" )
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        do { broadcastConnection = try UDPBroadcastConnection(
        port: 5005,
        handler: { [weak self] (ipAddress: String, port: Int, response: Data) -> Void in
            //Cast the received packets to a String for easier manipulation
            let receivedAsString: String? = String(data: response, encoding: String.Encoding.utf8) as String?
            
            //Debuggin purposes
            print("Received: \(receivedAsString ?? "Nothing?")")
        },
        errorHandler: { (error) in
          print(error)
        })} catch {
            print("error setting up broadcast connection")
        }
    }
    
    //MARK: Methods
    func sendUDPCommand(data: String!) {
        //Debugging purposes, comment this out
        print("Sent: \(data ?? "Nothing?")")
        
        do {
            try broadcastConnection.sendBroadcast(data)
        } catch {
            print("error sending")
        }
    }
}

