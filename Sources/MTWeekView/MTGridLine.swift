//
//  MTGridLine.swift
//  WeekView
//
//  Created by Maksim Tochilkin on 22.03.2020.
//  Copyright © 2020 Maksim Tochilkin. All rights reserved.
//

import UIKit

class MTGridLine: UICollectionReusableView, ReusableView {
    func configure(with indexPath: IndexPath) {
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemGray
    }
    
    required init?(coder: NSCoder) {
        fatalError("Storyboards? Never heard of them")
    }
}
