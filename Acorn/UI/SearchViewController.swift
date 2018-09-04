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
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        hitsTableView = tableView
        
        InstantSearch.shared.registerAllWidgets(in: self.view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, containing hit: [String: Any]) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "hitCell", for: indexPath) as! SearchHitsTvCell
        
        cell.hit = hit
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath, containing hit: [String : Any]) {
        let article = Article(json: hit)
        print("articleTitle: \(article.title ?? "")")
        if article.link != nil && article.link != "" {
            print("openArticle")
            openArticle(article: article)
        } else {
            print("openComments")
            openComments(article: article)
        }
    }
    
    func openArticle(article: Article) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "WebView") as? WebViewViewController
        vc?.article = article
        vc?.searchVC = self
        present(vc!, animated: true, completion: nil)
    }
    
    func openComments(article: Article) {
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "Comment") as? CommentViewController
        vc?.article = article
        present(vc!, animated:true, completion: nil)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.endEditing(true)
    }

}
