//
//  BENavSearchCell.swift
//  MapAssistView
//
//  Created by test on 31/10/19.
//  Copyright © 2019 GlobeCo Technologies Pvt Ltd. All rights reserved.
//

import UIKit

protocol BECellelegate: NSObjectProtocol {
    func didSelectButton(index: Int, tag: Int)
}

class BENavSearchCell: UITableViewCell {
    weak var delegate: BECellelegate?
    var cellIndex = 0

    @IBOutlet var currentLocImage: UIImageView!
    @IBOutlet var pointIndexLabel: UILabel!
    @IBOutlet var pointNameLabel: UILabel!
    @IBOutlet var rightButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

    @IBAction func rightButtonTapped(_ sender: UIButton) {
        delegate?.didSelectButton(index: cellIndex, tag: sender.tag)
    }
}
