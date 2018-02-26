//
//  NormalModeView.swift
//  ARWorld
//
//  Created by TSD040 on 2018-02-07.
//  Copyright © 2018 sudo-world. All rights reserved.
//

import UIKit

protocol NormalModeViewDelegate: class {
    func selectSudoNodeForEditing(screenCoordinates: CGPoint)
    func resetRequested()
    func didSelectNewNodeToInsert(assetType: NodeAssetType)
}

class NormalModeView: UIView {

    @IBOutlet weak var view: UIView!
    @IBOutlet weak var nodeMenuCollectionViewContainer: UIView!
    @IBOutlet weak var newNodeButton: UIButton!
    @IBOutlet weak var closeMenuButton: UIButton!
    
    weak var delegate: NormalModeViewDelegate?
    
    var collectionView: UICollectionView!
    private var menuBottomConstraint: NSLayoutConstraint!
    private let menuHeight: CGFloat = 175
    
    override func awakeFromNib() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 100, height: 100)
        flowLayout.scrollDirection = .horizontal
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UINib(nibName: String(describing: MenuCollectionViewCell.self), bundle: nil), forCellWithReuseIdentifier: String(describing: MenuCollectionViewCell.self))
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        nodeMenuCollectionViewContainer.addSubview(collectionView)
        
        menuBottomConstraint = nodeMenuCollectionViewContainer.constrainBottom(to: self, offset: menuHeight)
        
        collectionView.constrainTopToBottom(of: closeMenuButton)
        collectionView.constrainBottom(to: nodeMenuCollectionViewContainer, offset: -30)
        collectionView.constrainEdgesHorizontally(to: self)
    }
    
    @IBAction func newNodeButtonPressed(_ sender: UIButton) {
        newNodeButton.isHidden = true
        
        self.menuBottomConstraint.constant = 0.0
        UIView.animate(withDuration: 0.4) {
            self.layoutIfNeeded()
        }
    }
    
    @IBAction func closeNodeMenuPressed(_ sender: UIButton) {
        newNodeButton.isHidden = false
        
        self.menuBottomConstraint.constant = self.menuHeight
        UIView.animate(withDuration: 0.4) {
            self.layoutIfNeeded()
        }
    }
    
    @IBAction func resetButtonPressed(_ sender: UIButton) {
        delegate?.resetRequested()
    }
}

extension NormalModeView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return NodeAssetType.assetTypesForMenu().count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MenuCollectionViewCell.self), for: indexPath) as? MenuCollectionViewCell {
            let currentMenuItem = NodeAssetType.assetTypesForMenu()[indexPath.row]
            cell.config(image: currentMenuItem.menuImage())
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.didTapCell(assetType: NodeAssetType.assetTypesForMenu()[indexPath.row])
    }
    
    func didTapCell(assetType: NodeAssetType) {
        delegate?.didSelectNewNodeToInsert(assetType: assetType)
    }
}

extension NormalModeView: ARModeView {
    func panGestureDidChange(_ gestureRecognizer: UIPanGestureRecognizer, screenCoordinates: CGPoint) {}
    
    func tapGestureDidChange(_ gestureRecognizer: UITapGestureRecognizer, screenCoordinates: CGPoint) {
        delegate?.selectSudoNodeForEditing(screenCoordinates: screenCoordinates)
    }
    
    func rotationGestureDidChange(_ gestureRecognizer: UIRotationGestureRecognizer) {}
    
    func pinchGestureDidChange(_ gestureRecognizer: UIPinchGestureRecognizer) {}
}
