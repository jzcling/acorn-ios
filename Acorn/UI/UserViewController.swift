//
//  UserViewController.swift
//  Acorn
//
//  Created by macOS on 10/10/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit
import UICircularProgressRing
import FirebaseUI

class UserViewController: UIViewController {
    
    @IBOutlet var mainScrollView: UIScrollView!
    
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var basicUserDetailsView: UIView!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusPointsSeparator: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    
    @IBOutlet weak var upvoteBackgroundView: UIView!
    @IBOutlet weak var downvoteBackgroundView: UIView!
    @IBOutlet weak var commentBackgroundView: UIView!
    @IBOutlet weak var postBackgroundView: UIView!
    @IBOutlet weak var upvoteCountLabel: UILabel!
    @IBOutlet weak var downvoteCountLabel: UILabel!
    @IBOutlet weak var commentCountLabel: UILabel!
    @IBOutlet weak var postCountLabel: UILabel!
    @IBOutlet weak var upvoteTextLabel: UILabel!
    @IBOutlet weak var downvoteTextLabel: UILabel!
    @IBOutlet weak var commentTextLabel: UILabel!
    @IBOutlet weak var postTextLabel: UILabel!
    
    @IBOutlet weak var progressTitleLabel: UILabel!
    @IBOutlet weak var progressBackgroundView: UIView!
    @IBOutlet weak var circularProgressView: UICircularProgressRing!
    @IBOutlet weak var remainingPointsLabel: UILabel!
    @IBOutlet weak var remainingPointsTextLabel: UILabel!
    
    @IBOutlet weak var mostViewedThemesBackgroundView: UIView!
    @IBOutlet weak var mostViewedThemesLabel: UILabel!
    @IBOutlet weak var themeOneView: UIView!
    @IBOutlet weak var themeTwoView: UIView!
    @IBOutlet weak var themeThreeView: UIView!
    @IBOutlet weak var themeOneLabel: UILabel!
    @IBOutlet weak var themeTwoLabel: UILabel!
    @IBOutlet weak var themeThreeLabel: UILabel!
    
    let dataSource = NetworkDataSource.instance
    
    var user: AcornUser?
    
    let defaults = UserDefaults.standard
    lazy var nightModeOn = defaults.bool(forKey: "nightModePref")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        basicUserDetailsView.layer.cornerRadius = 15
        progressBackgroundView.layer.cornerRadius = 10
        mostViewedThemesBackgroundView.layer.cornerRadius = 10
        
        self.circularProgressView.maxValue = self.user!.targetPoints > 10 ? CGFloat(self.user!.targetPoints - self.user!.targetPoints / self.dataSource.TARGET_POINTS_MULTIPLIER) : CGFloat(self.user!.targetPoints)
        
