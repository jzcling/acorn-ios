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
import FBAudienceNetwork

class NativeAdCvCell: UICollectionViewCell, FBNativeAdDelegate {
    
    @IBOutlet weak var nativeAdView: UIView!
    @IBOutlet weak var topSeparatorLabel: UILabel!
    @IBOutlet weak var headlineView: UILabel!
    @IBOutlet weak var bodyView: UILabel!
    @IBOutlet weak var iconView: FBMediaView!
    @IBOutlet weak var callToActionView: UIButton!
    @IBOutlet weak var advertiserView: UILabel!
    @IBOutlet weak var mediaView: FBMediaView!
    @IBOutlet weak var adChoicesView: FBAdChoicesView!
    
    var vc: FeedViewController?
    
    var textColor: UIColor?
    var textColorFaint: UIColor?
    
    let dataSource = NetworkDataSource.instance
    
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
    
    func populateContent(ad: FBNativeAd) {
        ad.unregisterView()
        ad.registerView(forInteraction: nativeAdView, mediaView: mediaView, iconView: iconView, viewController: vc)
        
        if let title = ad.headline, let body = ad.bodyText {
            if title.count > body.count {
                headlineView.text = body
                bodyView.text = title
            } else {
                headlineView.text = title
                bodyView.text = body
            }
        }
        advertiserView.text = ad.advertiserName
        if let cta = ad.callToAction { callToActionView.setTitle(cta, for: UIControl.State.normal)
            callToActionView.isHidden = false
        } else {
            callToActionView.isHidden = true
        }
        adChoicesView.nativeAd = ad
        
        topSeparatorLabel.textColor = textColorFaint
        headlineView.textColor = textColorFaint
        bodyView.textColor = textColor
        advertiserView.textColor = textColor
        callToActionView.backgroundColor = ctaDefaultTint
        callToActionView.setTitleColor(textColor, for: UIControl.State.normal)
    }
}
