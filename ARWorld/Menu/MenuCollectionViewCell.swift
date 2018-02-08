//
//  MenuCollectionViewCell.swift
//  ARWorld
//
//  Created by TSD040 on 2018-02-07.
//  Copyright © 2018 sudo-world. All rights reserved.
//

import UIKit

class MenuCollectionViewCell: UICollectionViewCell {

    
    @IBOutlet weak var iamgeView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.addCornerRadius()
        self.addTopHighlight()
        self.addGrayDiagonalShading()
        self.addBottomShadow()
    }
    
    func config(image: UIImage) {
        self.iamgeView.image = image
    }

}
