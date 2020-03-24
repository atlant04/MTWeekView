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

protocol MTWeekViewCollectionLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, timeRangeForItemAt indexPath: IndexPath) -> (start: Time, end: Time)
    func rangeForCurrentWeek(_ collectionView: UICollectionView) -> (start: Time, end: Time)
}

class MTWeekViewCollectionLayout: UICollectionViewFlowLayout {
    
    var delegate: MTWeekViewCollectionLayoutDelegate?
    
    var headerHeight: CGFloat = 20
    var heightPerHour: CGFloat = 50
    
    var totalHours: Int = 24
    var totalHeight: CGFloat = 0
    var totalWidth: CGFloat = 0
    var timelineWidth = 40
    
    var horizontalLineCount: Int = 0
    var verticalLineCount: Int = 0
    
    
    var unitHeight: CGFloat = 0
    var unitWidth: CGFloat = 0
    
    typealias AttDict = [IndexPath: UICollectionViewLayoutAttributes]
    
    var allAttributes: [UICollectionViewLayoutAttributes] = []
    var headerCache: AttDict = [:]
    var timelineCache: AttDict = [:]
    var gridCache: [UICollectionViewLayoutAttributes] = []
    var eventCache: [UICollectionViewLayoutAttributes] = []
    
    var config: LayoutConfiguration
    var range: (start: Time, end: Time)!
    
    init(configuration: LayoutConfiguration) {
        self.config = configuration
        super.init()
        self.register(MTGridLine.self, forDecorationViewOfKind: MTGridLine.reuseId)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func clearCache() {
        allAttributes = []
    }
    
    override func prepare() {
        guard allAttributes.isEmpty else { return }
        self.range = delegate?.rangeForCurrentWeek(collectionView!)
        
        setupUIElements()
        timelineCache = layoutAttributesForTimelineView()
        headerCache = layoutAttributesForHeaderView()
        gridCache = layoutAttributesForGridView()
        
        for day in 0 ..< config.totalDays {
            eventCache.append(contentsOf: layoutEvents(for: day))
        }
            
        allAttributes.append(contentsOf: Array(headerCache.values))
        allAttributes.append(contentsOf: Array(timelineCache.values))
        allAttributes.append(contentsOf: gridCache)
        allAttributes.append(contentsOf: eventCache)
        
    }
    
    func setupUIElements() {
        guard let collectionView = collectionView else { return }
        totalHeight = collectionView.bounds.height
        totalWidth = collectionView.bounds.width - CGFloat(timelineWidth)
        
        totalHours = range.end.hour - range.start.hour
        heightPerHour = collectionView.bounds.height / CGFloat(totalHours)
        
        horizontalLineCount = Int(totalHeight / heightPerHour)
        verticalLineCount = config.totalDays
        
        unitHeight = totalHeight / CGFloat(horizontalLineCount)
        unitWidth = totalWidth / CGFloat(verticalLineCount)
    }
    
    func layoutAttributesForGridView() -> [UICollectionViewLayoutAttributes] {
        var result = [UICollectionViewLayoutAttributes]()
        let gridLineThickness = config.gridLineThickness
        
        for (indexPath, headerAttribute) in headerCache {
            let headerFrame = headerAttribute.frame
            let frame = CGRect(x: headerFrame.origin.x, y: headerHeight + unitHeight / 2, width: gridLineThickness, height: totalHeight)
            let attributes = UICollectionViewLayoutAttributes(forDecorationViewOfKind: MTGridLine.reuseId, with: indexPath)
            attributes.frame = frame
            result.append(attributes)
        }
        
        for (indexPath, rowAttribute) in timelineCache {
            let rowViewFrame = rowAttribute.frame
            let frame = CGRect(x: rowViewFrame.size.width, y: rowViewFrame.center.y, width: totalWidth, height: gridLineThickness)
            let attributes = UICollectionViewLayoutAttributes(forDecorationViewOfKind: MTGridLine.reuseId, with: indexPath)
            attributes.frame = frame
            result.append(attributes)
        }
        return result
    }

    
    func layoutEvents(for section: Int) -> [UICollectionViewLayoutAttributes] {
        var result = [UICollectionViewLayoutAttributes]()
        
        for i in 0..<collectionView!.numberOfItems(inSection: section) {
            
            let indexPath = IndexPath(item: i, section: section)
            guard let times = delegate?.collectionView(collectionView!, timeRangeForItemAt: indexPath) else { continue }
            
            let startIndexPath = IndexPath(item: times.start.hour, section: config.totalDays)
            let endIndexPath = IndexPath(item: times.end.hour, section: config.totalDays)
            let dayIndexPath = IndexPath(item: 0, section: section)
            
            if let startAttributes = timelineCache[startIndexPath],
                let endAttributes = timelineCache[endIndexPath],
                let dayAttributes = headerCache[dayIndexPath] {
                
                let startHourY = startAttributes.frame.centerY
                let startMinY = CGFloat(times.start.minute) * unitHeight / 60
                let startY = startHourY + startMinY
                
                let endHourY = endAttributes.frame.centerY
                let endMinY = CGFloat(times.end.minute) * unitHeight / 60
                let height = endHourY + endMinY - startY
                
//                let hourDifference = CGFloat(times.end.hour - times.start.hour)
//                let heightHour = hourDifference * unitHeight
//                let heightMinute = CGFloat(times.end.minute) * unitHeight / 60
//                let gridLineWidth = hourDifference * config.gridLineThickness
//                let height = heightHour + heightMinute + gridLineWidth
//                let x = CGFloat(day.index + 1) * unitWidth
                
                let xOffset = dayAttributes.frame.origin.x
                let frame = CGRect(x: xOffset, y: startY, width: unitWidth, height: height)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = frame
                attributes.zIndex = 1000
                result.append(attributes)
            }
        }
        return result
    }
    
    func layoutAttributesForHeaderView() -> AttDict {
        var result = AttDict()
        var xOffset: CGFloat = CGFloat(timelineWidth)
        
        for count in 0 ..< config.totalDays {
            let indexPath = IndexPath(item: 0, section: count)
            let frame = CGRect(x: xOffset, y: 0, width: unitWidth, height: headerHeight)
            let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: MTDayHeader.reuseId, with: indexPath)
            attributes.frame = frame
            result[indexPath] = attributes
            xOffset += unitWidth
        }
        
        return result
    }
    
