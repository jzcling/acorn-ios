//
//  SearchHitsTvCell.swift
//  Acorn
//
//  Created by macOS on 3/9/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit
import InstantSearch
import SDWebImage
import Firebase

class SearchHitsTvCell: UITableViewCell, ArticleCell {
    
    let cellView: UIView
    let titleLabel: UILabel
    let sourceLabel: UILabel
    let sourceDateSeparator: UILabel
    let dateLabel: UILabel
    let voteCntImageView: UIImageView
    let voteCntLabel: UILabel
    let voteCommSeparator: UILabel
    let commCntImageView: UIImageView
    let commCntLabel: UILabel
    let mainImageView: UIImageView
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        cellView = .init(frame: .zero)
        titleLabel = .init(frame: .zero)
        sourceLabel = .init(frame: .zero)
        sourceDateSeparator = .init(frame: .zero)
        dateLabel = .init(frame: .zero)
        voteCntImageView = .init(frame: .zero)
        voteCntLabel = .init(frame: .zero)
        voteCommSeparator = .init(frame: .zero)
        commCntImageView = .init(frame: .zero)
        commCntLabel = .init(frame: .zero)
        mainImageView = .init(frame: .zero)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        layout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
    lazy var searchHitTextColor = nightModeOn ? ResourcesNight.SEARCH_HIT_TEXT_COLOR : ResourcesDay.SEARCH_HIT_TEXT_COLOR
    lazy var upvoteTint = nightModeOn ? ResourcesNight.UPVOTE_TINT_COLOR : ResourcesDay.UPVOTE_TINT_COLOR
    lazy var commentTint = nightModeOn ? ResourcesNight.COMMENT_TINT_COLOR : ResourcesDay.COMMENT_TINT_COLOR
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.lightGray.cgColor
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = nil
        sourceLabel.text = nil
        dateLabel.text = nil
        voteCntImageView.image = #imageLiteral(resourceName: "ic_arrow_up_18")
        voteCntImageView.tintColor = upvoteTint
        voteCntLabel.text = nil
        commCntLabel.text = nil
        mainImageView.isHidden = false
        mainImageView.sd_cancelCurrentImageLoad()
    }

    private func layout() {
        contentView.backgroundColor = nil
        
        cellView.translatesAutoresizingMaskIntoConstraints = false
        cellView.backgroundColor = nil
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 17, weight: .regular)
        titleLabel.numberOfLines = 0
        
        sourceLabel.translatesAutoresizingMaskIntoConstraints = false
        sourceLabel.font = .systemFont(ofSize: 13, weight: .regular)
        sourceLabel.numberOfLines = 1
        
        sourceDateSeparator.translatesAutoresizingMaskIntoConstraints = false
        sourceDateSeparator.font = .systemFont(ofSize: 13, weight: .regular)
        sourceDateSeparator.text = " • "
        sourceDateSeparator.numberOfLines = 1
        
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .systemFont(ofSize: 13, weight: .regular)
        dateLabel.numberOfLines = 1
        
        let sourceDateStackView = UIStackView()
        sourceDateStackView.axis = .horizontal
        sourceDateStackView.translatesAutoresizingMaskIntoConstraints = false
        sourceDateStackView.spacing = 5
        
        sourceDateStackView.addArrangedSubview(sourceLabel)
        sourceDateStackView.addArrangedSubview(sourceDateSeparator)
        sourceDateStackView.addArrangedSubview(dateLabel)
        
        voteCntImageView.clipsToBounds = true
        voteCntImageView.translatesAutoresizingMaskIntoConstraints = false
        voteCntImageView.contentMode = .scaleAspectFill
        voteCntImageView.layer.masksToBounds = true
        voteCntImageView.image = #imageLiteral(resourceName: "ic_arrow_up_18")
        voteCntImageView.tintColor = upvoteTint
        
        voteCntLabel.translatesAutoresizingMaskIntoConstraints = false
        voteCntLabel.font = .systemFont(ofSize: 13, weight: .regular)
        voteCntLabel.numberOfLines = 1
        
        voteCommSeparator.translatesAutoresizingMaskIntoConstraints = false
        voteCommSeparator.font = .systemFont(ofSize: 13, weight: .regular)
        voteCommSeparator.text = " • "
        voteCommSeparator.numberOfLines = 1
        
        commCntImageView.clipsToBounds = true
        commCntImageView.translatesAutoresizingMaskIntoConstraints = false
        commCntImageView.contentMode = .scaleAspectFill
        commCntImageView.layer.masksToBounds = true
        commCntImageView.image = #imageLiteral(resourceName: "ic_comment_18")
        commCntImageView.tintColor = commentTint
        
        commCntLabel.translatesAutoresizingMaskIntoConstraints = false
        commCntLabel.font = .systemFont(ofSize: 13, weight: .regular)
        commCntLabel.numberOfLines = 1
        
        let voteCommStackView = UIStackView()
        voteCommStackView.axis = .horizontal
        voteCommStackView.translatesAutoresizingMaskIntoConstraints = false
        voteCommStackView.spacing = 5
        
        voteCommStackView.addArrangedSubview(voteCntImageView)
        voteCommStackView.addArrangedSubview(voteCntLabel)
        voteCommStackView.addArrangedSubview(voteCommSeparator)
        voteCommStackView.addArrangedSubview(commCntImageView)
        voteCommStackView.addArrangedSubview(commCntLabel)
        
        cellView.addSubview(titleLabel)
        cellView.addSubview(sourceDateStackView)
        cellView.addSubview(voteCommStackView)
        
        mainImageView.clipsToBounds = true
        mainImageView.translatesAutoresizingMaskIntoConstraints = false
        mainImageView.contentMode = .scaleAspectFill
        mainImageView.layer.masksToBounds = true
        mainImageView.layer.cornerRadius = 10
        
        contentView.addSubview(cellView)
        contentView.addSubview(mainImageView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: cellView.topAnchor, constant: 10),
            titleLabel.bottomAnchor.constraint(equalTo: sourceDateStackView.topAnchor, constant: -8),
            titleLabel.leftAnchor.constraint(equalTo: cellView.leftAnchor, constant: 12),
            titleLabel.rightAnchor.constraint(equalTo: cellView.rightAnchor, constant: -12),
            sourceDateStackView.bottomAnchor.constraint(equalTo: voteCommStackView.topAnchor, constant: -8),
            sourceDateStackView.leftAnchor.constraint(equalTo: cellView.leftAnchor, constant: 12),
            voteCommStackView.bottomAnchor.constraint(equalTo: cellView.bottomAnchor, constant: -10),
            voteCommStackView.leftAnchor.constraint(equalTo: cellView.leftAnchor, constant: 12),
            cellView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            cellView.rightAnchor.constraint(equalTo: mainImageView.leftAnchor),
            cellView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cellView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            mainImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -12),
            mainImageView.heightAnchor.constraint(equalToConstant: 90),
            mainImageView.widthAnchor.constraint(equalToConstant: 90),
            mainImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
}
