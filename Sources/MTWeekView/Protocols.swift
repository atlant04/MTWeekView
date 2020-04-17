//
//  Protocols.swift
//  WeekView
//
//  Created by Maksim Tochilkin on 22.03.2020.
//  Copyright © 2020 Maksim Tochilkin. All rights reserved.
//

import Foundation

public protocol Event {
    var day: Day { get set }
    var start: Time { get }
    var end: Time { get }
}

public protocol MTConfigurableCell {
    static var reuseId: String { get }
    func configure(with event: Event)
}

extension MTConfigurableCell {
    static var reuseId: String {
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
