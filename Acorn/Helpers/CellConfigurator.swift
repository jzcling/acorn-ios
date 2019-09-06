//
//  CellConfigurator.swift
//  Acorn
//
//  Created by Jeremy Ling on 2/9/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import Foundation
import SDWebImage
import InstantSearchCore
import Firebase

struct ArticleCellViewState {
    
    func configure(_ cell: SearchHitsTvCell) -> (Article, UISearchBar) -> () {
        return { article, searchBar in
            
            let nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
            let upvoteTint = nightModeOn ? ResourcesNight.UPVOTE_TINT_COLOR : ResourcesDay.UPVOTE_TINT_COLOR
            let downvoteTint = nightModeOn ? ResourcesNight.DOWNVOTE_TINT_COLOR : ResourcesDay.DOWNVOTE_TINT_COLOR
            let cardTextColor = nightModeOn ? ResourcesNight.CARD_TEXT_COLOR : ResourcesDay.CARD_TEXT_COLOR
            
            var imageUrl: String?
            var ref: StorageReference?
            if let url = article.imageUrl {
                imageUrl = url
            }
            if imageUrl == nil || imageUrl == "" {
                if let url = article.postImageUrl {
                    if url.starts(with: "gs://") {
                        ref = Storage.storage().reference(forURL: url)
                        cell.mainImageView.sd_setImage(with: ref!)
                    } else {
                        imageUrl = url
                    }
                }
            }
            if imageUrl != nil && imageUrl != "" {
                cell.mainImageView.sd_setImage(with: URL(string: imageUrl!))
            } else {
                if ref == nil {
                    cell.mainImageView.isHidden = true
                }
            }
//            cell.titleLabel.text = article.title
//            cell.sourceLabel.text = article.source
            cell.titleLabel.attributedText = getHighlightedString(article.title, searchBar.text)
            cell.sourceLabel.attributedText = getHighlightedString(article.source, searchBar.text)
            cell.dateLabel.text = DateUtils.parsePrettyDate(unixTimestamp: -article.pubDate)
            
            let voteCnt = article.voteCount ?? 0
            cell.voteCntLabel.text = String(voteCnt)
            if voteCnt < 0 {
                cell.voteCntImageView.tintColor = downvoteTint
                cell.voteCntImageView.image = #imageLiteral(resourceName: "ic_arrow_down_18")
            } else {
                cell.voteCntImageView.tintColor = upvoteTint
                cell.voteCntImageView.image = #imageLiteral(resourceName: "ic_arrow_up_18")
            }
            
            let commCnt = article.commentCount ?? 0
            cell.commCntLabel.text = String(commCnt)
            
            cell.titleLabel.textColor = cardTextColor
            cell.sourceLabel.textColor = cardTextColor
            cell.dateLabel.textColor = cardTextColor
            cell.voteCntLabel.textColor = cardTextColor
            cell.commCntLabel.textColor = cardTextColor
            cell.sourceDateSeparator.textColor = cardTextColor
            cell.voteCommSeparator.textColor = cardTextColor
        }
    }
    
}

struct ArticleHitCellViewState {
    
    func configure(_ cell: SearchHitsTvCell) -> (Hit<Article>, UISearchBar) -> () {
        return { articleHit, searchBar in
            let article = articleHit.object
            let nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
            let searchHitTextColor = nightModeOn ? ResourcesNight.SEARCH_HIT_TEXT_COLOR : ResourcesDay.SEARCH_HIT_TEXT_COLOR
            let upvoteTint = nightModeOn ? ResourcesNight.UPVOTE_TINT_COLOR : ResourcesDay.UPVOTE_TINT_COLOR
            let downvoteTint = nightModeOn ? ResourcesNight.DOWNVOTE_TINT_COLOR : ResourcesDay.DOWNVOTE_TINT_COLOR
            let cardTextColor = nightModeOn ? ResourcesNight.CARD_TEXT_COLOR : ResourcesDay.CARD_TEXT_COLOR
            
            var imageUrl: String?
            var ref: StorageReference?
            if let url = article.imageUrl {
                imageUrl = url
            }
            if imageUrl == nil || imageUrl == "" {
                if let url = article.postImageUrl {
                    if url.starts(with: "gs://") {
                        ref = Storage.storage().reference(forURL: url)
                        cell.mainImageView.sd_setImage(with: ref!)
                    } else {
                        imageUrl = url
                    }
                }
            }
            if imageUrl != nil && imageUrl != "" {
                cell.mainImageView.sd_setImage(with: URL(string: imageUrl!))
            } else {
                if ref == nil {
                    cell.mainImageView.isHidden = true
                }
            }
            
            cell.titleLabel.text = article.title
            cell.sourceLabel.text = article.source
            
//            if let title = articleHit.highlightResult?["title"] {
//                cell.titleLabel.attributedText = NSAttributedString(highlightedResults: title, separator: NSAttributedString(string: ", "), attributes: [.foregroundColor: searchHitTextColor])
//            }
//            if let source = articleHit.highlightResult?["source"] {
//                cell.sourceLabel.attributedText = NSAttributedString(highlightedResults: source, separator: NSAttributedString(string: ", "), attributes: [.foregroundColor: searchHitTextColor])
//            }
            cell.dateLabel.text = DateUtils.parsePrettyDate(unixTimestamp: -article.pubDate)
            
            let voteCnt = article.voteCount ?? 0
            cell.voteCntLabel.text = String(voteCnt)
            if voteCnt < 0 {
                cell.voteCntImageView.tintColor = downvoteTint
                cell.voteCntImageView.image = #imageLiteral(resourceName: "ic_arrow_down_18")
            } else {
                cell.voteCntImageView.tintColor = upvoteTint
                cell.voteCntImageView.image = #imageLiteral(resourceName: "ic_arrow_up_18")
            }
            
            let commCnt = article.commentCount ?? 0
            cell.commCntLabel.text = String(commCnt)
            
            cell.titleLabel.textColor = cardTextColor
            cell.sourceLabel.textColor = cardTextColor
            cell.dateLabel.textColor = cardTextColor
            cell.voteCntLabel.textColor = cardTextColor
            cell.commCntLabel.textColor = cardTextColor
            cell.sourceDateSeparator.textColor = cardTextColor
            cell.voteCommSeparator.textColor = cardTextColor
        }
    }
}

private func getHighlightedString(_ text: String?, _ query: String?) -> NSAttributedString? {
    let nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
    let searchHitTextColor = nightModeOn ? ResourcesNight.SEARCH_HIT_TEXT_COLOR : ResourcesDay.SEARCH_HIT_TEXT_COLOR
    let searchBGTextColor = nightModeOn ? ResourcesNight.SEARCH_HIT_BG_COLOR : ResourcesDay.SEARCH_HIT_BG_COLOR
    
    var rangesToHighlight = [Range<String.Index>]()
    
    if let query = query, let text = text, query.count > 0 {
        var tailRange = text.startIndex..<text.endIndex
        while let match = text.range(of: query, options: [.caseInsensitive], range: tailRange) {
            tailRange = match.upperBound..<text.endIndex
            rangesToHighlight.append(match)
        }
        
        let highlightAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: searchHitTextColor,
            .backgroundColor: searchBGTextColor
        ]
        let highlighted = NSMutableAttributedString(string: text)
        for range in rangesToHighlight {
            highlighted.addAttributes(highlightAttributes, range: NSRange(range, in: text))
        }
        
        return highlighted
    } else {
        return NSAttributedString(string: text!)
    }
}
