//
//  File.swift
//  
//
//  Created by MacBook on 4/19/20.
//

import Foundation


class EventsProvider {

    var allEvents: [Event]
    fileprivate var map: [Day: EventNode] = [:]

    typealias SortDescriptor = ((Event, Event) -> Bool)
    var sortDescriptor: SortDescriptor = { first, second in
        first.day.index < second.day.index || first.start < second.start
    }

    typealias SelectionCondition = (Event) -> Bool

    init(events: [Event]) {
        self.allEvents = events
        populate()
    }

    func populate(with condition: SelectionCondition = { _ in true }) {
        map = [:]
        for event in allEvents {
            guard condition(event) else { continue }
            insertNode(event)
        }
    }

    fileprivate func insertNode(_ event: Event) {
        guard let root = map[event.day] else {
            map[event.day] = EventNode(event: event)
            return
        }

        let newNode = EventNode(event: event)
        if event.start < root.event.start {
            newNode.next = root
            map[event.day] = newNode
        } else {
            let earliest = findEarliest(root: root)
            let temp = earliest.next
            earliest.next = newNode
            newNode.next = temp
        }
    }


    fileprivate func nodeAt(_ index: Int, day: Day) -> EventNode? {
        guard let root = map[day] else { return nil }
        var curr: EventNode? = root

        while let _ = curr, curr?.index != index {
            curr = curr?.next
        }

        return curr
    }

    fileprivate func findEarliest(root: EventNode) -> EventNode {
        var curr = root
        while let next = curr.next, curr.event.start < next.event.start {
            curr = next
        }
        return curr
    }

    func event(at indexPath: IndexPath) -> Event? {
        guard let day = Day(rawValue: indexPath.section) else { return nil }
        return nodeAt(indexPath.item, day: day)?.event
    }

    func indexPath(for event: Event) -> IndexPath? {
        guard let root = map[event.day] else { return nil }
        var curr: EventNode? = root

        while curr?.event.id != event.id {
            curr = curr?.next
        }

        if let index = curr?.index {
            return IndexPath(item: index, section: event.day.index)
        }

        return nil
    }

    func deleteNode(with event: Event) {
        guard let root = map[event.day] else { return }

        if root.event.id == event.id {
            map[event.day] = root.next
            return
        }

        var curr = root
        while let next = curr.next, next.event.id != event.id {
            curr = next
        }
        curr.next = curr.next?.next
    }


    func move(event: Event, to day: Day, start: Time, end: Time) {

        deleteNode(with: event)

        var newEvent = event

        newEvent.day = day
        newEvent.start = start
        newEvent.end = end

        insertNode(newEvent)

    }

    func events(for day: Day) -> [Event] {
        return toArray(day: day)
    }

    func numberOfEvents(for day: Day) -> Int {
        return toArray(day: day).count
    }

    func selectEvents(where condition: SelectionCondition) {
        populate(with: condition)
    }

    fileprivate func toArray(day: Day) -> [Event] {
        guard let root = map[day] else { return [] }
        var result = [Event]()
        var curr = root

        result.append(curr.event)

        while let next = curr.next {
            result.append(next.event)
            curr = next
        }

        return result
    }

}


fileprivate class EventNode {

    var next: EventNode? {
        didSet {
            next?.index = index + 1
        }
    }

    let event: Event
    var index: Int = 0

    init(event: Event, next: EventNode? = nil) {
        self.event = event
        self.next = next
    }
}

extension EventNode: Comparable {
    static func < (lhs: EventNode, rhs: EventNode) -> Bool {
        return lhs.event.start < rhs.event.start
    }

    static func == (lhs: EventNode, rhs: EventNode) -> Bool {
        return lhs.event.start == rhs.event.start
    }

}
