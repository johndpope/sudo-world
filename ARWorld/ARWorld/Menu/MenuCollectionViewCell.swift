//
//  MenuCollectionViewCell.swift
//  ARWorld
//
//  Created by TSD040 on 2018-02-07.
//  Copyright © 2018 sudo-world. All rights reserved.
//

import UIKit

class MenuCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.addCornerRadius()
    }
    
    func config(image: UIImage) {
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        
//        if imageView.layer.sublayers == nil {
//            imageView.addTopHighlight()
//            imageView.addGrayDiagonalShading()
//            imageView.addBottomShadow()
//        }
    }
}
