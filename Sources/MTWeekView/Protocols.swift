//
//  Protocols.swift
//  WeekView
//
//  Created by Maksim Tochilkin on 22.03.2020.
//  Copyright © 2020 Maksim Tochilkin. All rights reserved.
//

import Foundation

public protocol MTSelfConfiguringEventCell {
    static var reuseId: String { get }
    func configure(with data: Event)
}

extension MTSelfConfiguringEventCell {
    static var reuseId: String {
        return String(describing: self)
    }
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