    func layoutAttributesForTimelineView() -> [IndexPath: UICollectionViewLayoutAttributes] {
        var result = [IndexPath: UICollectionViewLayoutAttributes]()
        
        var yOffset: CGFloat = headerHeight
        for count in range.start.hour ... range.end.hour {
            let indexPath = IndexPath(item: count, section: config.totalDays)
            let frame = CGRect(x: 0, y: yOffset, width: 40, height: unitHeight + config.gridLineThickness)
            let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: MTTimelineHeader.reuseId, with: indexPath)
            attributes.frame = frame
            attributes.zIndex = 1
            result[indexPath] = attributes
            yOffset += unitHeight
       
        }
        return result
    }
    
    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else { return .zero }
        let width = collectionView.bounds.width
        let height = headerHeight + (heightPerHour * CGFloat(totalHours)) + unitHeight
        return CGSize(width: width, height: height)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var visibleAttributes = [UICollectionViewLayoutAttributes]()
        
        for attribute in allAttributes {
            if attribute.frame.intersects(rect) {
                visibleAttributes.append(attribute)
            }
        }
        return visibleAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        eventCache[indexPath.item]
    }
    
}






//override func prepare() {
//    guard cache.isEmpty, let collectionView = collectionView else { return }
//    let columnWidth = collectionView.bounds.width / CGFloat(days)
//    var xOffset: [CGFloat] = []
//
//    for day in 0 ..< days {
//        xOffset.append(CGFloat(day) * columnWidth)
//    }
//
//    var yOffset: [CGFloat] = Array<CGFloat>(repeating: 0, count: days)
//    let headerAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: IndexPath(item: 0, section: 0))
//    headerAttributes.frame = CGRect(origin: .zero, size: CGSize(width: collectionView.bounds.width, height: 100))
//    headerCache = [headerAttributes]
//
//    let timelineAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: WeekViewSupplementaryView.timeline.rawValue, with: IndexPath(item: 1, section: 0))
//    timelineAttributes.frame = CGRect(x: 0, y: 100, width: 100, height: 200)
//    timelineCache = [timelineAttributes]
//
//    for item in 0 ..< collectionView.numberOfItems(inSection: 0) {
//        let indexPath = IndexPath(item: item, section: 0)
//        let height = CGFloat(50)
//        let numberOfItems = collectionView.numberOfItems(inSection: 0)
//        let row = Int(item / days)
//        let yOffset = CGFloat(row) * height
//        var frame = CGRect(x: xOffset[item % days], y: yOffset, width: height, height: height)
//        frame = frame.insetBy(dx: 5, dy: 5)
//
//
//
//
//        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
//        attributes.frame = frame
//        attributes.zIndex = 1
//        cache.append(attributes)
//    }
//
//}
