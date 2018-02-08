//
//  NormalModeView.swift
//  ARWorld
//
//  Created by TSD040 on 2018-02-07.
//  Copyright © 2018 sudo-world. All rights reserved.
//

import UIKit

protocol NormalModeViewDelegate: class {
    func didRecieveTap(screenLocation: CGPoint)
    func resetRequested()
    func didSelectNewNodeToInsert(assetType: NodeAssetType)
}

class NormalModeView: UIView {

    @IBOutlet weak var view: UIView!
    @IBOutlet weak var nodeMenuCollectionViewContainer: UIView!
    @IBOutlet weak var newNodeButton: UIButton!
    @IBOutlet weak var nodeMenuCollectionView: MenuCollectionView!
    
    weak var delegate: NormalModeViewDelegate?
    
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//
//        let flowLayout = UICollectionViewFlowLayout()
//        flowLayout.itemSize = CGSize.init(width: 100, height: 100)
//        let alskdjf = MenuCollectionView(frame: CGRect.zero,collectionViewLayout: flowLayout)
//        nodeMenuCollectionViewContainer.addSubview(alskdjf)
//        alskdjf.frame = nodeMenuCollectionViewContainer.bounds
//
//        nodeMenuCollectionView.menuCollectionDelegate = self
//    }
    
    override func awakeFromNib() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize.init(width: 100, height: 100)
        flowLayout.scrollDirection = .horizontal
        let collectionView = MenuCollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.menuCollectionDelegate = self
        collectionView.isUserInteractionEnabled = true
        nodeMenuCollectionView = collectionView
        
        nodeMenuCollectionViewContainer.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: nodeMenuCollectionViewContainer.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: nodeMenuCollectionViewContainer.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: nodeMenuCollectionViewContainer.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: nodeMenuCollectionViewContainer.trailingAnchor)
            ])
        
    }

    @IBAction func handleTapGesture(_ sender: UITapGestureRecognizer) {
        delegate?.didRecieveTap(screenLocation: sender.location(in: self.view))
    }
    
    @IBAction func newNodeButtonPressed(_ sender: UIButton) {
        newNodeButton.isHidden = true
        nodeMenuCollectionViewContainer.isHidden = false
//        nodeMen?uCollectionView.reloadData()
    }
    
    @IBAction func closeNodeMenuPressed(_ sender: UIButton) {
        newNodeButton.isHidden = false
        nodeMenuCollectionViewContainer.isHidden = true
    }
    
    @IBAction func resetButtonPressed(_ sender: UIButton) {
        delegate?.resetRequested()
    }
}

extension NormalModeView: MenuCollectionViewDelegate {
    func didTapCell(assetType: NodeAssetType) {
        delegate?.didSelectNewNodeToInsert(assetType: assetType)
    }
 
}
