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
            let receivedString: String? = String(data: response, encoding: String.Encoding.utf8) as String?
            
            let packetIdentifier = receivedString!.prefix(1)
            var finalValue = receivedString ?? " "
            finalValue.remove(at: receivedString?.startIndex ?? "Unknown".startIndex)
            
            switch packetIdentifier {
            case "N":
                self?.mediaName.text = finalValue
            case "T":
                let seconds = Int(finalValue) ?? 0
                self?.playerTime.text = "\(seconds/60):\(seconds%60)"
            case "V":
                self?.volumeSlider.value = Float(finalValue) ?? 0.0
            default:
                break
            }
            
            //Debuggin purposes
            print("Received: \(receivedString ?? "Nothing?")")
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

