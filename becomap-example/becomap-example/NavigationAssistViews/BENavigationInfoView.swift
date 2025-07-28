//
//  BENavigationInfoView.swift
//  BeCoMapTest
//
//  Created by test on 25/11/19.
//  Copyright © 2019 GlobeCo Technologies Pvt Ltd. All rights reserved.
//

import UIKit
import becomap_ios

protocol BENavigationInfoViewDelegate: NSObjectProtocol {
    func navInfoView(_ navInfoView: BENavigationInfoView, didRequestedForEditWith points: [BCLocation])
    func didCancelednavigation(for navInfoView: BENavigationInfoView)
}

class BENavigationInfoView: UIView {
    weak var delegate: BENavigationInfoViewDelegate?
    var points: [BCLocation] = [] {
        didSet {
            guard points.count >= 2 else {
                startPointName.text = ""
                betweenStops.text = ""
                endPointName.text = ""
                return
            }
            startPointName.text = points[0].name
            endPointName.text = points[points.count - 1].name
            let betweenStopCount = points.count - 2
            betweenStops.text = "\(betweenStopCount) \(betweenStopCount > 1 ? "Stops" : "Stop")"
            if betweenStopCount > 0 {
                mainViewHightConstraint.constant = 113
                midViewHeightConstraint.constant = 26
                middleView.isHidden = false
            } else {
                mainViewHightConstraint.constant = 86
                midViewHeightConstraint.constant = 0
                middleView.isHidden = true
            }
        }
    }

    @IBOutlet var contentView: UIView!
    @IBOutlet var mainViewHightConstraint: NSLayoutConstraint!

    @IBOutlet var startPointLbl: UILabel!
    @IBOutlet var currentLocationImg: UIImageView!
    @IBOutlet var startPointName: UILabel!
    @IBOutlet var endPointName: UILabel!

    @IBOutlet var middleView: UIView!
    @IBOutlet var betweenStops: UILabel!
    @IBOutlet var midViewHeightConstraint: NSLayoutConstraint!

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
        Bundle.main.loadNibNamed("BENavigationInfoView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }

    // MARK: - Access Methods

    func setRouteWith(routePoints: [BCLocation]) {
        points = routePoints
    }

    func showView() {
        show()
    }

    func hideView() {
        hide()
        points.removeAll()
    }

    // MARK: - Actions

    @IBAction func backButtonTapped(_: Any) {
        delegate?.didCancelednavigation(for: self)
    }

    @IBAction func editTapped(_: Any) {
        delegate?.navInfoView(self, didRequestedForEditWith: points)
    }
}
