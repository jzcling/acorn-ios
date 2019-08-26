//
//  NativeAdCvCell.swift
//  Acorn
//
//  Created by Jeremy Ling on 19/8/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import MaterialComponents
import SDWebImage
import FirebaseUI
import Firebase

class NativeAdCvCell: UICollectionViewCell {
    
    @IBOutlet weak var topSeparatorLabel: UILabel!
    @IBOutlet weak var headlineView: UILabel!
    @IBOutlet weak var bodyView: UILabel!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var callToActionView: UIButton!
    @IBOutlet weak var advertiserView: UILabel!
    @IBOutlet weak var mediaView: GADMediaView!
    
    var textColor: UIColor?
    var textColorFaint: UIColor?
    
    lazy var user = Auth.auth().currentUser!
    lazy var uid = user.uid
    
    let dataSource = DataSource.instance
    
    let nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
    lazy var ctaDefaultTint = nightModeOn ? ResourcesNight.CTA_DEFAULT_TINT_COLOR : ResourcesDay.CTA_DEFAULT_TINT_COLOR
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let inkTouchController = MDCInkTouchController(view: self)
        inkTouchController.addInkView()
        
        self.layer.cornerRadius = 10
        
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        setNeedsLayout()
        layoutIfNeeded()
        
        let size = contentView.systemLayoutSizeFitting(layoutAttributes.size)
        
        var frame = layoutAttributes.frame
        frame.size.height = ceil(size.height)
        layoutAttributes.frame = frame
        
        return layoutAttributes
    }
    
    func populateContent(ad: GADUnifiedNativeAd) {
        
        let adView = contentView.subviews.first as! GADUnifiedNativeAdView
        adView.nativeAd = ad
        
        if let title = ad.headline, let body = ad.body {
            if title.count > body.count {
                (adView.headlineView as! UILabel).text = body
                (adView.bodyView as! UILabel).text = title
            } else {
                (adView.headlineView as! UILabel).text = title
                (adView.bodyView as! UILabel).text = body
            }
        }
        if let iconUrl = ad.icon?.imageURL {
            (adView.iconView as! UIImageView).sd_setImage(with: iconUrl)
        } else {
            (adView.iconView as! UIImageView).isHidden = true
        }
        (adView.advertiserView as! UILabel).text = ad.advertiser
        (adView.callToActionView as! UIButton).setTitle(ad.callToAction, for: UIControl.State.normal)
        adView.mediaView?.mediaContent = ad.mediaContent
        
        topSeparatorLabel.textColor = textColorFaint
        headlineView.textColor = textColorFaint
        bodyView.textColor = textColor
        advertiserView.textColor = textColor
        callToActionView.backgroundColor = ctaDefaultTint
        callToActionView.setTitleColor(textColor, for: UIControl.State.normal)
    }
}
