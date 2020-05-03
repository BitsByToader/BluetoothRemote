//
//  MouseViewController.swift
//  BluetoothRemote
//
//  Created by Ifrim Tudor on 28/02/2020.
//  Copyright © 2020 tudor. All rights reserved.
//

import UIKit
import Foundation

class MouseViewController: UIViewController {
    //MARK: Variables
    var previousPosition: CGPoint?
    var initialPosition: CGPoint?
    var callBacksReceived: Int = 0
    var isScrolling: Bool = false
    var broadcastConnection: UDPBroadcastConnection!
    
    //MARK: Actions
    
    @IBAction func scrollRecognizer(_ sender: UIPanGestureRecognizer) {
        guard sender.view != nil else {return}
        let touch = sender.view!
        // Get the changes in the X and Y directions relative to
        // the superview's coordinate space.
        let translation = sender.translation(in: touch.superview)
        
        if ( sender.state == .began ) {
            self.initialPosition = touch.center
        } else if ( sender.state == .changed ) {
            sendUDPCommand(data: "S\(translation.x)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        do { broadcastConnection = try UDPBroadcastConnection(
        port: 5005,
        handler: { (ipAddress: String, port: Int, response: Data) -> Void in
            //Cast the received packets to a String for easier manipulation
            let receivedString: String? = String(data: response, encoding: String.Encoding.utf8) as String?
            
            //Debuggin purposes
            print("Received: \(receivedString ?? "Nothing?")")
        },
        errorHandler: { (error) in
          print(error)
        })} catch {
            print("error setting up broadcast connection")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: view)
            previousPosition = position
            initialPosition = position
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: view)
            
            if ( callBacksReceived == 2	 ) {
                var x = Int(position.x)
                var y = Int(position.y)
                
                let prevX = Int(previousPosition?.x ?? 0)
                let prevY = Int(previousPosition?.y ?? 0)
                
                let radius = 5
                
                if ( x >= prevX + radius || x <= prevX - radius ||
                     y >= prevY + radius || y <= prevY - radius)  {
                    
                    x = x - prevX
                    //x = ( x *  1920 ) / Int(self.view.frame.width)
                    
                    y = y - prevY
                    //y = ( y * 1080 ) / Int(self.view.frame.height)
                    
                    if ( !isScrolling) {
                        sendUDPCommand(data: "M\(x),\(y)")
                    } else {
                        sendUDPCommand(data: "S\(x)")
                    }
                    
                    previousPosition = position
                    callBacksReceived = 0
                }
            } else {
                callBacksReceived += 1
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: view)
            
            let x = Int(position.x)
            let y = Int(position.y)
            
            let prevX = Int(initialPosition?.x ?? 0)
            let prevY = Int(initialPosition?.y ?? 0)
            
            if ( x == prevX && y == prevY ) {
                sendUDPCommand(data: "C")
            }
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
