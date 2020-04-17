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
        collectionView.reloadData()
        layout.invalidateLayout()
    }

    override open var intrinsicContentSize: CGSize {
        return layout.collectionViewContentSize
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: Private

    private var layout: MTWeekViewCollectionLayout!
    private var allEvents: [Day: [Event]] = [:]
    private var selectedEvents: [Day: [Event]]?


    typealias MainCell = (UICollectionViewCell & MTConfigurableCell)
    var MainCellType: MainCell.Type?


    private func commonInit() {
        layout = MTWeekViewCollectionLayout(configuration: configuration)
        layout.delegate = self
        collectionView = UICollectionView(frame: self.bounds, collectionViewLayout: layout!)
        registerClasses()
        setupCollectionView()
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.fill(view: self)
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
        if let events = allEvents[day] {
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

    public func register<T: UICollectionViewCell>(_ type: T.Type) where T: MTConfigurableCell {
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

        if let cell = cell as? MainCell {
            if let day = Day(rawValue: indexPath.section), let events = eventsToShow[day] {
                let event = events[indexPath.item]
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

