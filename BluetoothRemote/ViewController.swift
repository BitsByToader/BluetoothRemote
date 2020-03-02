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
    var volumeInSeconds: Int = -1
    var mediaTimer: Timer!
    var seekTimer: Timer!
    var isPlaying: Bool! = false
    var secondsSeeked: Int! = 0
    
    //MARK: Properties
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var playerTime: UILabel!
    @IBOutlet weak var mediaName: UILabel!
    
    @IBOutlet weak var playPauseButton: UIButton!
    
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    @IBOutlet weak var closeServerButton: UIBarButtonItem!
    
    @IBAction func playPauseMedia(_ sender: UIButton) {
        sendUDPCommand(data: "P")
    }
    
    @IBAction func nextItem(_ sender: UIButton) {
        if ( secondsSeeked < 1 ) {
            sendUDPCommand(data: "N")
        }
        secondsSeeked = 0
        seekTimer.invalidate()
    }
    
    @IBAction func previousItem(_ sender: UIButton) {
        if ( secondsSeeked < 1 ) {
            sendUDPCommand(data: "R")
        }
        secondsSeeked = 0
        seekTimer.invalidate()
    }
    
    @IBAction func setVolume(_ sender: UISlider) {
        sendUDPCommand( data: "V\( String(Int(volumeSlider.value)) )" )
    }
    
    @IBAction func closeServer(_ sender: UIBarButtonItem) {
        sendUDPCommand(data: "E")
    }
    
    @IBAction func refreshButton(_ sender: UIBarButtonItem) {
        sendUDPCommand(data: "I")
    }
    
    @IBAction func seekForward(_ sender: UIButton) {
        startSeekTimer(type: "+")
    }
    
    @IBAction func seekBackward(_ sender: UIButton) {
        startSeekTimer(type: "-")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //Notify the view when it entered the foreground
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadData),
                                               name: UIApplication.didBecomeActiveNotification,
                                                object: nil)
        
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
                self?.volumeInSeconds = seconds
                if ( self!.isPlaying ) {
                    self?.mediaTimer.fire()
                } else {
                    self?.startTimer()
                }
                self?.isPlaying = true
                self?.playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            case "V":
                self?.volumeSlider.value = Float(finalValue) ?? 0.0
            case "P":
                self?.isPlaying = false
                self?.mediaTimer.invalidate()
                self?.playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
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
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        tabBarController?.title = "Your Title"
//        tabBarController?.navigationItem.rightBarButtonItem = closeServerButton
//        tabBarController?.navigationItem.leftBarButtonItem = refreshButton
//    }
    
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
    
    func updateTimerLabel(timer: Timer) {
        self.volumeInSeconds += 1
        self.playerTime.text = "\(self.volumeInSeconds/60):\(self.volumeInSeconds%60)"
    }
    
    @objc func reloadData() {
        sendUDPCommand(data: "I")
    }
    
    func startTimer() {
        mediaTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: updateTimerLabel(timer:))
        mediaTimer.tolerance = 0
    }
    
    func startSeekTimer(type: String!) {
        if ( type == "+" ) {
            seekTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true, block: seekForward(timer:))
        } else if ( type == "-" ) {
            seekTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true, block: seekBackward(timer:))
        }
        seekTimer.tolerance = 0
    }
    
    func seekForward(timer: Timer) {
        secondsSeeked += 1
        sendUDPCommand(data: "S+")
    }
    
    func seekBackward(timer: Timer) {
        secondsSeeked += 1
        sendUDPCommand(data: "S-")
    }
    
    
}

