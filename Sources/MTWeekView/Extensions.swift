//
//  Extensions.swift
//  WeekView
//
//  Created by Maksim Tochilkin on 22.03.2020.
//  Copyright © 2020 Maksim Tochilkin. All rights reserved.
//

import UIKit

extension CGRect {
    init(center: CGPoint, size: CGSize)
    {
        self.init(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    }
    
    /** the coordinates of this rectangles center */
    var center: CGPoint
    {
        get { return CGPoint(x: centerX, y: centerY) }
        set { centerX = newValue.x; centerY = newValue.y }
    }
    
    /** the x-coordinate of this rectangles center
     - note: Acts as a settable midX
     - returns: The x-coordinate of the center
     */
    var centerX: CGFloat
    {
        get { return midX }
        set { origin.x = newValue - width * 0.5 }
    }
    
    /** the y-coordinate of this rectangles center
     - note: Acts as a settable midY
     - returns: The y-coordinate of the center
     */
    var centerY: CGFloat
    {
        get { return midY }
        set { origin.y = newValue - height * 0.5 }
    }
}

extension UIView {
    func fill(view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

extension Encodable {
    func toJSONData() throws -> Data? { try JSONEncoder().encode(self) }

}

extension Decodable {
}

