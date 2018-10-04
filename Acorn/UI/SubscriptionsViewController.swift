//
//  SubscriptionsViewController.swift
//  Acorn
//
//  Created by macOS on 10/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit
import MaterialComponents

class SubscriptionsViewController: MDCCollectionViewController, SubscriptionsHeaderViewDelegate, SubscriptionsFooterViewDelegate {

    let defaults = UserDefaults.standard
    lazy var themeKey = defaults.string(forKey: "themeKey")
    let themeList = ResourcesDay.THEME_LIST
    lazy var themeObjects = [Theme]()
    lazy var nightModeOn = defaults.bool(forKey: "nightModePref")
    lazy var colorList = nightModeOn ? ResourcesNight.COLOR_LIST : ResourcesDay.COLOR_LIST
    
    var allThemesCheckbox: Checkbox?
    var areAllThemesSelected = false
    
    var isFirstTimeLogin = false
    
    var textColor: UIColor?
    var cellBackgroundColor: UIColor?
    var mainBackgroundColor: UIColor?
    
    var vc: FeedViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.styler.cellStyle = .card
        self.styler.cellLayoutType = .grid
        self.styler.gridColumnCount = 2
        
        for theme in themeList {
            if (themeKey != nil && themeKey?.range(of: theme) != nil) {
                themeObjects.append(Theme(name: theme, isSelected: true))
            } else {
                themeObjects.append(Theme(name: theme, isSelected: false))
            }
        }
        
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
        self.collectionView?.reloadData()
    }
    
    @objc func nightModeDisabled() {
        disableNightMode()
        self.collectionView?.reloadData()
    }
    
    func enableNightMode() {
        nightModeOn = true
        self.collectionView?.backgroundColor = ResourcesNight.COLOR_BG
        self.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        self.cellBackgroundColor = ResourcesNight.CARD_BG_COLOR
        self.mainBackgroundColor = ResourcesNight.COLOR_BG
    }
    
    func disableNightMode() {
        nightModeOn = false
        self.collectionView?.backgroundColor = ResourcesDay.COLOR_BG
        self.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        self.cellBackgroundColor = ResourcesDay.CARD_BG_COLOR
        self.mainBackgroundColor = ResourcesDay.COLOR_BG
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        var themeSelectionCount = 0
        for theme in themeObjects {
            if theme.isSelected {
                themeSelectionCount += 1
            }
        }
        if themeSelectionCount == themeList.count {
            areAllThemesSelected = true
        } else {
            areAllThemesSelected = false
        }
        allThemesCheckbox?.isChecked = areAllThemesSelected
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return themeList.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SubscriptionCvCell", for: indexPath) as! SubscriptionCvCell
        
        let theme = themeList[indexPath.row]
        cell.themeLabel.text = theme
        cell.checkbox.tintColor = colorList[indexPath.row]
        cell.checkbox.uncheckedBorderColor = colorList[indexPath.row]
        cell.checkbox.checkedBorderColor = colorList[indexPath.row]
        cell.checkbox.checkmarkColor = colorList[indexPath.row]
        
        cell.object = self.themeObjects[indexPath.row]
        
        cell.themeLabel.textColor = textColor
        cell.backgroundColor = cellBackgroundColor
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? SubscriptionCvCell {
            let bool = !cell.checkbox.isChecked
            themeObjects[indexPath.row] = Theme(name: themeList[indexPath.row], isSelected: bool)
            DispatchQueue.main.async {
                collectionView.reloadItems(at: [indexPath])
                self.collectionViewLayout.invalidateLayout()
            }
            
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! SubscriptionsHeaderView
            headerView.delegate = self
            headerView.allThemesButton.backgroundColor = cellBackgroundColor
            headerView.allThemesLabel.textColor = textColor
            
            self.allThemesCheckbox = headerView.allThemesCheckbox
            self.allThemesCheckbox?.isChecked = areAllThemesSelected
            
            return headerView
            
        } else {
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Footer", for: indexPath) as! SubscriptionsFooterView
            footerView.delegate = self
            footerView.backgroundColor = mainBackgroundColor
            return footerView
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 147)
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 50)
    }
    
    func allThemesButtonTapped() {
        
        if let isChecked = allThemesCheckbox?.isChecked {
            for theme in themeObjects {
                theme.isSelected = !isChecked
            }
            allThemesCheckbox?.isChecked = !isChecked
            collectionView?.reloadData()
        }
    }
    
    func saveThemes() {
        var themePrefs = [String]()
        for theme in themeObjects {
            if theme.isSelected {
                themePrefs.append(theme.name)
            }
        }
        
        if themePrefs.count < 1 {
            let message = MDCSnackbarMessage()
            message.text = "Please select at least one theme"
            MDCSnackbarManager.show(message)
            return
        }
        
        themePrefs = themePrefs.sorted()
        var tempThemeKey = themePrefs[0]
        var tempThemeFilters = "mainTheme: \"\(themePrefs[0])\""
        for theme in themePrefs[1 ..< themePrefs.endIndex] {
            tempThemeKey += "_\(theme)"
            tempThemeFilters += " OR mainTheme: \"\(theme)\""
        }
        self.themeKey = tempThemeKey
        let themeFilters = tempThemeFilters
        self.defaults.set(themeFilters, forKey: "themeFilters")
        self.defaults.set(self.themeKey, forKey: "themeKey")
        
        DataSource.instance.setThemeSubscriptions(themePrefs)
        
        let message = MDCSnackbarMessage()
        message.text = "Theme subscriptions saved"
        MDCSnackbarManager.show(message)
        
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        vc!.subscriptionsDidChange = true
        
        if isFirstTimeLogin {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func close() {
        dismiss(animated: true, completion: nil)
    }

}
