//
//  NibView.swift
//  A$AP UI Components
//
//  Created by TSD040 on 2018-02-13.
//  Copyright © 2018 TSD040. All rights reserved.
//

import UIKit

protocol NibView {}

extension NibView where Self: UIView {
    static func instanceFromNib() -> Self? {
        let nibName = String(describing: self)
        return Bundle.main.loadNibNamed(nibName, owner: self, options: nil)?.first as? Self
    }
}
