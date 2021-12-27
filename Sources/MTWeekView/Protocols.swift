//
//  Protocols.swift
//  WeekView
//
//  Created by Maksim Tochilkin on 22.03.2020.
//  Copyright © 2020 Maksim Tochilkin. All rights reserved.
//

import Foundation

public protocol Event: Codable {
    var day: Day { get }
    var start: Time { get }
    var end: Time { get }
    var id: String { get }
}

public extension Event {
    static func == (lhs: Event, rhs: Event) -> Bool {
        return lhs.id == rhs.id
    }
}


//extension Event: Equatable {
//    static func == (lhs: Event, rhs: Event) -> Bool {
//        return lhs.day == rhs.day && lhs.start == rhs.start && lhs.end == rhs.end
//    }
//}

public protocol MTConfigurableCell {
    static var reuseId: String { get }
    func configure(with event: Event)
}

extension MTConfigurableCell {
    public static var reuseId: String {
        return String(describing: self)
    }
}

public extension MTWeekViewDataSource {
    func weekView(_ weekView: MTWeekView, eventsForDay day: Day) -> [Event] { [] }
}

protocol ReusableView {
    static var reuseId: String { get }
    func configure(with indexPath: IndexPath)
}

extension ReusableView {
    static var reuseId: String {
        return String(describing: self)
    }
}
