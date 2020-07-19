//
//  WeekView.swift
//  WeekView
//
//  Created by Maksim Tochilkin on 21.03.2020.
//  Copyright © 2020 Maksim Tochilkin. All rights reserved.
//

import UIKit
import MobileCoreServices

public protocol MTWeekViewDataSource: class {
    func weekView(_ weekView: MTWeekView, eventsForDay day: Day) -> [Event]
    func allEvents(for weekView: MTWeekView) -> [Event]
}

@IBDesignable
open class MTWeekView: UIView, MTWeekViewCollectionLayoutDelegate {

    //MARK: Public
    public var configuration: LayoutConfiguration! {
        didSet { reload() }
    }
    public weak var dataSource: MTWeekViewDataSource? {
        didSet { reload() }
    }
    public var collectionView: MTCollectionView!

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

    public func reloadDays(days: [Day]) {
        collectionView.reloadSections(IndexSet(days.map { $0.rawValue }))
    }

    override open var intrinsicContentSize: CGSize {
        return layout.collectionViewContentSize
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configuration = LayoutConfiguration()
        commonInit()
    }

    //MARK: Private

    internal var layout: MTWeekViewCollectionLayout!
    internal var eventProvider: EventsProvider?

    var MainCellType: MTBaseCell.Type?


    private func commonInit() {
        layout = MTWeekViewCollectionLayout(configuration: configuration)
        layout.delegate = self
        collectionView = MTCollectionView(frame: self.bounds, collectionViewLayout: layout!)
        registerClasses()
        addSubview(collectionView)
        self.fill(with: collectionView)
        collectionView.dragDelegate = self
//        collectionView.dropDelegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let interaction = UIDropInteraction(delegate: self)
        collectionView.addInteraction(interaction)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        layout.clearCache()
        layout.invalidateLayout()
        print(bounds)
    }
    
    
    private func getEvents() {
//        for day in Day.allCases {
//            guard let events = dataSource?.weekView(self, eventsForDay: day) else { continue }
//            allEvents[day] = events
//        }

        guard let events = dataSource?.allEvents(for: self) else { return }
        eventProvider = EventsProvider(events: events)
    }
    
    private func registerClasses() {
        collectionView.register(MTTimelineHeader.self, forSupplementaryViewOfKind: MTTimelineHeader.reuseId, withReuseIdentifier: MTTimelineHeader.reuseId)
        collectionView.register(MTDayHeader.self, forSupplementaryViewOfKind: MTDayHeader.reuseId, withReuseIdentifier: MTDayHeader.reuseId)
    }

    internal func events(for day: Day) -> [Event]? {
        return eventProvider?.events(for: day)
    }
}

//MARK: Public API

extension MTWeekView {
    public func showEvents(where condition: (Event) -> Bool) {
        eventProvider?.selectEvents(where: condition)
        invalidate()
    }

    public func showAll() {
        eventProvider?.populate()
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
        guard let day = Day(rawValue: section) else { return 0 }
        return eventProvider?.numberOfEvents(for: day) ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let Type = self.MainCellType ?? MTBaseCell.self

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Type.reuseId, for: indexPath)

        if let event = eventProvider?.event(at: indexPath) {
            if let cell = cell as? MTBaseCell {
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

}


extension MTWeekView: UICollectionViewDragDelegate {
    public func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {

        let location = session.location(in: collectionView)
        guard let cell = collectionView.cellForItem(at: indexPath) as? MTBaseCell else { return [] }
        
        if let event = eventProvider?.event(at: indexPath) {
            let provider = NSItemProvider(object: AnyEvent(event: event))
            let dragItem = UIDragItem(itemProvider: provider)

            let coordinator = DragDropCoordinator(for: collectionView, position: location, sourceIndexPath: indexPath)
            session.localContext = coordinator

            return [dragItem]
        }

        return []
    }

}



struct ConcreteEvent: Event, Codable {

    var id: UUID = UUID()

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
