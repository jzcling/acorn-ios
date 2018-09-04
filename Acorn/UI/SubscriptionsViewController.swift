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
    let themeList = Resources.THEME_LIST
    lazy var themeObjects = [Theme]()
    
    var isFirstTimeLogin = false
    
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
            print("themeObjects init: \(String(describing: themeObjects.last?.name)), \(String(describing: themeObjects.last?.isSelected))")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return themeList.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("cellForItemAt: \(indexPath.row)")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SubscriptionCvCell", for: indexPath) as! SubscriptionCvCell
        
        let theme = themeList[indexPath.row]
        cell.theme.text = theme
        cell.checkbox.tintColor = Resources.COLOR_LIST[indexPath.row]
        cell.checkbox.uncheckedBorderColor = Resources.COLOR_LIST[indexPath.row]
        cell.checkbox.checkedBorderColor = Resources.COLOR_LIST[indexPath.row]
        cell.checkbox.checkmarkColor = Resources.COLOR_LIST[indexPath.row]
        
        cell.object = self.themeObjects[indexPath.row]
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? SubscriptionCvCell {
            let bool = !cell.checkbox.isChecked
            themeObjects[indexPath.row] = Theme(name: themeList[indexPath.row], isSelected: bool)
            DispatchQueue.main.async {
                collectionView.reloadItems(at: [indexPath])
            }
            print("cell tapped: \(themeObjects[indexPath.row].name), \(themeObjects[indexPath.row].isSelected)")
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
            
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! SubscriptionsHeaderView
            headerView.delegate = self
            return headerView
            
        case UICollectionElementKindSectionFooter:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Footer", for: indexPath) as! SubscriptionsFooterView
            footerView.delegate = self
            return footerView
            
        default:
            assert(false, "Unexpected element kind")
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 147)
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 50)
    }
    
    func allThemesButtonTapped(checkbox: Checkbox) {
        print("allThemesButtonTapped")
        let isChecked = checkbox.isChecked
        for theme in themeObjects {
            theme.isSelected = !isChecked
        }
        checkbox.isChecked = !isChecked
        collectionView?.reloadData()
    }
    
    func saveThemes() {
        var themePrefs = [String]()
        for theme in themeObjects {
            if theme.isSelected {
                themePrefs.append(theme.name)
            }
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
        
        if isFirstTimeLogin {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func close() {
        print("close")
        dismiss(animated: true, completion: nil)
    }

}
