//
//  ArticleListTvCellDelegate.swift
//  Acorn
//
//  Created by macOS on 11/10/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import Foundation

protocol ArticleListTvCellDelegate: class {
    func openArticle(_ articleId: String)
    func openComments(_ articleId: String)
}
