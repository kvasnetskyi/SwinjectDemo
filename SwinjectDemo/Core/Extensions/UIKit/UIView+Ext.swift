//
//  UIView+Ext.swift
//  SwinjectDemo
//
//  Created by Roman Savchenko on 12.12.2021.
//

import UIKit

extension UIView {
    func bordered(width: CGFloat, color: UIColor) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
    }

    func rounded() {
        rounded(min(bounds.width, bounds.height) / 2)
    }

    func rounded(_ radius: CGFloat) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }
}
