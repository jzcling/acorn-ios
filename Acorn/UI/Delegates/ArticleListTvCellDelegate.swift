//
//  ArticleListTvCellDelegate.swift
//  Acorn
//
//  Created by macOS on 11/10/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import Foundation

@objc protocol ArticleListTvCellDelegate: class {
    @objc optional func openArticle(_ articleId: String)
    @objc optional func openArticle(_ articleId: String, _ postcode: [String])
    @objc optional func openComments(_ articleId: String)
}
