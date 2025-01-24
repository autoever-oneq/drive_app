//
//  SettingViewModel.swift
//  drive_app
//
//  Created by Demian on 1/24/25.
//

import Foundation

class SettingViewModel: ObservableObject {
    @Published var setting: VehicleSetting
    
    private var baseUrl = "http://192.168.137.165:3000/"

    init() {
        self.setting = VehicleSetting (optimalTemperature: 20, autoDoorOpen: false, autoDoorClose: false, seatAngle: 110, seatTemperature: 23, seatPosition: 40)
    }
    
    func updateSetting() {
        let api = "setting/"
        let uid = "ABCDEF00"
        guard let url = URL(string: baseUrl + api + uid) else {
            print("INVALID URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(setting)
            request.httpBody = jsonData
        } catch {
            print("Error encoding JSON: \(error)")
            return
        }
        
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
    
    func fetchSetting() {
        let api = "setting/"
        let uid = "ABCDEF00"
        guard let url = URL(string: baseUrl + api + uid) else {
            print("INVALID URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request failed: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    let error = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch settings."])
                    return
                }
            }
            
            if let data = data {
                do {
                    self.setting = try JSONDecoder().decode(VehicleSetting.self, from: data)
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
        }.resume()
    }
}
