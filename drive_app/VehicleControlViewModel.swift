//
//  app_viewmodel.swift
//  drive_app
//
//  Created by Demian on 1/21/25.
//

import Foundation
import CoreBluetooth
import Network
import Combine

class VehicleControlViewModel: NSObject, ObservableObject {
    @Published var isDoorLocked: Bool = true
    @Published var rssi: Int = -100
    
    private var centralManager: CBCentralManager!
    
    private var baseUrl = "http://192.168.137.165:3000/"
    
    func startScanning() {
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func sendCommand(_ command: String) {
        let api = "command/"
        
        guard let url = URL(string: baseUrl + api + command ) else {
            print("INVALID URL")
            return
        }
        
        print("GOGO")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request failed: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 200 {
                    print("Settings successfully sent to server")
                } else {
                    print("Failed to send settings. Code: \(httpResponse.statusCode)")
                }
            }
            
            if let data = data {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
            }
        }.resume()
    }

}

extension VehicleControlViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning()
        } else {
            print("BLE 사용 불가능")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.rssi = RSSI.intValue
        if RSSI.intValue > -50 && isDoorLocked {
            print("BLE 감지 강도 충족: 문 잠금 해제")
            isDoorLocked = false
        } else if RSSI.intValue <= -50 && !isDoorLocked {
            print("BLE 감지 강도 낮음: 문 잠금")
            isDoorLocked = true
        }
    }
}
