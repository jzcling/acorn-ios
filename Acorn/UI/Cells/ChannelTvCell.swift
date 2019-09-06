//
//  ChannelTvCell.swift
//  Acorn
//
//  Created by Jeremy Ling on 25/7/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import UIKit

protocol ChannelTvCellDelegate: class {
    func toggleChannelRemoval(for channel: String, _ bool: Bool)
}

class ChannelTvCell: UITableViewCell {
    var cellTextColor: UIColor?
    var channel: String?
    var delegate: ChannelTvCellDelegate?
    
    @IBOutlet weak var channelLabel: UILabel!
    @IBOutlet weak var channelSwitch: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        channelLabel.textColor = cellTextColor
    }
    
    func populateCell() {
        channelLabel.text = channel
        channelSwitch.isOn = true
    }
    
    @IBAction func toggleChannelRemoval(_ sender: UISwitch) {
        delegate?.toggleChannelRemoval(for: channel!,  sender.isOn)
    }
}
