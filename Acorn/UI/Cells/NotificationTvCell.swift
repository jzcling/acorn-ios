//
//  NotificationTvCell.swift
//  Acorn
//
//  Created by macOS on 25/9/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit
import SDWebImage
import FirebaseStorage

class NotificationTvCell: UITableViewCell {

    @IBOutlet weak var headerTextLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var sourceExtraSeparator: UILabel!
    @IBOutlet weak var extraLabel: UILabel!
    @IBOutlet weak var notificationImageView: UIImageView!
    
    var notification: String?
    
    let nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
    lazy var defaultTextColor = nightModeOn ? ResourcesNight.COLOR_DEFAULT_TEXT : ResourcesDay.COLOR_DEFAULT_TEXT
    lazy var cardBackgroundColor = nightModeOn ? ResourcesNight.CARD_BG_COLOR : ResourcesDay.CARD_BG_COLOR
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setColors()
        
        notificationImageView.layer.cornerRadius = notificationImageView.frame.height/2
        
        titleLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 104
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setColors() {
        self.contentView.backgroundColor = cardBackgroundColor
        headerTextLabel.textColor = defaultTextColor
        titleLabel.textColor = defaultTextColor
        sourceLabel.textColor = defaultTextColor
        sourceExtraSeparator.textColor = defaultTextColor
        extraLabel.textColor = defaultTextColor
    }

    func populateCell() {
        let content = notification!.components(separatedBy: "|•|")
        let type = content[0]
        let articleId = content[1]
        let headerText = content[2]
        let title = content[3]
        let source = content[4]
        let imageUrl = content[5]
        let theme = content[6]
        let extra = content[7]
        let timestamp = content[8]
        let link = content[9]
        
        headerTextLabel.text = headerText
        titleLabel.text = title
        sourceLabel.text = source
        if (type == "article" || type == "deal") {
            extraLabel.text = DateUtils.parsePrettyDate(unixTimestamp: -Double(extra)!)
        } else if type == "comment" {
            extraLabel.text = extra
        }
        if imageUrl == "" {
            notificationImageView.isHidden = true
        } else {
            notificationImageView.isHidden = false
            if imageUrl.starts(with: "gs://") {
                let ref = Storage.storage().reference(forURL: imageUrl)
                self.notificationImageView.sd_setImage(with: ref)
            } else {
                self.notificationImageView.sd_setImage(with: URL(string: imageUrl))
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        headerTextLabel.text = ""
        titleLabel.text = ""
        sourceLabel.text = ""
        extraLabel.text = ""
        notificationImageView.sd_cancelCurrentImageLoad()
        notificationImageView.isHidden = false
    }
}
