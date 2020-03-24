//
//  WeekView.swift
//  WeekView
//
//  Created by Maksim Tochilkin on 21.03.2020.
//  Copyright © 2020 Maksim Tochilkin. All rights reserved.
//

import UIKit


open class MTWeekView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, MTWeekViewCollectionLayoutDelegate {
    
    public var dataSource: MTWeekViewDataSource? {
        didSet {
            getEvents()
            getHourRange()
        }
    }
    var layout: MTWeekViewCollectionLayout!
    
    var collectionView: UICollectionView!
    var configuration: LayoutConfiguration!
    var allEvents:[Day: [Event]] = [:]
    var range = (start: Time(hour: 0, minute: 0), end: Time(hour: 23, minute: 0))
    var cellType: MTSelfConfiguringEventCell.Type?
    
    
    public init(frame: CGRect, configuration: LayoutConfiguration) {
        super.init(frame: frame)
        self.configuration = configuration
        
        layout = MTWeekViewCollectionLayout(configuration: configuration)
        layout.delegate = self
        collectionView = UICollectionView(frame: self.bounds, collectionViewLayout: layout!)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        registerClasses()
        setupCollectionView()
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    public func invalidate() {
        getEvents()
        getHourRange()
        layout.clearCache()
        collectionView.reloadData()
        layout.invalidateLayout()
    }
    
    
    func getEvents() {
        for day in Day.allCases {
            guard let events = dataSource?.weekView(self, eventsForDay: day) else { continue }
            allEvents[day] = events
        }
    }
    
    func getHourRange() {
        if let range = dataSource?.hourRangeForWeek(self)  {
            self.range = range
        }
    }
    
    func setupCollectionView() {
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        addSubview(collectionView)
    }
    
    public func registerCell<T: UICollectionViewCell>(of type: T.Type) where T: MTSelfConfiguringEventCell {
        self.cellType = type
        self.collectionView.register(type, forCellWithReuseIdentifier: type.reuseId)
    }
    
    public func registerClasses() {
        collectionView.register(MTTimelineHeader.self, forSupplementaryViewOfKind: MTTimelineHeader.reuseId, withReuseIdentifier: MTTimelineHeader.reuseId)
        collectionView.register(MTDayHeader.self, forSupplementaryViewOfKind: MTDayHeader.reuseId, withReuseIdentifier: MTDayHeader.reuseId)
        //collectionView.register(EventCell.self, forCellWithReuseIdentifier: EventCell.reuseId)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        configuration.totalDays + 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let day = Day(rawValue: section), let events = allEvents[day] {
            return events.count
        }
        return 0
    }
    
    func rangeForCurrentWeek(_ collectionView: UICollectionView) -> (start: Time, end: Time) {
        return range
    }
    
    public func collectionView(_ collectionView: UICollectionView, timeRangeForItemAt indexPath: IndexPath) -> (start: Time, end: Time) {
        if let day = Day(rawValue: indexPath.section), let events = allEvents[day] {
            let event = events[indexPath.item]
            return (start: event.start, end: event.end)
        }
        return (start: Time(hour: 0, minute: 0), end: Time(hour: 0, minute: 0))
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: MTSelfConfiguringEventCell
        
        if let type = self.cellType {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: type.reuseId, for: indexPath) as! MTSelfConfiguringEventCell
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: EventCell.reuseId, for: indexPath) as! EventCell
        }
        
        if let day = Day(rawValue: indexPath.section), let events = allEvents[day] {
            let event = events[indexPath.item]
            cell.configure(with: event)
        }
    
        return cell as! UICollectionViewCell
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath)
        (view as? ReusableView)?.configure(with: indexPath)
        return view
    }
}

class EventCell: UICollectionViewCell, MTSelfConfiguringEventCell {
    func configure(with data: Event) {
        
    }
    
    typealias DataType = Event
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemRed, .systemYellow, .systemGray]
        contentView.backgroundColor = colors.randomElement()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Storyboard??? None of that")
    }
}
