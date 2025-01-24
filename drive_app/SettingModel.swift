//
//  SettingModel.swift
//  drive_app
//
//  Created by Demian on 1/24/25.
//

import Foundation

struct VehicleSetting: Codable {
    var optimalTemperature: Double
    var autoDoorOpen: Bool
    var autoDoorClose: Bool
    var seatAngle: Int
    var seatTemperature: Double
    var seatPosition: Double
}
