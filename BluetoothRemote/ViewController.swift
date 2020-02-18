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
    @IBAction func testUDP(_ sender: UIButton) {
        print("pressed")
        do {
            try broadcastConnection.sendBroadcast("P")
        } catch {
            print("error sending")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        do { broadcastConnection = try UDPBroadcastConnection(
        port: 5005,
        handler: { [weak self] (ipAddress: String, port: Int, response: Data) -> Void in
            print("Received")
        },
        errorHandler: { (error) in
          print(error)
        })} catch {
            print("error setting up broadcast connection")
        }
    }
}

