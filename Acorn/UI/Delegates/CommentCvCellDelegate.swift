//
//  CommentCvCellDelegate.swift
//  Acorn
//
//  Created by macOS on 3/10/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import Foundation

protocol CommentCvCellDelegate: class {
    func openReportAlert(for comment: Comment)
}
