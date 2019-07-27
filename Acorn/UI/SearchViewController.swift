//
//  SearchViewController.swift
//  Acorn
//
//  Created by macOS on 3/9/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit
import InstantSearch

class SearchViewController: HitsTableViewController {

    @IBOutlet weak var tableView: HitsTableWidget!
    @IBOutlet weak var searchBar: SearchBarWidget!
    
    var nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
    var cardBackgroundColor: UIColor?
    var textColor: UIColor?
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    let dataSource = DataSource.instance
    
    override func viewDidLoad() {
        super.viewDidLoad()

        hitsTableView = tableView
        
        InstantSearch.shared.registerAllWidgets(in: self.view)
        
        searchBar.becomeFirstResponder()
        
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
        self.tableView.reloadData()
    }
    
    @objc func nightModeDisabled() {
        disableNightMode()
        self.tableView.reloadData()
    }
    
    func enableNightMode() {
        nightModeOn = true
        self.view.backgroundColor = ResourcesNight.COLOR_BG
        self.tableView.backgroundColor = ResourcesNight.COLOR_BG
        
        cardBackgroundColor = ResourcesNight.CARD_BG_COLOR
        textColor = ResourcesNight.COLOR_DEFAULT_TEXT
    }
    
    func disableNightMode() {
        nightModeOn = false
        self.view.backgroundColor = ResourcesDay.COLOR_BG
        self.tableView.backgroundColor = ResourcesDay.COLOR_BG
        
        cardBackgroundColor = ResourcesDay.CARD_BG_COLOR
        textColor = ResourcesDay.COLOR_DEFAULT_TEXT
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, containing hit: [String: Any]) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "hitCell", for: indexPath) as! SearchHitsTvCell
        
        cell.hit = hit
        cell.backgroundColor = cardBackgroundColor
        cell.cellView.backgroundColor = cardBackgroundColor
        cell.defaultTextColor = textColor
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath, containing hit: [String : Any]) {
        let article = Article(json: hit)
        
        dataSource.recordOpenArticleDetails(articleId: article.objectID, mainTheme: article.mainTheme ?? "General")
        if article.link != nil && article.link != "" {
            openArticle(article: article)
        } else {
            openComments(article: article)
        }
    }
    
    func openArticle(article: Article) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "WebView") as? WebViewViewController
        vc?.articleId = article.objectID
        vc?.searchVC = self
        present(vc!, animated: true, completion: nil)
    }
    
    func openComments(article: Article) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "Comment") as? CommentViewController
        vc?.articleId = article.objectID
        present(vc!, animated:true, completion: nil)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.endEditing(true)
    }

}
