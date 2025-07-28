//
//  BESearchListView.swift
//  MapAssistView
//
//  Created by test on 29/10/19.
//  Copyright © 2019 GlobeCo Technologies Pvt Ltd. All rights reserved.
//

import UIKit
import becomap_ios

protocol BESearchListDelegate: NSObjectProtocol {
    func searchlist(_ searchlist: BESearchListView, didLoad pointList: [BCLocation])
    func searchlist(_ searchlist: BESearchListView, didSelected point: BCLocation)
}

class BESearchListView: UIView {
    weak var delegate: BESearchListDelegate?
    @IBOutlet var contentView: UIView!
    @IBOutlet var resultsTable: UITableView!

    var pointsList: [BCLocation] = []

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
        Bundle.main.loadNibNamed("BESearchListView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        let nib = UINib(nibName: "SearchTableViewCell", bundle: nil)
        resultsTable.register(nib, forCellReuseIdentifier: "SearchTableViewCell")
    }

    // MARK: - Access Methods

    func loadPointsList(points: [BCLocation]) {
        pointsList = points
        resultsTable.reloadData()
        delegate?.searchlist(self, didLoad: points)
    }

    func showView() {
        show()
    }

    func hideView() {
        hide()
        pointsList = []
        resultsTable.reloadData()
    }
}

extension BESearchListView: UITableViewDelegate, UITableViewDataSource {
    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        if pointsList.count > 0 {
            tableView.backgroundView = nil
            return 1
        } else {
            TableViewHelper.EmptyMessage(
                message: "No search results found.\n Please enter a valid point name to see your results.",
                tableView: tableView
            )
            return 0
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return pointsList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "SearchTableViewCell",
            for: indexPath
        ) as! SearchTableViewCell
        cell.selectionStyle = .none
        cell.pointNameLabel.text = pointsList[indexPath.row].name
        cell.floorNameLabel.text = pointsList[indexPath.row].floor?.name
        return cell
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.searchlist(self, didSelected: pointsList[indexPath.row])
    }
}

class TableViewHelper {
    // MARK: - UITableView Helper class

    class func EmptyMessage(message: String, tableView: UITableView) {
        let rect = CGRect(
            origin: CGPoint(x: 0, y: 0),
            size: CGSize(width: tableView.bounds.size.width, height: tableView.bounds.size.height)
        )
        let messageLabel = UILabel(frame: rect)
        messageLabel.text = message
        messageLabel.textColor = UIColor.lightGray
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont(name: "TrebuchetMS", size: 15)
        messageLabel.sizeToFit()
        tableView.backgroundView = messageLabel
        tableView.separatorStyle = .none
    }
}
