// THIS IS VERSION TRYING TO INCLUDE SWITCH
//  ble.swift
//  ble_example
//
//  Created by Nathan Dullea on 10/16/18.
//  Copyright © 2018 PATCH. All rights reserved.
//
//  Reference for this is https://www.appcoda.com/core-bluetooth
//

import Foundation
import UIKit
import CoreBluetooth

// Service IDs
//perhaps use the automation IO service ID: 0x1815
let BLE_example_service_CBUUID = CBUUID(string: "6c251c91-dde0-4263-a0a7-d26b4a662b41")
//let ble_service = CBService(String: "6c251c91-dde0-4263-a0a7-d26b4a662b41")

// Characteristic IDs
let Light_Characteristic_CBUUID = CBUUID(string: "ffc7b3e7-3ff6-4672-a060-a47b884f38b1")
let Switch_Characteristic_CBUUID = CBUUID(string: "3b712824-9972-4283-946b-7257f760b29c")

// lightOn, 0 == Red, 1 == Yellow, 2 == Green
var lightOn = "0"
//var switchCount = 0

class BLE_example: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager?
    var peripheralDevice: CBPeripheral?
    
    //IBOutlets for what will appear on the screen, squares with 3 colors??
    //IBoutlet button 1
    //IBoutlet button 2
    //IBoutlet button 3
    //IBoutlet ble status label
    //bluetooth off label
    @IBOutlet weak var bleStatusLabel: UILabel!
    @IBOutlet weak var switchPressedLabel: UILabel!
    
    var switchCount: Int = 0 {
        didSet {
            switchPressedLabel.text = "\(switchCount)"
        }
    }
    
    @IBAction func red(_ sender: Any) {
        lightOn = "2"
        print("red")
        sendColor(peripheral: peripheralDevice!)
    }
    @IBAction func yellow(_ sender: Any) {
        lightOn = "0"
        print("yellow")
        sendColor(peripheral: peripheralDevice!)
    }
    @IBAction func green(_ sender: Any) {
        lightOn = "1"
        print("green")
        sendColor(peripheral: peripheralDevice!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //handle what appears on screen
        bleStatusLabel.text = "letss goo"
        switchPressedLabel.text = "0"
        
        //Create a queue for the central
        let centralQueue: DispatchQueue = DispatchQueue(label: "doesLabelMatter?", attributes: .concurrent)
        //Create a central to scan for and manage peripherals
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        //dispose of resources that can be recreated?
    }
    
    //CBCENTRAL MANAGER METHODS
    
    //This one will scan depending upon bluetooth state
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("Bluetooth Status is unknown.")
        case .resetting:
            print("Bluetooth Status is resetting.")
        case .unsupported:
            print("Bluetooth status is UNSUPPORTED")
            //bluetoothOffLabel.alpha = 1.0
        case .unauthorized:
            print("Bluetooth status is UNAUTHORIZED")
            //bluetoothOffLabel.alpha = 1.0
        case .poweredOff:
            print("Bluetooth status is POWERED OFF")
            //bluetoothOffLabel.alpha = 1.0
        case .poweredOn:
            print("Bluetooth status is POWERED ON")
            
            DispatchQueue.main.async { () -> Void in
                //self.bluetoothOffLabel.alpha = 0.0
                //self.connectingActivityIndicator.startAnimating()
                self.bleStatusLabel.text = "central manager updates"
            }
            
            // STEP 3.2: scan for peripherals that we're interested in
            centralManager?.scanForPeripherals(withServices: [BLE_example_service_CBUUID])
            //centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
            print("scanning...")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered Peripheral")
        //ISSUES ARE HAPPENING HERE
        print(peripheral.name!)
        
        decodePeripheralState(peripheralState: peripheral.state)
        
        peripheralDevice = peripheral
        
        peripheralDevice?.delegate = self
        
        centralManager?.stopScan()
        
        centralManager?.connect(peripheralDevice!)
        print("connecting?")
    }
 
 
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async { () -> Void in
            //Change stuff here!!
            self.bleStatusLabel.text = "peripheral connected"
        }
        //Not really sure why I am discovering service when I have been searching
        //for peripherals offering that specific service?
        peripheralDevice?.discoverServices([BLE_example_service_CBUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        DispatchQueue.main.async { () -> Void in
            self.bleStatusLabel.text = "peripheral disconnected"
        }
        
        //start scanning again for peripherals to come online
        centralManager?.scanForPeripherals(withServices: [BLE_example_service_CBUUID])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            if service.uuid == BLE_example_service_CBUUID {
                print("Service : \(service)")
                //I THINK MAYBE NIL SHOULD BE THE CHARACTERISTIC UUID
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    //This runs when confirmed we have discovered characteristics of interest
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        for characteristic in service.characteristics! {
            if characteristic.uuid == Light_Characteristic_CBUUID {
                //THIS IS WHERE I WRITE THE VALUE TO THE ESP32!!
                //WRITE VALUE OF LIGHT ON
                //let data = lightOn.dataUsingEncoding(NSUTF8StringEncoding)
                let data = lightOn.data(using: String.Encoding.utf8)
                peripheral.writeValue(data!, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
            }
            
            //ADD ANOTHER CHARACTERISTIC WE CAN SUbSCRIBE TOO
            if characteristic.uuid == Switch_Characteristic_CBUUID {
                //Subscribe to this notification
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic.uuid == Switch_Characteristic_CBUUID {
            switchCount += 1
        }
    }
    
    //ADD FUNCTION FOR UPDATEVALUE FROM CHARACTERISTIC WE ARE SUBSCRIBED TO
    //Did update value for function
    
    func decodePeripheralState(peripheralState: CBPeripheralState) {
        switch peripheralState {
        case .disconnected:
            print("Peripheral state: disconnected")
        case .connected:
            print("Peripheral state: connected")
        case .connecting:
            print("Peripheral state: connecting")
        case .disconnecting:
            print("Peripheral state: disconnecting")
        }
    }
    
    func sendColor(peripheral: CBPeripheral) {
        print("sending color")
        /*let data = lightOn.data(using: String.Encoding.utf8)
        peripheral.writeValue(data!, for: Light_Characteristic_CBUUID, type: CBCharacteristicWriteType.withoutResponse)*/
        for service in peripheral.services! {
            for characteristic in service.characteristics! {
                if characteristic.uuid == Light_Characteristic_CBUUID {
                    //THIS IS WHERE I WRITE THE VALUE TO THE ESP32!!
                    //WRITE VALUE OF LIGHT ON
                    //let data = lightOn.dataUsingEncoding(NSUTF8StringEncoding)
                    let data = lightOn.data(using: String.Encoding.utf8)
                    peripheral.writeValue(data!, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
                }
            }
        }
    }
}
