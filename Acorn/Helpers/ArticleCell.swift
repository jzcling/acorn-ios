//
//  ArticleCell.swift
//  Acorn
//
//  Created by Jeremy Ling on 2/9/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import Foundation
import UIKit

protocol ArticleCell {
    var cellView: UIView { get }
    var titleLabel: UILabel { get }
    var sourceLabel: UILabel { get }
    var sourceDateSeparator: UILabel { get }
    var dateLabel: UILabel { get }
    var voteCntImageView: UIImageView { get }
    var voteCntLabel: UILabel { get }
    var voteCommSeparator: UILabel { get }
    var commCntImageView: UIImageView { get }
    var commCntLabel: UILabel { get }
    var mainImageView: UIImageView { get }
}
