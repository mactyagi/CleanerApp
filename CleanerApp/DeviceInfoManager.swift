//
//  DeviceInfoManager.swift
//  CleanerApp
//
//  Created by Manu on 23/12/23.
//

import Foundation


protocol DeviceInfoDelegate: AnyObject{
    func availableRAMDidUpdate(_ availableRAM: UInt64)
}


class DeviceInfoManager{
    weak var delegate: DeviceInfoDelegate?
    
    private var timer: Timer = Timer()
    private(set) var availableRAM: UInt64 = 0{
        didSet{
            delegate?.availableRAMDidUpdate(availableRAM)
        }
    }
    
    
    func startRAMUpdateTimer() {
            // You can adjust the timer interval based on your needs
            
        timer.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.getAvailableRAM()
        }
        }
    
    func stopRamUpdateTimer(){
        timer.invalidate()
    }
    
    
    private func getAvailableRAM(){
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            availableRAM = info.resident_size
        } else {
            return availableRAM = 0
        }
    }
}
