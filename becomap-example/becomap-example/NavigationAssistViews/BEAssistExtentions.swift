//
//  BEAssistExtentions.swift
//  MapAssistView
//
//  Created by test on 28/10/19.
//  Copyright © 2019 GlobeCo Technologies Pvt Ltd. All rights reserved.
//

import UIKit

extension UIView {
    var safeTopAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide.topAnchor
        }
        return topAnchor
    }

    var safeLeftAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide.leftAnchor
        }
        return leftAnchor
    }

    var safeRightAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide.rightAnchor
        }
        return rightAnchor
    }

    var safeBottomAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide.bottomAnchor
        }
        return bottomAnchor
    }

    var safeLeadingAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide.leadingAnchor
        }
        return leadingAnchor
    }

    var safeTrailingAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide.trailingAnchor
        }
        return trailingAnchor
    }
}

@IBDesignable
public extension UIView {
    @IBInspectable
    var borderRadius: CGFloat {
        set(radius) {
            layer.cornerRadius = radius
            layer.masksToBounds = radius > 0
        }
        get {
            return layer.cornerRadius
        }
    }

    @IBInspectable
    var borderWidth: CGFloat {
        set(borderWidth) {
            layer.borderWidth = borderWidth
        }
        get {
            return layer.borderWidth
        }
    }

    @IBInspectable
    var borderColor: UIColor? {
        set(color) {
            layer.borderColor = color?.cgColor
        }
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            } else {
                return nil
            }
        }
    }
}

extension UIView {
    func show(
        duration: TimeInterval = 0.5,
        delay: TimeInterval = 0.0,
        completion: @escaping ((Bool) -> Void) = { (_: Bool) in }
    ) {
        alpha = 0.0
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.isHidden = false
            self.alpha = 1.0
        }, completion: completion)
    }

    func hide(
        duration: TimeInterval = 0.5,
        delay: TimeInterval = 0.0,
        completion: @escaping (Bool) -> Void = { (_: Bool) in }
    ) {
        alpha = 1.0
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.alpha = 0.0
        }) { _ in
            self.isHidden = true
            completion(true)
        }
    }
}

extension UITableView {
    func scrollToBottom() {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            let indexPath = IndexPath(
                row: weakSelf.numberOfRows(inSection: weakSelf.numberOfSections - 1) - 1,
                section: weakSelf.numberOfSections - 1
            )
            weakSelf.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
}
