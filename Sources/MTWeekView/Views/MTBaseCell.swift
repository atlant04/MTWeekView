//
//  MTBaseCell.swift
//  
//
//  Created by MacBook on 4/19/20.
//

import UIKit


open class MTBaseCell: UICollectionViewCell, MTConfigurableCell, UIDropInteractionDelegate {

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

    override public init(frame: CGRect) {
        super.init(frame: frame)
//        let shape = CAShapeLayer()
//        shape.fillColor = UIColor.systemBlue.cgColor
//        shape.frame = CGRect(x: 0, y: 0, width: 2, height: contentView.frame.height)
//        contentView.layer.addSublayer(shape)

        let view = UIView()
        view.backgroundColor = .systemBlue
        view.frame = CGRect(x: 0, y: 0, width: 2, height: contentView.frame.height)
        contentView.addSubview(view)

//        let interaction = UIDropInteraction(delegate: self)
//        addInteraction(interaction)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func animate() {
        let transform: CGAffineTransform = overlayed! ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
        UIView.animate(withDuration: 0.2, animations: {
            self.transform = transform
        }) { _ in
            self.animated = false
        }

    }

    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
        UIView.animate(withDuration: 0.2, animations: {
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        })
    }

    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        UIView.animate(withDuration: 0.2, animations: {
            self.transform = .identity
        })
    }

    public func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        let context = session.localDragSession?.localContext as? DragDropCoordinator
        print(context)
    }

    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return  UIDropProposal(operation: .move)
    }

    public func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        true
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