        if nightModeOn {
            nightModeEnabled()
        } else {
            nightModeDisabled()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeEnabled), name: .nightModeOn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeDisabled), name: .nightModeOff, object: nil)
    }
    
    @objc func nightModeEnabled() {
        enableNightMode()
    }
    
    @objc func nightModeDisabled() {
        disableNightMode()
    }
    
    func enableNightMode() {
        nightModeOn = true
        self.mainScrollView.backgroundColor = ResourcesNight.USER_BG_COLOR
        
        self.basicUserDetailsView.backgroundColor = ResourcesNight.USER_SEC_BG_COLOR
        self.upvoteBackgroundView.backgroundColor = ResourcesNight.USER_SEC_BG_COLOR
        self.downvoteBackgroundView.backgroundColor = ResourcesNight.USER_SEC_BG_COLOR
        self.commentBackgroundView.backgroundColor = ResourcesNight.USER_SEC_BG_COLOR
        self.postBackgroundView.backgroundColor = ResourcesNight.USER_SEC_BG_COLOR
        
        self.displayNameLabel.textColor = ResourcesNight.USER_TEXT_COLOR
        self.statusLabel.textColor = ResourcesNight.USER_TEXT_COLOR
        self.statusPointsSeparator.textColor = ResourcesNight.USER_TEXT_COLOR
        self.pointsLabel.textColor = ResourcesNight.USER_TEXT_COLOR
        self.upvoteCountLabel.textColor = ResourcesNight.USER_TEXT_COLOR
        self.upvoteTextLabel.textColor = ResourcesNight.USER_TEXT_COLOR
        self.downvoteCountLabel.textColor = ResourcesNight.USER_TEXT_COLOR
        self.downvoteTextLabel.textColor = ResourcesNight.USER_TEXT_COLOR
        self.commentCountLabel.textColor = ResourcesNight.USER_TEXT_COLOR
        self.commentTextLabel.textColor = ResourcesNight.USER_TEXT_COLOR
        self.postCountLabel.textColor = ResourcesNight.USER_TEXT_COLOR
        self.postTextLabel.textColor = ResourcesNight.USER_TEXT_COLOR
        
        self.progressBackgroundView.backgroundColor = ResourcesNight.CARD_BG_COLOR
        self.circularProgressView.backgroundColor = ResourcesNight.CARD_BG_COLOR
        
        self.progressTitleLabel.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        self.remainingPointsLabel.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        self.remainingPointsTextLabel.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        
        self.mostViewedThemesBackgroundView.backgroundColor = ResourcesNight.CARD_BG_COLOR
        self.mostViewedThemesLabel.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        
    }
    
    func disableNightMode() {
        nightModeOn = false
        self.mainScrollView.backgroundColor = ResourcesDay.USER_BG_COLOR
        
        self.basicUserDetailsView.backgroundColor = ResourcesDay.USER_SEC_BG_COLOR
        self.upvoteBackgroundView.backgroundColor = ResourcesDay.USER_SEC_BG_COLOR
        self.downvoteBackgroundView.backgroundColor = ResourcesDay.USER_SEC_BG_COLOR
        self.commentBackgroundView.backgroundColor = ResourcesDay.USER_SEC_BG_COLOR
        self.postBackgroundView.backgroundColor = ResourcesDay.USER_SEC_BG_COLOR
        
        self.displayNameLabel.textColor = ResourcesDay.USER_TEXT_COLOR
        self.statusLabel.textColor = ResourcesDay.USER_TEXT_COLOR
        self.statusPointsSeparator.textColor = ResourcesDay.USER_TEXT_COLOR
        self.pointsLabel.textColor = ResourcesDay.USER_TEXT_COLOR
        self.upvoteCountLabel.textColor = ResourcesDay.USER_TEXT_COLOR
        self.upvoteTextLabel.textColor = ResourcesDay.USER_TEXT_COLOR
        self.downvoteCountLabel.textColor = ResourcesDay.USER_TEXT_COLOR
        self.downvoteTextLabel.textColor = ResourcesDay.USER_TEXT_COLOR
        self.commentCountLabel.textColor = ResourcesDay.USER_TEXT_COLOR
        self.commentTextLabel.textColor = ResourcesDay.USER_TEXT_COLOR
        self.postCountLabel.textColor = ResourcesDay.USER_TEXT_COLOR
        self.postTextLabel.textColor = ResourcesDay.USER_TEXT_COLOR
        
        self.progressBackgroundView.backgroundColor = ResourcesDay.CARD_BG_COLOR
        self.circularProgressView.backgroundColor = ResourcesDay.CARD_BG_COLOR
        
        self.progressTitleLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        self.remainingPointsLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        self.remainingPointsTextLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        
        self.mostViewedThemesBackgroundView.backgroundColor = ResourcesDay.CARD_BG_COLOR
        self.mostViewedThemesLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super .viewWillAppear(true)
        
        displayNameLabel.text = user!.displayName
        statusLabel.text = dataSource.getUserStatus(user!.status)
        pointsLabel.text = String(Int(user!.points)) + " pts"
        upvoteCountLabel.text = String(user!.upvotedItemsCount)
        downvoteCountLabel.text = String(user!.downvotedItemsCount)
        commentCountLabel.text = String(user!.commentedItemsCount)
        postCountLabel.text = String(user!.createdPostsCount)
        remainingPointsLabel.text = String(Int(user!.targetPoints - user!.points))
        
        if user!.status == 0 {
            statusImageView.image = UIImage(named: "user_acorn")
        } else if user!.status == 1 {
            statusImageView.image = UIImage(named: "user_sprout")
        } else if user!.status == 2 {
            statusImageView.image = UIImage(named: "user_sapling")
        } else if user!.status >= 3 {
            statusImageView.image = UIImage(named: "user_oak")
        }
        
        let progressValue = self.user!.targetPoints > 10 ? CGFloat(self.user!.points - self.user!.targetPoints / self.dataSource.TARGET_POINTS_MULTIPLIER) : CGFloat(self.user!.points)
        circularProgressView.startProgress(to: progressValue, duration: 1.0)
        
        let themes = Array(user!.openedThemes.keys)
        if themes.count == 0 {
            themeOneView.isHidden = true
            themeTwoView.isHidden = true
            themeThreeView.isHidden = true
        } else if themes.count == 1 {
            themeOneLabel.text = themes[0]
            themeOneView.layer.cornerRadius = themeOneView.frame.height / 2.0
            themeTwoView.isHidden = true
            themeThreeView.isHidden = true
        } else if themes.count == 2 {
            let rankedThemes = Array(user!.openedThemes.keys).sorted(by: { user!.openedThemes[$0]! > user!.openedThemes[$1]! })
            themeOneLabel.text = rankedThemes[0]
            themeOneView.layer.cornerRadius = themeOneView.frame.height / 2.0
            themeTwoLabel.text = rankedThemes[1]
            themeTwoView.layer.cornerRadius = themeTwoView.frame.height / 2.0
            themeThreeView.isHidden = true
        } else if themes.count > 2 {
            let rankedThemes = Array(user!.openedThemes.keys).sorted(by: { user!.openedThemes[$0]! > user!.openedThemes[$1]! })
            themeOneLabel.text = rankedThemes[0]
            themeOneView.layer.cornerRadius = themeOneView.frame.height / 2.0
            themeTwoLabel.text = rankedThemes[1]
            themeTwoView.layer.cornerRadius = themeTwoView.frame.height / 2.0
            themeThreeLabel.text = rankedThemes[2]
            themeThreeView.layer.cornerRadius = themeThreeView.frame.height / 2.0
        }
    }

    private func pinBackground(to stackView: UIStackView) {
        let view = UIView()
        view.backgroundColor = ResourcesDay.COLOR_PRIMARY
        view.translatesAutoresizingMaskIntoConstraints = false
        stackView.layoutIfNeeded()
        view.layer.cornerRadius = stackView.frame.height / 2.0
        view.widthAnchor.constraint(equalToConstant: stackView.frame.width)
        stackView.insertSubview(view, at: 0)
        view.pin(to: stackView)
    }
}

public extension UIView {
    func pin(to view: UIView) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
