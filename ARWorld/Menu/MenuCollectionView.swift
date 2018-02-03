//
//  MenuCollectionView.swift
//  ARWorld
//
//  Created by TSD044 on 2018-02-02.
//  Copyright © 2018 sudo-world. All rights reserved.
//

import Foundation
import UIKit


protocol MenuCollectionViewDelegate: class {
    func didTapCell(assetType: NodeAssetType)
}

class MenuCollectionView: UICollectionView {
    var allMenuAssets = NodeAssetType.assetTypesForMenu()

    weak var menuCollectionDelegate: MenuCollectionViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.delegate = self
        self.dataSource = self
    }
}

extension MenuCollectionView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allMenuAssets.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AssetMenuItemCell", for: indexPath) as? AssetMenuItemCell {
            let currentMenuItem = allMenuAssets[indexPath.row]
            cell.config(image: currentMenuItem.menuImage())
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.menuCollectionDelegate?.didTapCell(assetType: allMenuAssets[indexPath.row])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }
}

class AssetMenuItemCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.addCornerRadius()
        self.addTopHighlight()
        self.addGrayDiagonalShading()
        self.addBottomShadow()
    }
    
    func config(image: UIImage) {
        self.imageView.image = image
    }
}

extension UIView {
    static var cornerRadius: CGFloat = 30
    
    func addCornerRadius() {
        self.layer.cornerRadius = UIView.cornerRadius
        self.layer.masksToBounds = true
    }
    
    func addGrayDiagonalShading() {
        let topLeftColor = UIColor.black.withAlphaComponent(0.3)
        let bottomRightColor = UIColor.white.withAlphaComponent(0)
        
        let gradient = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.startPoint = CGPoint.zero
        gradient.endPoint = CGPoint(x: 0.8, y: 0.8)
        gradient.colors = [topLeftColor.cgColor, bottomRightColor.cgColor]
        self.layer.insertSublayer(gradient, at: 0)
    }
    
    func addTopHighlight() {
        let topColor = UIColor.white.withAlphaComponent(1).cgColor
        let bottomColor = UIColor.white.withAlphaComponent(0).cgColor
        let height: CGFloat = 12
        
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: height)
        gradient.startPoint = CGPoint.zero
        gradient.endPoint = CGPoint(x: 0, y: 1.0)
        gradient.colors = [topColor, bottomColor]
        self.layer.insertSublayer(gradient, at: 0)
    }
    
    func addBottomShadow() {
        let topColor = UIColor.white.withAlphaComponent(0).cgColor
        let bottomColor = UIColor.black.withAlphaComponent(0.2).cgColor
        let height: CGFloat = 12
        
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: self.bounds.height - height, width: self.bounds.width, height: height)
        gradient.startPoint = CGPoint(x: 0, y: 1)
        gradient.endPoint = CGPoint(x: 0, y: 0.4)
        gradient.colors = [bottomColor, topColor]
        self.layer.insertSublayer(gradient, at: 0)
    }
}




//
//class OldCarouselCell<ItemCell: UICollectionViewCell>: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource where ItemCell: OldCarouselItemCell {
//    private var collectionViewHeightConstraint: NSLayoutConstraint!
//    fileprivate var collectionView: UICollectionView!
//    fileprivate var storedOffsets = [Int: CGFloat]()
//    fileprivate var models: [ItemCell.Model] = []
//    fileprivate var didSelectCell: ((IndexPath) -> Void)?
//
//    // If nothing is showing up, make sure collectionHeight is greater than item height
//    // If you're using nibs, set width and height on the nib
//    fileprivate var collectionHeight: CGFloat = 170 {
//        didSet {
//            collectionViewHeightConstraint.constant = collectionHeight
//        }
//    }
//
//    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//
//        collectionView = createCollectionView()
//        collectionView.delegate = self
//        collectionView.dataSource = self
//
//        contentView.addSubview(collectionView)
//        collectionView.constrainToSuperView()
//
//        collectionViewHeightConstraint = collectionView.heightAnchor.activateConstraint(equalToConstant: collectionHeight, priority: 999)
//
//        if ItemCell.hasNib() {
//            collectionView.register(UINib(nibName: String(describing: ItemCell.self), bundle: nil), forCellWithReuseIdentifier: ItemCell.reuseId())
//        } else {
//            collectionView.register(ItemCell.self, forCellWithReuseIdentifier: ItemCell.reuseId())
//        }
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    private func createCollectionView() -> UICollectionView {
//        let layout = UICollectionViewFlowLayout()
//        layout.scrollDirection = .horizontal
//        layout.estimatedItemSize = CGSize(width: 80, height: 80) // An arbitary number smaller than collectionView height
//
//        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
//        collectionView.backgroundColor = .white
//        collectionView.showsHorizontalScrollIndicator = false
//
//        return collectionView
//    }
//
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return models.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ItemCell.reuseId(), for: indexPath) as? ItemCell {
//            let model = models[indexPath.row]
//            cell.configure(model: model)
//            cell.tag = indexPath.row
//            return cell
//        }
//        return ItemCell()
//    }
//
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        self.didSelectCell?(indexPath)
//    }
//}

