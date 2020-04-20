//
//  MTBaseCell.swift
//  
//
//  Created by MacBook on 4/19/20.
//

import UIKit


open class MTBaseCell: UICollectionViewCell, MTConfigurableCell {

    var event: Event!
    var animated = false
    var overlayed: Bool? {
        didSet {
            if !animated {
                animated = true
                animate()
            }
        }
    }

    public func configure(with event: Event) {
        self.event = event
    }

    func animate() {
        let transform: CGAffineTransform = overlayed! ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
        UIView.animate(withDuration: 0.2, animations: {
            self.transform = transform
        }) { _ in
            self.animated = false
        }

    }
    
    //needs to hold and event
    //needs to know its position AND frame within the grid
    //needs to be a Drop destination
    //needs to be able to convert from position to time ??? other class

    //boolean isDragging
    //anchor
    //size
    //current origin
    

    
}
