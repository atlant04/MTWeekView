//
//  MTCollectionView.swift
//  
//
//  Created by MacBook on 4/30/20.
//

import UIKit

open class MTCollectionView: UICollectionView {

    var lastTouchPos: CGPoint?
    
    override public init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        dragInteractionEnabled = true
        isUserInteractionEnabled = true
        isScrollEnabled = true
        backgroundColor = .systemBackground
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPos = touches.first?.location(in: self)
        NotificationCenter.default.post(name: Notification.Name("touch"), object: lastTouchPos)
    }
}
