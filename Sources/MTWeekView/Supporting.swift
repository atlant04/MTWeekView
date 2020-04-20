//
//  MTWeekViewDataSource.swift
//  WeekView
//
//  Created by Maksim Tochilkin on 21.03.2020.
//  Copyright © 2020 Maksim Tochilkin. All rights reserved.
//

import Foundation
import UIKit

public enum Day: Int, CaseIterable, Codable {
    case Monday, Tuesday, Wednesday, Thursday, Friday
    
    var index: Int {
        return self.rawValue
    }
    
    var name: String {
        return String(String(describing: self).prefix(3))
    }
}

public struct LayoutConfiguration {
    public init() { }
    
    public var start: Time = Time(hour: 8, minute: 0)
    public var end: Time = Time(hour: 20, minute: 0)
    public var hidesVerticalLines: Bool = false

    var range: (start: Time, end: Time) {
        return (start: start, end: end)
    }
    
    var interval: Time = Time(hour: 1, minute: 0)
    var totalDays: Int = 5
    public var gridLineThickness: CGFloat =  1
}

