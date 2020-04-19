//
//  File.swift
//  
//
//  Created by MacBook on 4/17/20.
//

import Foundation

public struct Time: Codable {
    public var hour: Int
    public var minute: Int

   public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

   public init(from date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        self.hour = components.hour ?? 0
        self.minute = components.minute ?? 0
    }

}


extension Time: Comparable {
    public static func < (lhs: Time, rhs: Time) -> Bool {
        lhs.hour < rhs.hour && lhs.minute < rhs.minute
    }
}

extension Time: Equatable {
    public static func == (lhs: Time, rhs: Time) -> Bool {
        return lhs.hour == rhs.hour && lhs.minute == lhs.minute
    }
}

extension Time {

   public static func -(lhs: Time, rhs: Time) -> Time {
        var hours = lhs.hour - rhs.hour
        var minutes = lhs.minute - rhs.minute

        if minutes < 0 {
            hours -= 1
            minutes = 60 + minutes
        }

        if hours < 0 {
            return Time(hour: 0, minute: 0)
        }

        return Time(hour: hours, minute: minutes)
    }

    public static func +(lhs: Time, rhs: Time) -> Time {
        var hours = lhs.hour + rhs.hour
        var minutes = lhs.minute + rhs.minute

        if minutes >= 60 {
            hours += 1
            minutes = minutes - 60
        }

        if hours > 24 {
            return Time(hour: hours - 24, minute: minutes)
        }

        return Time(hour: hours, minute: minutes)
    }

    public static func /(lhs: Time, rhs: Time) -> Time {
        let first: Float = Float(lhs.hour) + Float(lhs.minute) / 60.0
        let second: Float = Float(rhs.hour) + Float(rhs.minute) / 60.0

        let result = first / second

        let whole = modf(result).0
        let decimal = modf(result).1

        return Time(hour: Int(whole), minute: Int(decimal * 60))
    }

    public static func *(lhs: Int, rhs: Time) -> Time {
        var result = Time(hour: 0, minute: 0)
        for _ in 0 ..< lhs {
            result = result + rhs
        }
        return result
    }

   public static func <=(lhs: Time, rhs: Time) -> Bool {
        return lhs.hour <= rhs.hour && lhs.minute <= rhs.minute
    }
}

extension Time {
    public func float() -> Float {
        return Float(self.hour) + Float(self.minute) / 60.0
    }

    public static func fromFloat(_ value: Float) -> Time {
        let whole = modf(value).0
        let decimal = modf(value).1

        return Time(hour: Int(whole), minute: Int(decimal * 60))
    }
}
