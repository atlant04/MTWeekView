//
//  File.swift
//  
//
//  Created by MacBook on 4/19/20.
//

import UIKit

class DragDropCoordinator {
    var cell: MTBaseCell
    var session: UIDragDropSession
    var initialLocation: CGPoint?

    var oldEvent: Event?

    init(for cell: MTBaseCell, in session: UIDragDropSession) {
        self.cell = cell
        self.session = session
    }
    
}

extension MTWeekView: UICollectionViewDropDelegate {

    func coordinates() -> CGPoint {
        let location = layout.coordinator.session.location(in: collectionView!)
        return collectionView!.convert(location, from: layout.grid)
    }

    public func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        var location = coordinates()

        guard let item = coordinator.items.first else { return }
        guard let section = layout.daySection(at: location) else { return }
        let newFrame = CGRect(center: coordinates(), size: item.previewSize)

        if let oldEvent = self.layout.coordinator.oldEvent,
            let newStart = layout.time(at: newFrame),
            let day = Day(rawValue: section) {
            print(newStart)

            let newEnd = newStart + (oldEvent.end - oldEvent.start)
            let newEvent = ConcreteEvent(day: day, start: newStart, end: newEnd)

            print(newEvent)
            let oldDay = Day(rawValue: item.sourceIndexPath!.section)
            let num = collectionView.numberOfItems(inSection: section)
            let finalIndexPath = IndexPath(item: num, section: section)
            if item.sourceIndexPath?.section != section {
                selectedEvents?[oldDay!]?.remove(at: item.sourceIndexPath!.item)
                selectedEvents?[day]?.append(newEvent)
                collectionView.moveItem(at: item.sourceIndexPath!, to: finalIndexPath)
            } else {
                var huh = selectedEvents?[oldDay!]?.first { event in
                    print(event.id)
                    print(oldEvent.id)
                    return event.id == oldEvent.id

                }
                huh!.start = newStart
                huh!.end = newEnd
            }
            coordinator.drop(item.dragItem, toItemAt: finalIndexPath)
    }
        //collectionView.performBatchUpdates({
            //collectionView.reloadData()
            //invalidate()
            //collectionView.insertItems(at: [finalIndexPath])
            //collectionView.moveItem(at: item.sourceIndexPath!, to: finalIndexPath)
//            collectionView.deleteItems(at: [item.sourceIndexPath!])
            reload()
        //}, completion: { _ in
        //})

    }


    public func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        session.canLoadObjects(ofClass: AnyEvent.self)
    }

    public func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let location = layout.coordinator?.session.location(in: collectionView)
//        print("View: \(location)")
//        print("Grid: \(collectionView.convert(location!, to: grid))")
        return UICollectionViewDropProposal(operation: .move)
    }

    public func collectionView(_ collectionView: UICollectionView, dropSessionDidEnter session: UIDropSession) {
        layout.coordinator?.session = session
    }


}


class Grid: NSObject, UICoordinateSpace {
    func convert(_ point: CGPoint, to coordinateSpace: UICoordinateSpace) -> CGPoint {
        var point = point
        point.x += bounds.origin.x
        point.y += bounds.origin.y
        return point
    }

    func convert(_ point: CGPoint, from coordinateSpace: UICoordinateSpace) -> CGPoint {
        var point = point
        point.x -= bounds.origin.x
        point.y -= bounds.origin.y
        return point
    }

    func convert(_ rect: CGRect, to coordinateSpace: UICoordinateSpace) -> CGRect {
        var rect = rect
        let origin = self.convert(rect.origin, to: coordinateSpace)
        rect.origin = origin
        return rect
    }

    func convert(_ rect: CGRect, from coordinateSpace: UICoordinateSpace) -> CGRect {
        var rect = rect
        let origin = self.convert(rect.origin, from: coordinateSpace)
        rect.origin = origin
        return rect
    }

    var bounds: CGRect

    init(frame: CGRect) {
        self.bounds = frame
    }


}
