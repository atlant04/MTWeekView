//
//  MTTimelineHeader.swift
//  WeekView
//
//  Created by Maksim Tochilkin on 22.03.2020.
//  Copyright © 2020 Maksim Tochilkin. All rights reserved.
//

import UIKit

class MTTimelineHeader: UICollectionReusableView, ReusableView {
    
    func configure(with indexPath: IndexPath) {
        label.text = "\(indexPath.item):00"
    }
    
    let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFontMetrics.default.scaledFont(for: UIFont.preferredFont(forTextStyle: .title3), maximumPointSize: 12)
        label.textColor = .secondaryLabel
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemRed, .systemYellow, .systemGray]
        //        backgroundColor = colors.randomElement()!
        if frame.size.width != 0 {
            self.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                //label.widthAnchor.constraint(equalToConstant: self.bounds.width)
            ])
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
