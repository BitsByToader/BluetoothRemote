//
//  ViewController.swift
//  BluetoothRemote
//
//  Created by Ifrim Tudor on 16/02/2020.
//  Copyright © 2020 tudor. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    //MARK: Properties
    @IBAction func testUDP(_ sender: UIButton) {
        print("pressed")
//        var addr = in_addr()
//        inet_pton(AF_INET, "192.168.0.1", &buf)
        let INADDR_ANY = in_addr(s_addr: 0)
        udpSend(textToSend: "H", address: INADDR_ANY, port: 5005)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    func udpSend(textToSend: String, address: in_addr, port: CUnsignedShort) {


    func htons(value: CUnsignedShort) -> CUnsignedShort {
        return (value << 8) + (value >> 8);
    }

    let fd = socket(AF_INET, SOCK_DGRAM, 0) // DGRAM makes it UDP

    let addr = sockaddr_in(
        sin_len:    __uint8_t(MemoryLayout<sockaddr_in>.size),
        sin_family: sa_family_t(AF_INET),
        sin_port:   htons(value: port),
        sin_addr:   address,
        sin_zero:   ( 0, 0, 0, 0, 0, 0, 0, 0 )
    )

        _ = textToSend.withCString { cstr -> Int in

        var localCopy = addr

        let sent = withUnsafePointer(to: &localCopy) { pointer -> Int in
            let memory = UnsafeRawPointer(pointer).bindMemory(to: sockaddr.self, capacity: 1)
            let sent = sendto(fd, cstr, strlen(cstr), 0, memory, socklen_t(addr.sin_len))
            return sent
        }

        return sent
    }

    close(fd)

    }
}

