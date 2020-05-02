//
//  MTDayHeader.swift
//  WeekView
//
//  Created by Maksim Tochilkin on 22.03.2020.
//  Copyright © 2020 Maksim Tochilkin. All rights reserved.
//

import UIKit

class MTDayHeader: UICollectionReusableView, ReusableView {
    func configure(with indexPath: IndexPath) {
        label.text = Day.allCases[indexPath.item].name
    }
    
    typealias DataType = Day
    
    let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        if frame.size.height != 0 {
            addSubview(label)
            NSLayoutConstraint.activate([
                label.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                label.widthAnchor.constraint(equalToConstant: self.bounds.width)
            ])
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

