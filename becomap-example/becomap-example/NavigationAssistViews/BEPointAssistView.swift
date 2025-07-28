//
//  BEPointAssistView.swift
//  MapAssistView
//
//  Created by test on 18/11/19.
//  Copyright © 2019 GlobeCo Technologies Pvt Ltd. All rights reserved.
//

import UIKit
import becomap_ios

protocol BEPointAssistDelegate: NSObjectProtocol {
    func pointAssist(_ pointAssist: BEPointAssistView, didRequestedForDirectionTo point: BCLocation)
    func pointAssistDidCancel(_ pointAssist: BEPointAssistView)
}

class BEPointAssistView: UIView {
    var point: BCLocation? = nil {
        didSet {
            pointNameLabel.text = point?.name
            floorNameLabel.text = point?.floor?.name
        }
    }

    weak var delegate: BEPointAssistDelegate?

    @IBOutlet var contentView: UIView!
    @IBOutlet var pointNameLabel: UILabel!
    @IBOutlet var floorNameLabel: UILabel!

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        didLoadView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        didLoadView()
    }

    private func didLoadView() {
        Bundle.main.loadNibNamed("BEPointAssistView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }

    func setPoint(point: BCLocation) {
        self.point = point
    }

    func showView() {
        show()
    }

    func hideView() {
        hide()
        point = nil
    }

    @IBAction func directionsTapped(_: Any) {
        if let aPoint = point {
            delegate?.pointAssist(self, didRequestedForDirectionTo: aPoint)
        }
    }

    @IBAction func cancelTapped(_: Any) {
        delegate?.pointAssistDidCancel(self)
    }
}
