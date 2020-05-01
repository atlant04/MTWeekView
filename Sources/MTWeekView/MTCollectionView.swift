//
//  MTCollectionView.swift
//  
//
//  Created by MacBook on 4/30/20.
//

import UIKit

open class MTCollectionView: UICollectionView {

    var lastTouchPos: CGPoint?

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPos = touches.first?.location(in: self)
        NotificationCenter.default.post(name: Notification.Name("touch"), object: lastTouchPos)
    }
}
