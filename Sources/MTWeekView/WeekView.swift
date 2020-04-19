//
//  WeekView.swift
//  WeekView
//
//  Created by Maksim Tochilkin on 21.03.2020.
//  Copyright © 2020 Maksim Tochilkin. All rights reserved.
//

import UIKit

public protocol MTWeekViewDataSource {
    func weekView(_ weekView: MTWeekView, eventsForDay day: Day) -> [Event]
    func allEvents(for weekView: MTWeekView) -> [Event]
}

open class MTWeekView: UIView, MTWeekViewCollectionLayoutDelegate {

    //MARK: Public
    public var configuration: LayoutConfiguration!
    public var dataSource: MTWeekViewDataSource? {
        didSet { reload() }
    }
    public var collectionView: UICollectionView!

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.configuration = LayoutConfiguration()
        commonInit()
    }

    public init(frame: CGRect, configuration: LayoutConfiguration = LayoutConfiguration()) {
        super.init(frame: frame)
        self.configuration = configuration
        commonInit()

    }

    public func reload() {
        getEvents()
        invalidate()
    }

    public func invalidate() {
        layout.clearCache()
        collectionView.reloadData()
    }

    override open var intrinsicContentSize: CGSize {
        return layout.collectionViewContentSize
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: Private

    internal var layout: MTWeekViewCollectionLayout!
    internal var allEvents: [Day: [Event]] = [:]
    internal var selectedEvents: [Day: [Event]]?

    var MainCellType: MTBaseCell.Type?


    private func commonInit() {
        layout = MTWeekViewCollectionLayout(configuration: configuration)
        layout.delegate = self
        collectionView = UICollectionView(frame: self.bounds, collectionViewLayout: layout!)
        registerClasses()
        setupCollectionView()
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.fill(view: self)
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
    }
    
    
    private func getEvents() {
        for day in Day.allCases {
            guard let events = dataSource?.weekView(self, eventsForDay: day) else { continue }
            allEvents[day] = events
        }

        guard let events = dataSource?.allEvents(for: self) else { return }
        allEvents = Dictionary(grouping: events, by: { $0.day } )
    }
    
    private func setupCollectionView() {
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        addSubview(collectionView)
    }
    
    private func registerClasses() {
        collectionView.register(MTTimelineHeader.self, forSupplementaryViewOfKind: MTTimelineHeader.reuseId, withReuseIdentifier: MTTimelineHeader.reuseId)
        collectionView.register(MTDayHeader.self, forSupplementaryViewOfKind: MTDayHeader.reuseId, withReuseIdentifier: MTDayHeader.reuseId)
    }

    internal func events(for day: Day) -> [Event]? {
        let events = selectedEvents ?? allEvents
        if let events = events[day] {
            return Array(events)
        }
        return nil
    }

}

//MARK: Public API

extension MTWeekView {
    public func showEvents(where condition: (Event) -> Bool) {
        selectedEvents = allEvents.mapValues { events in
            return events.filter(condition)
        }
        invalidate()
    }

    public func showAll() {
        selectedEvents = nil
        invalidate()
    }

    public func register<T: MTBaseCell>(_ type: T.Type) {
        self.MainCellType = type
        self.collectionView.register(type, forCellWithReuseIdentifier: type.reuseId)
    }
}

//MARK: UICollectionView Delegate + DataSource
extension MTWeekView: UICollectionViewDelegate, UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        configuration.totalDays
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let day: Day = Day(rawValue: section) ?? .Monday
        let events = selectedEvents ?? allEvents
        return events[day]?.count ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let Type = self.MainCellType else { fatalError("Must Register a Week View Cell first") }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Type.reuseId, for: indexPath)
        let eventsToShow = selectedEvents ?? allEvents

        if let cell = cell as? MTBaseCell {
            if let event = event(at: indexPath, in: eventsToShow) {
                cell.configure(with: event)
            }
        }

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath)
        (view as? ReusableView)?.configure(with: indexPath)
        return view
    }

    func event(at indexPath: IndexPath, in collection: [Day: [Event]]) -> Event? {
        if let day = Day(rawValue: indexPath.section) {
            return collection[day]?[indexPath.item]
        }
        return nil
    }
}

extension MTWeekView: UICollectionViewDragDelegate {
    public func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let currentEvents = selectedEvents ?? allEvents
        let location = session.location(in: collectionView)
        guard
            let indexPath = collectionView.indexPathForItem(at: location),
            let cell = collectionView.cellForItem(at: indexPath) as? MTBaseCell
        else { return [] }

        layout.coordinator?.initialLocation = collectionView.convert(location, from: layout.grid)
        
        if let event = event(at: indexPath, in: currentEvents) {
            let provider = NSItemProvider(object: AnyEvent(event: event))
            let dragItem = UIDragItem(itemProvider: provider)
            dragItem.localObject = event
            layout.coordinator = DragDropCoordinator(for: cell, in: session)
            layout.coordinator.oldEvent = event
            return [dragItem]
        }

        return []
    }

    public func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {

    }

}



struct ConcreteEvent: Event, Codable {
    var day: Day
    var start: Time
    var end: Time

    init(day: Day, start: Time, end: Time) {
        self.day = day
        self.start = start
        self.end = end
    }

    init(event: Event) {
        self.day = event.day
        self.start = event.start
        self.end = event.end
    }
}

final class AnyEvent: NSObject, NSItemProviderWriting, NSItemProviderReading {
    static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> AnyEvent {
        return try AnyEvent(data: data)
    }

    let event: Event

    init(event: Event) {
        self.event = event
    }

    static func decode<T: Event>(data: Data) throws -> T {
        return try JSONDecoder().decode(T.self, from: data)
    }

    convenience init(data: Data) throws {
        let concrete: ConcreteEvent = try AnyEvent.decode(data: data)
        self.init(event: concrete)
    }

    static var writableTypeIdentifiersForItemProvider: [String] {
        return [kUTTypeData as String]
    }

    static var readableTypeIdentifiersForItemProvider: [String] {
        return [kUTTypeData as String]
    }

    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        let progress = Progress(totalUnitCount: 100)

        do {
            let data = try event.toJSONData()
            progress.completedUnitCount = 100
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }

        return progress
    }

}
