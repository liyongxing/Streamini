//
//  UIEdgeInsets.swift
//  Streamini
//
//  Created by Cloud Stream on 17/07/15.
//  Copyright (c) 2015 Streamini. All rights reserved.
//

import UIKit

extension UIEdgeInsets {    
    var inverse : UIEdgeInsets {
        return UIEdgeInsets(top: -top, left: -left, bottom: -bottom, right: -right)
    }
    func apply(rect: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(rect, self)
    }
}
