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
    var coordinator: DragDropCoordinator!
    
    var headerHeight: CGFloat = 30
    var timelineWidth: CGFloat = 40
    
    var totalHours: Int = 24
    var heightPerHour: CGFloat = 50
    
    var gridHeight: CGFloat = 0
    var gridWidth: CGFloat = 0
    
    var horizontalLineCount: Int = 0
    var verticalLineCount: Int = 0
    
    var unitHeight: CGFloat = 0
    var unitWidth: CGFloat = 0
    
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

    private enum Sections: Int {
        case Header = 1
        case Timeline = 2
    }
    
    init(configuration: LayoutConfiguration) {
        self.config = configuration
        self.range = configuration.range
        self.lineWidth = configuration.gridLineThickness

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
        eventCache = [:]
    }

    func calculateParams() {
        guard let collectionView = collectionView else { return }

        gridHeight = collectionView.bounds.height - CGFloat(headerHeight)
        gridWidth = collectionView.bounds.width - CGFloat(timelineWidth)
        
        totalHours = range.end.hour - range.start.hour
        
        horizontalLineCount = range.end.hour - range.start.hour
        verticalLineCount = config.totalDays
        
        unitHeight = gridHeight / CGFloat(horizontalLineCount)
        unitWidth = gridWidth / CGFloat(config.totalDays)

        grid = Grid(frame: CGRect(x: timelineWidth, y: headerHeight * 3 / 2 , width: gridWidth, height: gridHeight))

    }

    func layout() {
        if timelineCache.isEmpty {
            layoutHeader()
            layoutTimeline()
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
        let minY = headerHeight / 2 + unitHeight / 2
        let maxY = minY + gridHeight
        let minTime = CGFloat(config.range.start.hour)
        let maxTime = CGFloat(config.range.end.hour)

        let time = map(rect.minY, minY, maxY, minTime, maxTime)
        if time < minTime {
            return config.start
        } else if time > maxTime {
            return config.end
        } else {
            let decimal = time.truncatingRemainder(dividingBy: 1.0)
            let hour = Int(time)
            let minute = decimal < 0.05 || decimal > 0.95 ? 0 : Int(decimal * 60)
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

    class ClusterNode: CustomDebugStringConvertible {
        var attribute: Attributes
        var next: ClusterNode?

        init(attribute: Attributes) {
            self.attribute = attribute
        }

        var debugDescription: String {
            """
            Item: \(attribute.indexPath.item)
            X:    \(attribute.frame.origin.x)
            """
        }

        func lastIntersection(with cluster: ClusterNode) -> ClusterNode? {
            var curr: ClusterNode? = self
            var last: ClusterNode? = nil

            while curr != nil {
                if curr!.attribute.frame.intersects(cluster.attribute.frame) {
                    last = curr
                }
                curr = curr?.next
            }

            return last
            //return _lastIntersection(curr: self, cluster: cluster)
        }

//        func _lastIntersection(curr: ClusterNode?, cluster: ClusterNode) -> ClusterNode? {
//            guard let curr = curr else { return nil }
//
//            if !curr.attribute.frame.intersects(cluster.attribute.frame) {
//                if curr.next != nil {
//                    return nil
//                }
//            }
//
//            return _lastIntersection(curr: curr.next, cluster: cluster)
//        }

        func insert(_ cluster: ClusterNode) {
            let temp = self.next
            self.next = cluster
            cluster.next = temp

            let rect = self.attribute.frame.intersection(cluster.attribute.frame)
            print(rect.height)
            print(attribute.frame.height)

            if rect.height / self.attribute.frame.height > 0.8 {
                attribute.frame.size.width = attribute.frame.size.width / 2
                cluster.attribute.frame.size.width = attribute.frame.size.width
                cluster.attribute.frame.origin.x = attribute.frame.maxX
            } else {
                let newX = self.attribute.frame.origin.x + 4
                cluster.attribute.frame.origin.x = newX
            }
        }
    }
    
    func layoutEvents() {
        for day in Day.allCases {
            guard let events = delegate?.events(for: day) else { continue }

            var clusters = [ClusterNode]()
            for (index, event) in events.enumerated() {
                guard let frame = frame(for: event) else { continue }
                let indexPath = IndexPath(item: index, section: day.index)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = frame
                attributes.zIndex = 1
                insertCluster(attributes, in: &clusters)
                eventCache[indexPath] = attributes
            }
        }
    }

    func insertCluster(_ attribute: Attributes, in clusters: inout [ClusterNode]) {
        let newCluster = ClusterNode(attribute: attribute)

        for cluster in clusters {
            if let last = cluster.lastIntersection(with: newCluster) {
                last.insert(newCluster)
//                print(String(reflecting: last))
//                print(String(reflecting: newCluster))
                return
            }
        }

        clusters.append(newCluster)

    }

//    func insertCluster(_ attribute: Attributes, in allAttributes: [ClusterNode]) {
//        var intersections: CGFloat = 0
//
//        for attr in allAttributes {
//            if attr.frame.minY == attribute.frame.minY {
//                let newWidth = attr.frame.width / 2
//                attribute.frame.size.width = newWidth
//                attr.frame.size.width = newWidth
//                attribute.frame.origin.x = attr.frame.origin.x + attribute.size.width
//                return
//            }
//            if attribute.frame.intersects(attr.frame) {
//                intersections += 1
//            }
//        }
//
//        attribute.frame.origin.x += intersections * 4
//        attribute.frame.size.width -= intersections * 4
//    }

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
        let startMinY = CGFloat(event.start.minute) * unitHeight / 60
        let startY = startHourY + startMinY

        let endHourY = endAttributes.frame.centerY
        let endMinY = CGFloat(event.end.minute) * unitHeight / 60
        let height = endHourY + endMinY - startY

        let xOffset = dayAttributes.frame.origin.x + lineWidth
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
        var yOffset: CGFloat = headerHeight / 2

        for time in range.start.hour ... range.end.hour {
            let indexPath = IndexPath(item: time, section: Sections.Timeline.rawValue)
            let frame = CGRect(x: 0, y: yOffset, width: timelineWidth, height: unitHeight)

            let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: MTTimelineHeader.reuseId, with: indexPath)

            attributes.frame = frame
            attributes.zIndex = 1
            timelineCache[indexPath] = attributes
            yOffset += unitHeight
        }
    }

    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else { return .zero }
        return collectionView.bounds.insetBy(dx: 0, dy: -unitHeight).size
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

    var initialLocation: CGPoint?
}

