//
//  WeekViewFlowLayout.swift
//  WeekView
//
//  Created by Maksim Tochilkin on 21.03.2020.
//  Copyright © 2020 Maksim Tochilkin. All rights reserved.
//

//TODO: 1. Consider grid line thickness while calculating frame
//      2. Add more gridlines for timelineView and headerView

import UIKit

internal protocol MTWeekViewCollectionLayoutDelegate {
    func events(for day: Day) -> [Event]?
}

internal class MTWeekViewCollectionLayout: UICollectionViewLayout {
    
    var delegate: MTWeekViewCollectionLayoutDelegate?
    
    var headerHeight: CGFloat = 30
    var timelineWidth: CGFloat = 40
    
    var totalHours: Int = 24
    var heightPerHour: CGFloat = 50
    
    var gridHeight: CGFloat {
        return gridEndY - gridStartY
    }
    var gridWidth: CGFloat = 0
    
    var horizontalLineCount: Int = 0
    var verticalLineCount: Int = 0
    
    var unitHeight: CGFloat = 0
    var unitWidth: CGFloat = 0
    
    var gridStartY: CGFloat = 0
    var gridEndY: CGFloat = 0
    
    var gridUnitHeight: CGFloat {
        return gridHeight / CGFloat(horizontalLineCount)
    }
    var gridUnitWidth: CGFloat = 0
    
    typealias AttDict = [IndexPath: UICollectionViewLayoutAttributes]
    typealias Attributes = UICollectionViewLayoutAttributes
    
    var allAttributes: [UICollectionViewLayoutAttributes] = []
    var headerCache: AttDict = [:]
    var timelineCache: AttDict = [:]
    var gridCache: AttDict = [:]
    var eventCache: AttDict = [:]

    var sectionsBounds: [Int: ClosedRange<CGFloat>] = [:]
    var timelineBounds: [Int: ClosedRange<CGFloat>] = [:]
    var grid: Grid!
    
    var config: LayoutConfiguration
    var range: (start: Time, end: Time)
    var lineWidth: CGFloat

    var strategy: CollisionStrategy

    private enum Sections: Int {
        case Header = 1
        case Timeline = 2
    }
    
    init(configuration: LayoutConfiguration) {
        self.config = configuration
        self.range = configuration.range
        self.lineWidth = configuration.gridLineThickness
        self.strategy = configuration.collisionStrategy.strategy
        self.timelineWidth = configuration.timelineWidth
        self.headerHeight = configuration.headerHeight

        super.init()
        self.register(MTGridLine.self, forDecorationViewOfKind: MTGridLine.reuseId)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        guard allAttributes.isEmpty else { return }

        calculateParams()
        layout()
        populateBounds()
        populateTimelineBounds()
            
        allAttributes.append(contentsOf: headerCache.values)
        allAttributes.append(contentsOf: timelineCache.values)
        allAttributes.append(contentsOf: gridCache.values)
        allAttributes.append(contentsOf: eventCache.values)
        
    }

    func resetParams() {
        headerHeight = 10
    }

    func clearCache() {
        allAttributes = []
        headerCache = [:]
        timelineCache = [:]
        gridCache = [:]
        eventCache = [:]
    }

    func calculateParams() {
        guard let collectionView = collectionView else { return }
        
        horizontalLineCount = (range.start.hour ... range.end.hour).count
        verticalLineCount = config.totalDays

        gridWidth = collectionView.bounds.width - CGFloat(timelineWidth)
        
        unitHeight = collectionView.bounds.height / CGFloat(horizontalLineCount) - config.gridLineThickness
        unitWidth = gridWidth / CGFloat(config.totalDays)
        
        gridUnitWidth = gridWidth / CGFloat(config.totalDays)
        headerHeight = max(unitHeight, 15)

        grid = Grid(frame: CGRect(x: timelineWidth, y: headerHeight * 3 / 2 , width: gridWidth, height: gridHeight))

    }

    func layout() {
        if timelineCache.isEmpty {
            layoutTimeline()
            layoutHeader()
            layoutGrid()
        }
        layoutEvents()
    }

    func updateEvent(_ event: inout Event, for rect: CGRect) {
        event.day = .Monday
    }

    func populateBounds() {
        for (indexPath, attributes) in headerCache {
            let range: ClosedRange<CGFloat> = attributes.frame.minX ... attributes.frame.maxX
            sectionsBounds[indexPath.item] = range
        }
    }

    func populateTimelineBounds() {
        for (indexPath, attributes) in timelineCache {
            let frame = attributes.frame
            let range: ClosedRange<CGFloat> = frame.centerY ... frame.minY + frame.height + lineWidth
            timelineBounds[indexPath.item] = range
        }
    }

    func daySection(at point: CGPoint) -> Int? {
        for (section, range) in sectionsBounds {
            if case range = point.x {
                return section
            }
        }
        return nil
    }

    func map(_ value: CGFloat, _ minVal: CGFloat, _ maxVal: CGFloat, _ min: CGFloat, _ max: CGFloat) -> CGFloat {
        return (value - minVal) / (maxVal - minVal) * (max - min) + min
    }

    func time(at rect: CGRect) -> Time {
        let minY = gridStartY
        let maxY = gridEndY
        let minTime = CGFloat(config.range.start.hour)
        let maxTime = CGFloat(config.range.end.hour)

        let time = map(rect.minY, minY, maxY, minTime, maxTime)
        if time < minTime {
            return config.start
        } else if time > maxTime {
            return config.end
        } else {
            var decimal = time.truncatingRemainder(dividingBy: 1.0)
            let hour = Int(time)
            if decimal < 0.05 || decimal > 0.95 {
                decimal = decimal.rounded(.toNearestOrAwayFromZero)
            }
            let minute = Int(decimal * 60)
            return Time(hour: hour, minute: minute)
        }

    }

