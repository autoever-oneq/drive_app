//
//  ContentView.swift
//  drive_app
//
//  Created by Demian on 1/21/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "car.fill")
                    Text("홈")
                }
            
            CarSettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("설정")
                }
        }
    }
}

struct HomeView: View {
    @StateObject private var viewModel = VehicleControlViewModel()
    
    var body: some View {
        VStack {
            // 상단 차량 정보 섹션
            VStack(alignment: .center, spacing: 10) {
                Text("나의 대표차량")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Image("IONIQ6") // 차량 이미지를 표시
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                
                Text("IONIQ 6")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("E-Lite (롱레인지) 2WD")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 30) {
                    VStack {
                        Text("총 주행거리")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("24,729 km")
                            .font(.headline)
                    }
                    VStack {
                        Text("주행 가능거리")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("406 km")
                            .font(.headline)
                    }
                    VStack {
                        Text("배터리 상태")
                            .font(.caption)
                            .foregroundColor(.gray)
                        HStack {
                            Text("78%")
                                .font(.headline)
                            Circle()
                                .fill(Color.green)
                                .frame(width: 10, height: 10)
                        }
                    }
                }
                .padding(.top, 10)
            }
            .padding()
            
            Spacer()
            
            // 하단 버튼 섹션
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.sendCommand("open_door")
                    }) {
                        VStack {
                            Image(systemName: "lock.open.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                            Text("문 열기")
                                .font(.footnote)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        viewModel.sendCommand("close_door")
                    }) {
                        VStack {
                            Image(systemName: "lock.fill")
                                .font(.title)
                                .foregroundColor(.red)
                            Text("문 닫기")
                                .font(.footnote)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.sendCommand("power_on")
                    }) {
                        VStack {
                            Image(systemName: "power.circle.fill")
                                .font(.title)
                                .foregroundColor(.green)
                            Text("시동")
                                .font(.footnote)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        viewModel.sendCommand("power_off")
                    }) {
                        VStack {
                            Image(systemName: "power.circle")
                                .font(.title)
                                .foregroundColor(.orange)
                            Text("시동 해제")
                                .font(.footnote)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}

struct CarSettingsView: View {
    // 자동차 설정 값을 저장할 State 변수
    @State private var optimalTemperature: Double = 22.0
    @State private var autoDoorOpen: Bool = false
    @State private var autoDoorClose: Bool = false
    @State private var seatAngle: Int = 90
    @State private var seatTemperature: Double = 25.0
    @State private var seatPosition: Double = 0.5
    
    @StateObject private var viewModel = SettingViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("기본 설정")) {
                    HStack {
                        Text("적정 온도")
                        Spacer()
                        Text("\(viewModel.setting.optimalTemperature, specifier: "%.1f")°C")
                    }
                    Slider(value: $viewModel.setting.optimalTemperature, in: 16...30, step: 0.1)
                    
                    Toggle("자동 문 열림", isOn: $autoDoorOpen)
                    Toggle("자동 문 닫힘", isOn: $autoDoorClose)
                }
                
                Section(header: Text("시트 설정")) {
                    Stepper("시트 각도: \(viewModel.setting.seatAngle)°", value: $viewModel.setting.seatAngle, in: 60...120, step: 5)
                    
                    HStack {
                        Text("시트 온도")
                        Spacer()
                        Text("\(viewModel.setting.seatTemperature, specifier: "%.1f")°C")
                    }
                    Slider(value: $viewModel.setting.seatTemperature, in: 15...40, step: 0.1)
                    
                    HStack {
                        Text("시트 위치")
                        Spacer()
                        Text("\(Int(viewModel.setting.seatPosition))%")
                    }
                    Slider(value: $viewModel.setting.seatPosition, in: 0...100, step: 1)
                }
            }
            .navigationTitle("개인 설정")
        }
        .onAppear {
            viewModel.fetchSetting()
            print("HOMM")
        }
        .onDisappear {
            viewModel.updateSetting()
            print("GOGO")
        }
    }
}

#Preview {
    ContentView()
}
