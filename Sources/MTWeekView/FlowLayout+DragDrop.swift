//
//  File.swift
//  
//
//  Created by MacBook on 4/19/20.
//

import UIKit

class DragDropCoordinator {

    var cell: MTBaseCell
    var initialTapLocation: CGPoint
    var sourceIndexPath: IndexPath
    var collectionView: UICollectionView

    var event: Event {
        return cell.event
    }

    init(for view: UICollectionView, position: CGPoint, sourceIndexPath: IndexPath) {
        self.cell = view.cellForItem(at: sourceIndexPath) as! MTBaseCell
        self.collectionView = view
        self.sourceIndexPath = sourceIndexPath
        self.initialTapLocation = position
    }

    func currentFrame(at location: CGPoint) -> CGRect {
        var frame = cell.frame

        frame.origin.x += location.x - initialTapLocation.x
        frame.origin.y += location.y - initialTapLocation.y

        return frame
    }

    func intersects(at location: CGPoint) -> MTBaseCell? {
        let frame = currentFrame(at: location)
        guard let cells = collectionView.visibleCells as? [MTBaseCell] else { return nil }

        for cell in cells {
            if cell.frame.intersects(frame) && cell != self.cell {
                cell.overlayed = true
                return cell
            }
            cell.overlayed = false
        }
        
        return nil
    }
    
}

extension MTWeekView: UICollectionViewDropDelegate {

    public func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let finalLocation = coordinator.session.location(in: collectionView)

        guard
            let context = coordinator.session.localDragSession?.localContext as? DragDropCoordinator,
            let section = layout.daySection(at: finalLocation),
            let day = Day(rawValue: section)
        else { return }

        let start = layout.time(at: context.currentFrame(at: finalLocation))
        let end = start + (context.event.end - context.event.start)
        
        eventProvider?.move(context.cell.event, to: day, start: start, end: end)
        invalidate()

    }
    
    public func collectionView(_ collectionView: UICollectionView, dropSessionDidEnter session: UIDropSession) {
        //print("etner")
    }


    public func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        session.canLoadObjects(ofClass: AnyEvent.self)
    }

    public func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let proposal = UICollectionViewDropProposal(operation: .move)
        guard let context = session.localDragSession?.localContext as? DragDropCoordinator else { return proposal }

        let location = session.location(in: collectionView)
        if let cell = context.intersects(at: location) {
//            cell.overlayed = true
        }
        return proposal
    }


}

extension MTWeekView: UIDropInteractionDelegate {
    public func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        if session.localDragSession?.localContext is DragDropCoordinator {
            moveItems(session)
        } else {
            for item in session.items {
                if item.itemProvider.canLoadObject(ofClass: AnyEvent.self) {
                    item.itemProvider.loadObject(ofClass: AnyEvent.self) { (loaded, _) in
                        if let event = (loaded as? AnyEvent)?.event {
                            self.eventProvider?.insert(event)
                        }
                    }
                }
            }
            invalidate()
        }
    }
    
    public func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        session.canLoadObjects(ofClass: AnyEvent.self)
    }
    
    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        if let _ = session.localDragSession?.localContext as? DragDropCoordinator {
            return UIDropProposal(operation: .move)
        } else {
            return UIDropProposal(operation: .copy)
        }
    }
    
    func moveItems(_ session: UIDropSession) {
        let finalLocation = session.location(in: collectionView)

        guard
            let context = session.localDragSession?.localContext as? DragDropCoordinator,
            let section = layout.daySection(at: finalLocation),
            let day = Day(rawValue: section)
        else { return }

        let start = layout.time(at: context.currentFrame(at: finalLocation))
        let end = start + (context.event.end - context.event.start)
        
        eventProvider?.move(context.cell.event, to: day, start: start, end: end)
        invalidate()
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
