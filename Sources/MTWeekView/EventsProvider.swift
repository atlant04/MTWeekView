//
//  File.swift
//  
//
//  Created by MacBook on 4/19/20.
//

import Foundation

//TableImplementation
//LinkedListImplementation

class EventsProvider: TableImplementation {

    var allEvents: [Event]

    typealias SortDescriptor = ((Event, Event) -> Bool)
    var sortDescriptor: SortDescriptor = { first, second in
        first.day.index < second.day.index || first.start < second.start
    }

    typealias SelectionCondition = (Event) -> Bool

    init(events: [Event]) {
        self.allEvents = events
        super.init()
        populate()
    }

    func populate(with condition: SelectionCondition = { _ in true }) {
        map = [:]
        for event in allEvents {
            guard condition(event) else { continue }
            insert(event)
        }
    }

    func event(at indexPath: IndexPath) -> Event? {
        guard let day = Day(rawValue: indexPath.section) else { return nil }
        return nodeAt(indexPath.item, day: day)?.event
    }

    func selectEvents(where condition: SelectionCondition) {
        populate(with: condition)
    }


}



class TableImplementation: ProviderImplementation {

    var map: [Day: [EventNode]] = [:]

    func insert(_ event: Event) -> EventNode {
        let node = EventNode(event: event)

        if var array = map[event.day] {
            let index = array.firstIndex { $0.event.start < event.start } ?? array.count
            array.insert(node, at: index)
            map[event.day] = array
        } else {
            map[event.day] = [node]
        }

        return node
    }

    func delete(_ event: Event) -> EventNode? {
        if let index = map[event.day]?.firstIndex(where: { $0.event.id == event.id }) {
            return map[event.day]?.remove(at: index)
        }
        return nil
    }

    func nodeAt(_ index: Int, day: Day) -> EventNode? {
        return map[day]?[index]
    }

    func find(event: Event) -> EventNode? {
        return map[event.day]?.first(where: { $0.event.id == event.id })
    }

    func toArray(day: Day) -> [Event] {
        return map[day]?.map { $0.event } ?? []
    }
}

protocol BaseEventsProvider: class {

    @discardableResult
    func insert(_ event: Event) -> EventNode

    @discardableResult
    func delete(_ event: Event) -> EventNode?

    func nodeAt(_ index: Int, day: Day) -> EventNode?
    func find(event: Event) -> EventNode?
    func toArray(day: Day) -> [Event]

}

protocol ProviderImplementation: BaseEventsProvider {
    func move(_ event: Event, to day: Day, start: Time, end: Time)
    func events(for day: Day) -> [Event]
    func numberOfEvents(for day: Day) -> Int
    func indexPath(for event: Event) -> IndexPath?
    func event(at indexPath: IndexPath) -> Event?
}

extension ProviderImplementation {
    func move(_ event: Event, to day: Day, start: Time, end: Time) {
        delete(event)

        var newEvent = event
        newEvent.day = day
        newEvent.start = start
        newEvent.end = end

        insert(newEvent)
    }

    func events(for day: Day) -> [Event] {
        toArray(day: day)
    }

    func numberOfEvents(for day: Day) -> Int {
        toArray(day: day).count
    }

    func event(at indexPath: IndexPath) -> Event? {
        guard let day = Day(rawValue: indexPath.section) else { return nil }
        return nodeAt(indexPath.item, day: day)?.event
    }

    func indexPath(for event: Event) -> IndexPath? {
        let node = find(event: event)

        if let index = node?.index {
            return IndexPath(item: index, section: event.day.index)
        }

        return nil
    }
}


class EventNode {
    var event: Event
    var index: Int = 0

    init(event: Event) {
        self.event = event
    }
}

class LinkedListImplementation: ProviderImplementation {

    class LinkedNode: EventNode {
        var next: LinkedNode? {
            didSet {
                next?.index = index + 1
            }
        }
    }

    var map: [Day : LinkedNode] = [:]


    func insert(_ event: Event) -> EventNode {
        let newNode = LinkedNode(event: event)

        guard let root = map[event.day] else {
            map[event.day] = newNode
            return newNode
        }

        if let earliest = findEarliest(for: event) {
            let temp = earliest.next
            earliest.next = newNode
            newNode.next = temp
        } else {
            newNode.next = root
            map[event.day] = newNode
        }

        return newNode
    }

    func nodeAt(_ index: Int, day: Day) -> EventNode? {
        guard let root = map[day] else { return nil }
        var curr: LinkedNode? = root

        while let _ = curr, curr?.index != index {
            curr = curr?.next
        }

        return curr
    }

    func findEarliest(for event: Event) -> LinkedNode? {
        var curr = map[event.day]

        while let current = curr, current.event.start < event.start {
            curr = current.next
        }
        return curr
    }

    func delete(_ event: Event) -> EventNode? {
        guard let root = map[event.day] else { return nil }

        if root.event.id == event.id {
            map[event.day] = root.next
            return root
        }

        var curr = root
        while let next = curr.next, next.event.id != event.id {
            curr = next
        }

        let toReturn = curr.next
        curr.next = curr.next?.next
        return toReturn
    }

    func toArray(day: Day) -> [Event] {
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

    func find(event: Event) -> EventNode? {
        guard let root = map[event.day] else { return nil }
        var curr: LinkedNode? = root

        while curr != nil, curr?.event.id != event.id {
            curr = curr?.next
        }

        return curr
    }


}
