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
    private var discoveredPeripheral: CBPeripheral?
    private var targetCharacteristic: CBCharacteristic?
    
    private var baseUrl = "http://192.168.137.165:3000/"
    var isNear = false
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {

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

    
    func hexStringToData(_ hexString: String) -> Data? {
        var data = Data()
        var hex = hexString

        // 공백 및 불필요한 문자 제거
        hex = hex.replacingOccurrences(of: " ", with: "")
        hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Hex 문자열이 짝수가 아니면 변환 불가
        guard hex.count % 2 == 0 else { return nil }
        
        // 2글자씩 분리하여 바이트로 변환
        for i in stride(from: 0, to: hex.count, by: 2) {
            let start = hex.index(hex.startIndex, offsetBy: i)
            let end = hex.index(start, offsetBy: 2)
            let byteString = hex[start..<end]
            
            if let byte = UInt8(byteString, radix: 16) {
                data.append(byte)
            } else {
                return nil // 잘못된 문자열인 경우 nil 반환
            }
        }
        
        return data
    }
}

extension VehicleControlViewModel: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // BLE 장치 스캔 시작
            centralManager.scanForPeripherals(withServices: [], options: nil)
            } else {
            print("Bluetooth is not available")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered \(peripheral.identifier.uuidString)")
        if (peripheral.identifier.uuidString == "BB2C086B-14B7-1B50-1C5F-A131F3EBCD71") {
            discoveredPeripheral = peripheral
            discoveredPeripheral?.delegate = self
            centralManager.stopScan()
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Unknown Device")")
        peripheral.discoverServices([CBUUID(string: "ABCDEF00-B5A3-F393-E0A9-E50E24DCCA9E")])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            print("Discovered service: \(service.uuid)")
            peripheral.discoverCharacteristics([CBUUID(string: "ABCDEF01-B5A3-F393-E0A9-E50E24DCCA9E")], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            print("Discovered characteristic: \(characteristic.uuid)")
            if characteristic.uuid == CBUUID(string: "ABCDEF01-B5A3-F393-E0A9-E50E24DCCA9E") {
                targetCharacteristic = characteristic
                peripheral.readRSSI()
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard let characteristic = targetCharacteristic else { return }
        print("Current RSSI: \(RSSI)")
        
        guard peripheral.state == .connected  else {
            print("Peripheral is disconnected. Reconnecting...")
            centralManager.connect(peripheral, options: nil)
            return
        }
        
        // RSSI가 임계값 이하인지 확인
        if RSSI.intValue >= -40 && !isNear { // rssi -40dBm 이하일 경우
            guard let valueToWrite = hexStringToData("1101FF") else {
                return
            }
            peripheral.writeValue(valueToWrite, for: characteristic, type: .withResponse)
            isNear = true
        }
        else if RSSI.intValue <= -60 && isNear {
            guard let valueToWrite = hexStringToData("1003FF") else {
                return
            }
            peripheral.writeValue(valueToWrite, for: characteristic, type: .withResponse)
            isNear = false
        }
        
        // 일정 시간 간격으로 RSSI 다시 읽기
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            peripheral.readRSSI()
        }
    }
}