    func rect(section: Int) -> CGRect? {
        let indexPath = IndexPath(item: section, section: Sections.Header.rawValue)
        return headerCache[indexPath]?.frame
    }
    
    func layoutGrid() {

        let firstTimlineIndex = IndexPath(item: range.start.hour, section: Sections.Timeline.rawValue)
        let firstTimelineAtt = timelineCache[firstTimlineIndex]

        //TODO: Make iteration through day and time range respectively
        for (indexPath, headerAtt) in headerCache {
            var origin = headerAtt.frame.origin
            origin.y = firstTimelineAtt?.frame.center.y ?? headerHeight + headerHeight / 2

            let frame = CGRect(origin: origin, size: CGSize(width: lineWidth, height: gridHeight))
            let attributes = Attributes(forDecorationViewOfKind: MTGridLine.reuseId, with: indexPath)
            attributes.frame = frame
            attributes.zIndex = 2
            attributes.isHidden = config.hidesVerticalLines

            gridCache[indexPath] = attributes

        }

        for (indexPath, timeLineAtt) in timelineCache {
            var origin = timeLineAtt.frame.center
            origin.x = timelineWidth

            let frame = CGRect(origin: origin, size: CGSize(width: gridWidth, height: lineWidth))
            let attributes = Attributes(forDecorationViewOfKind: MTGridLine.reuseId, with: indexPath)
            attributes.frame = frame
            attributes.zIndex = 0
            attributes.alpha = 0.3

            gridCache[indexPath] = attributes

        }
    }
    
    func layoutEvents() {
        for day in Day.allCases {
            guard let events = delegate?.events(for: day) else { continue }

            var frames = [CGRect]()
            for event in events {
                guard let frame = frame(for: event) else { continue }
                frames.append(frame)
            }

            frames = strategy.apply(frames: frames)

            for (index, frame) in frames.enumerated() {
                let indexPath = IndexPath(item: index, section: day.index)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = frame
                attributes.zIndex = 1
                eventCache[indexPath] = attributes
            }
        }
    }


    func frame(for event: Event) -> CGRect? {

        let startIndexPath = IndexPath(item: event.start.hour, section: Sections.Timeline.rawValue)
        let endIndexPath = IndexPath(item: event.end.hour, section: Sections.Timeline.rawValue)
        let dayIndexPath = IndexPath(item: event.day.index, section: Sections.Header.rawValue)

        guard
            let startAttributes = timelineCache[startIndexPath],
            let endAttributes = timelineCache[endIndexPath],
            let dayAttributes = headerCache[dayIndexPath]
        else { return nil }

        let startHourY = startAttributes.frame.centerY
        let startMinY = CGFloat(event.start.minute) * gridUnitHeight / 60
        let startY = startHourY + startMinY

        let endHourY = endAttributes.frame.centerY
        let endMinY = CGFloat(event.end.minute) * gridUnitHeight / 60
        let height = endHourY + endMinY - startY

        let xOffset = dayAttributes.frame.origin.x
        let frame = CGRect(x: xOffset, y: startY, width: unitWidth, height: height)
        let insets = UIEdgeInsets(top: lineWidth, left: lineWidth, bottom: 0, right: 0)
        return frame.inset(by: insets)
    }

    func layoutHeader() {
        var xOffset: CGFloat = timelineWidth

        for day in 0 ..< config.totalDays {
            let indexPath = IndexPath(item: day, section: Sections.Header.rawValue)
            let frame = CGRect(x: xOffset, y: 0, width: unitWidth, height: headerHeight)

            let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: MTDayHeader.reuseId, with: indexPath)

            attributes.frame = frame
            attributes.zIndex = 1
            headerCache[indexPath] = attributes
            xOffset += unitWidth
        }

    }

    func layoutTimeline() {
        var yOffset: CGFloat = max(headerHeight - unitHeight / 2, 0)

        for time in 0..<horizontalLineCount {
            let indexPath = IndexPath(item: time + range.start.hour, section: Sections.Timeline.rawValue)
            let frame = CGRect(x: 0, y: yOffset, width: timelineWidth, height: unitHeight - config.gridLineThickness)

            let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: MTTimelineHeader.reuseId, with: indexPath)

            attributes.frame = frame
            attributes.zIndex = 1
            timelineCache[indexPath] = attributes
            yOffset += unitHeight - config.gridLineThickness
        }
        
        let startPath = IndexPath(item: range.start.hour, section: Sections.Timeline.rawValue)
        gridStartY = timelineCache[startPath]!.center.y
        var endPath = startPath
        endPath.item += horizontalLineCount - 1
        gridEndY = timelineCache[endPath]!.center.y
    }
    
    private var contentWidth: CGFloat {
      guard let collectionView = collectionView else {
        return 0
      }
      let insets = collectionView.contentInset
      return collectionView.bounds.width - (insets.left + insets.right)
    }
    
    private var contentHeight: CGFloat {
        collectionView?.bounds.height ?? 0
    }

    override var collectionViewContentSize: CGSize {
        CGSize(width: contentWidth, height: contentHeight)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var visibleAttributes = [Attributes]()

        for attribute in allAttributes {
            if attribute.frame.intersects(rect) {
                visibleAttributes.append(attribute)
            }
        }
        return visibleAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        eventCache[indexPath]
    }

}

