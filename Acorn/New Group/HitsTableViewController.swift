//
//  HitsTableViewController.swift
//  development-pods-instantsearch
//
//  Created by Vladislav Fitc on 13/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//
import Foundation
import UIKit
import InstantSearchCore

class HitsTableViewController<HitType: Codable>: UITableViewController, InstantSearchCore.HitsController {
    
    typealias DataSource = HitsInteractor<HitType>
    
    let cellIdentifier = "hitCell"
    
    var hitsSource: HitsInteractor<HitType>?
    
    var searchBar: UISearchBar
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    let dataSource = NetworkDataSource.instance
    
    var cardBackgroundColor: UIColor?
    
    init(searchBar: UISearchBar) {
        self.searchBar = searchBar
        super.init(nibName: .none, bundle: .none)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reload() {
        tableView.reloadData()
    }
    
    func scrollToTop() {
        tableView.scrollToFirstNonEmptySection()
    }
    
    //MARK: - UITableViewNetworkDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hitsSource?.numberOfHits() ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! SearchHitsTvCell
        if let hit = hitsSource?.hit(atIndex: indexPath.row) as? Article {
            ArticleCellViewState().configure(cell)(hit, searchBar)
        }
        
        cell.backgroundColor = cardBackgroundColor
        
        return cell
    }
    
    //MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let hit = hitsSource?.hit(atIndex: indexPath.row)
        
        let cellWidth = tableView.bounds.width
        let baseHeight: CGFloat = 71
        var titleHeight: CGFloat = 0
        
        let tempTitleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: cellWidth - 36 - 90, height: CGFloat.greatestFiniteMagnitude))
        tempTitleLabel.numberOfLines = 0
        tempTitleLabel.lineBreakMode = .byWordWrapping
        tempTitleLabel.font = UIFont.systemFont(ofSize: 17.0)
        
        switch hit {
        case let article as Article:
            tempTitleLabel.text = article.title
            tempTitleLabel.sizeToFit()
            titleHeight = tempTitleLabel.frame.height
        case let articleHit as Hit<Article>:
            let article = articleHit.object
            tempTitleLabel.text = article.title
            tempTitleLabel.sizeToFit()
            titleHeight = tempTitleLabel.frame.height
        default:
            break
        }
        
        let cellHeight = max(110, baseHeight + titleHeight)
        
        return cellHeight
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let hit = hitsSource?.hit(atIndex: indexPath.row)
        
        switch hit {
        case let article as Article:
            dataSource.recordOpenArticleDetails(articleId: article.objectID, mainTheme: article.mainTheme ?? "General")
            if article.link != nil && article.link != "" {
                openArticle(article: article)
            } else {
                openComments(article: article)
            }
        case let articleHit as Hit<Article>:
            let article = articleHit.object
            dataSource.recordOpenArticleDetails(articleId: article.objectID, mainTheme: article.mainTheme ?? "General")
            if article.link != nil && article.link != "" {
                openArticle(article: article)
            } else {
                openComments(article: article)
            }
        default: break
        }
        
    }
    
    func openArticle(article: Article) {
        self.dataSource.getAlgoliaApiKey() { key in
            let vc = self.mainStoryboard.instantiateViewController(withIdentifier: "WebView") as? WebViewViewController
            let searchVC = SearchViewController(algoliaApiKey: key)
            vc?.articleId = article.objectID
            vc?.searchVC = searchVC
            self.present(vc!, animated: true, completion: nil)
        }
    }
    
    func openComments(article: Article) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "Comment") as? CommentViewController
        vc?.articleId = article.objectID
        present(vc!, animated:true, completion: nil)
    }
    
}
