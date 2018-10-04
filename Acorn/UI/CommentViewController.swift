//
//  CommentViewController.swift
//  Acorn
//
//  Created by macOS on 17/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit
import MaterialComponents
import ImagePicker
import Lightbox
import FirebaseUI
import Firebase
import DropDown
import Toast_Swift
import SwiftSoup

class CommentViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var inputBarViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var chevronButton: UIBarButtonItem!
    @IBOutlet weak var searchButton: UIBarButtonItem!
    @IBOutlet weak var moreOptionsButton: UIBarButtonItem!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var inputBarView: UIView!
    @IBOutlet weak var inputAddButton: UIButton!
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var inputSendButton: UIButton!
    
    @IBOutlet weak var articleStackView: UIStackView!
    @IBOutlet weak var articleLeftView: UIView!
    @IBOutlet weak var articleRightView: UIView!
    @IBOutlet weak var articleTitleLabel: UILabel!
    @IBOutlet weak var articleSourceLabel: UILabel!
    @IBOutlet weak var articleSourceDateSeparator: UILabel!
    @IBOutlet weak var articleDateLabel: UILabel!
    @IBOutlet weak var articleVoteCntImageView: UIImageView!
    @IBOutlet weak var articleVoteCntLabel: UILabel!
    @IBOutlet weak var articleVoteCommSeparator: UILabel!
    @IBOutlet weak var articleCommCntImageView: UIImageView!
    @IBOutlet weak var articleCommCntLabel: UILabel!
    @IBOutlet weak var articleImageView: UIImageView!
    
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var cardImageView: UIImageView!
    @IBOutlet weak var cardTitleLabel: UILabel!
    @IBOutlet weak var cardSourceLabel: UILabel!
    @IBOutlet weak var cardViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var cardViewBottomConstraint: NSLayoutConstraint!
    
    let dataSource = DataSource.instance
    var articleId: String?
    var article: Article?
    var comments = [Comment]() {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    lazy var user = Auth.auth().currentUser!
    lazy var uid = user.uid
    lazy var userDisplayName = user.displayName
    
    var isFollowedByUser: Bool = false
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    var nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
    
    var adjustmentHeight: CGFloat?
    
    var inputTextHasLink = false
    var getArticleMetadataIsPending = false
    var urlLink: String?
    var urlTitle: String?
    var urlImageUrl: String?
    var urlSource: String?
    
    var isNewSearch = true
    var searchResultIndexArray = [Int]()
    var searchIndex = 0
    
    override func awakeFromNib() {
        let _ = self.view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        searchBar.delegate = self
        inputTextView.delegate = self
        
        searchBar.isHidden = true
        articleStackView.isHidden = true
        cardView.isHidden = true
        
        if nightModeOn {
            enableNightMode()
        } else {
            disableNightMode()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(nightModeEnabled), name: .nightModeOn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeDisabled), name: .nightModeOff, object: nil)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeUp.direction = .up
        articleStackView.addGestureRecognizer(swipeUp)
    }
    
    @objc func nightModeEnabled() {
        enableNightMode()
        self.collectionView.reloadData()
    }
    
    @objc func nightModeDisabled() {
        disableNightMode()
        self.collectionView.reloadData()
    }
    
    func enableNightMode() {
        nightModeOn = true
        self.collectionView.backgroundColor = ResourcesNight.COLOR_BG
        self.view.backgroundColor = ResourcesNight.CARD_BG_COLOR
        
        inputBarView.backgroundColor = ResourcesNight.CARD_BG_COLOR
        inputTextView.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        inputAddButton.tintColor = .lightGray
        inputSendButton.tintColor = .lightGray
        
        articleLeftView.backgroundColor = ResourcesNight.CARD_BG_COLOR
        articleRightView.backgroundColor = ResourcesNight.CARD_BG_COLOR
        articleTitleLabel.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        articleSourceLabel.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        articleSourceDateSeparator.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        articleDateLabel.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        articleVoteCntLabel.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        articleVoteCommSeparator.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        articleCommCntLabel.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        
        cardTitleLabel.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        cardSourceLabel.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        cardView.backgroundColor = ResourcesNight.CARD_BG_COLOR
    }
    
    func disableNightMode() {
        nightModeOn = false
        self.collectionView.backgroundColor = ResourcesDay.COLOR_BG
        self.view.backgroundColor = ResourcesDay.CARD_BG_COLOR
        
        inputBarView.backgroundColor = ResourcesDay.CARD_BG_COLOR
        inputTextView.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        inputAddButton.tintColor = .darkGray
        inputSendButton.tintColor = .darkGray
        
        articleLeftView.backgroundColor = ResourcesDay.CARD_BG_COLOR
        articleRightView.backgroundColor = ResourcesDay.CARD_BG_COLOR
        articleTitleLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        articleSourceLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        articleSourceDateSeparator.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        articleDateLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        articleVoteCntLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        articleVoteCommSeparator.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        articleCommCntLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        
        cardTitleLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        cardSourceLabel.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        cardView.backgroundColor = ResourcesDay.CARD_BG_COLOR
    }
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) {
        if gesture.direction == UISwipeGestureRecognizerDirection.up {
            UIView.animate(withDuration: 0.3, animations: {
                self.articleStackView.isHidden = true
            }, completion: { (bool) in
                self.chevronButton.image = #imageLiteral(resourceName: "ic_chevron_down")
            })
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = CGSize(width: collectionView.frame.width, height: 1)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.invalidateLayout()
        }
        
        loadComments()
        
        populateArticleCard() { article in
            self.articleStackView.isHidden = false
            
            self.article = article
            
            if let tokens = article.notificationTokens {
                self.isFollowedByUser = tokens.keys.contains(self.uid)
            } else {
                self.isFollowedByUser = false
            }
        }
    }
    
    func loadComments() {
        dataSource.getArticleComments(articleId!) { (comments) in
            self.comments = comments
            self.collectionView.reloadData()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                if self.comments.count > 0 {
                    self.collectionView.scrollToItem(at: NSIndexPath(item: self.comments.count - 1, section: 0) as IndexPath, at: .bottom, animated: false)
                }
            })
        }
    }
    
    func populateArticleCard(onComplete: @escaping (Article) -> ()) {
        guard let articleId = self.articleId else { return }
        
        dataSource.observeSingleArticle(articleId: articleId) { (retrievedArticle) in
            if (retrievedArticle.link != nil && retrievedArticle.link != "") {
                    self.articleTitleLabel.text = retrievedArticle.title
                    self.articleSourceLabel.text = retrievedArticle.source
                
                if (retrievedArticle.imageUrl != nil && retrievedArticle.imageUrl != "") {
                    self.articleImageView.sd_setImage(with: URL(string: retrievedArticle.imageUrl!))
                } else {
                    self.articleRightView.isHidden = true
                }
            } else {
                self.articleTitleLabel.text = retrievedArticle.postText
                self.articleSourceLabel.text = retrievedArticle.postAuthor
                
                if (retrievedArticle.postImageUrl != nil && retrievedArticle.postImageUrl != "") {
                    if retrievedArticle.postImageUrl!.starts(with: "gs://") {
                        let ref = Storage.storage().reference(forURL: retrievedArticle.postImageUrl!)
                        self.articleImageView.sd_setImage(with: ref)
                    } else {
                    self.articleImageView.sd_setImage(with: URL(string: retrievedArticle.postImageUrl!))
                    }
                } else {
                    self.articleRightView.isHidden = true
                }
            }
            
            self.articleDateLabel.text = DateUtils.parsePrettyDate(unixTimestamp: -retrievedArticle.pubDate)
            
            let voteCnt = retrievedArticle.voteCount ?? 0
            let commCnt = retrievedArticle.commentCount ?? 0
            
            if voteCnt < 0 {
                self.articleVoteCntImageView.image = #imageLiteral(resourceName: "ic_arrow_down")
                self.articleVoteCntImageView.tintColor = self.nightModeOn ? ResourcesNight.DOWNVOTE_TINT_COLOR : ResourcesDay.DOWNVOTE_TINT_COLOR
            } else {
                self.articleVoteCntImageView.image = #imageLiteral(resourceName: "ic_arrow_up")
                self.articleVoteCntImageView.tintColor = self.nightModeOn ? ResourcesNight.UPVOTE_TINT_COLOR : ResourcesDay.UPVOTE_TINT_COLOR
            }
            self.articleVoteCntLabel.text = String(voteCnt)
            
            self.articleCommCntImageView.tintColor = self.nightModeOn ? ResourcesNight.COMMENT_TINT_COLOR : ResourcesDay.COMMENT_TINT_COLOR
            self.articleCommCntLabel.text = String(commCnt)
            
            onComplete(retrievedArticle)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let comment = comments[indexPath.row]
        let textColor = nightModeOn ? ResourcesNight.COLOR_DEFAULT_TEXT : ResourcesDay.COLOR_DEFAULT_TEXT
        
        let isReported = comment.isReported ?? false
        if isReported {
            var identifier: String
            if comment.uid == uid {
                identifier = "CommentTextSelf"
            } else {
                identifier = "CommentText"
            }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! CommentTextCvCell
            cell.comment = comment
            cell.textColor = textColor
            cell.delegate = self
            
            cell.textWidthConstraint.constant = collectionView.frame.width * 0.75 - 2 * 8.0
            
            cell.populateReportedCell(comment)
            
            return cell
        } else {
            if comment.isUrl {
                var identifier: String
                if comment.uid == uid {
                    identifier = "CommentUrlSelf"
                } else {
                    identifier = "CommentUrl"
                }
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! CommentUrlCvCell
                cell.comment = comment
                cell.textColor = textColor
                cell.delegate = self
                
                cell.titleWidthConstraint.constant = collectionView.frame.width * 0.75 - 2 * 16.0 - 88.0
                cell.sourceWidthConstraint.constant = collectionView.frame.width * 0.75 - 2 * 16.0 - 88.0
                
                cell.populateCell(comment)
                
                return cell
            } else {
                if (comment.imageUrl == nil || comment.imageUrl == "") {
                    var identifier: String
                    if comment.uid == uid {
                        identifier = "CommentTextSelf"
                    } else {
                        identifier = "CommentText"
                    }
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! CommentTextCvCell
                    cell.comment = comment
                    cell.textColor = textColor
                    cell.delegate = self
                    
                    cell.textWidthConstraint.constant = collectionView.frame.width * 0.75 - 2 * 8.0
                    
                    cell.populateCell(comment)
                    
                    return cell
                } else if (comment.commentText == nil || comment.commentText == "") {
                    var identifier: String
                    if comment.uid == uid {
                        identifier = "CommentImageSelf"
                    } else {
                        identifier = "CommentImage"
                    }
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! CommentImageCvCell
                    cell.comment = comment
                    cell.textColor = textColor
                    cell.vc = self
                    cell.delegate = self
                    
                    cell.imageWidthConstraint.constant = collectionView.frame.width * 0.75 - 2 * 8.0
                    
                    cell.populateCell(comment)
                    
                    return cell
                } else {
                    var identifier: String
                    if comment.uid == uid {
                        identifier = "CommentImageTextSelf"
                    } else {
                        identifier = "CommentImageText"
                    }
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! CommentImageTextCvCell
                    cell.comment = comment
                    cell.textColor = textColor
                    cell.vc = self
                    cell.delegate = self
                    
                    cell.imageWidthConstraint.constant = collectionView.frame.width * 0.75 - 2 * 8.0
                    cell.textWidthConstraint.constant = collectionView.frame.width * 0.75 - 2 * 8.0
                    
                    cell.populateCell(comment)
                    
                    return cell
                }
            }
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return comments.count
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataSource.removeCommentObservers(articleId!)
        dataSource.removeArticleObserver(articleId!)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func didTapBackButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapChevronButton(_ sender: Any) {
        let currentOffset = collectionView.contentOffset.y
        UIView.animate(withDuration: 0.3, animations: {
            self.articleStackView.isHidden = !self.articleStackView.isHidden
        }, completion: { (bool) in
            if self.articleStackView.isHidden {
                self.chevronButton.image = #imageLiteral(resourceName: "ic_chevron_down")
            } else {
                self.chevronButton.image = #imageLiteral(resourceName: "ic_chevron_up")
            }
            self.collectionView.contentOffset = CGPoint(x: self.collectionView.contentOffset.x, y:  currentOffset)
        })
    }
    
    @IBAction func didTapSearchButton(_ sender: Any) {
        let currentOffset = collectionView.contentOffset.y
        UIView.animate(withDuration: 0.3, animations: {
            self.searchBar.isHidden = !self.searchBar.isHidden
        }, completion: { (bool) in
            if self.searchBar.isHidden {
                self.searchBar.resignFirstResponder()
            } else {
                self.searchBar.becomeFirstResponder()
            }
            self.collectionView.contentOffset = CGPoint(x: self.collectionView.contentOffset.x, y:  currentOffset)
        })
    }
    
    @IBAction func didTapMoreOptionsButton(_ sender: Any) {
        let dropdown = DropDown()
        dropdown.anchorView = moreOptionsButton
        
        if isFollowedByUser {
            dropdown.dataSource = ["Unfollow article"]
        } else {
            dropdown.dataSource = ["Follow article"]
        }
        
        dropdown.width = 200
        dropdown.direction = .bottom
        dropdown.backgroundColor = nightModeOn ? ResourcesNight.OPTIONS_BG_COLOR : ResourcesDay.OPTIONS_BG_COLOR
        dropdown.textColor = nightModeOn ? ResourcesNight.OPTIONS_TEXT_COLOR : ResourcesDay.OPTIONS_TEXT_COLOR
        dropdown.bottomOffset = CGPoint(x: 0, y: (dropdown.anchorView?.plainView.bounds.height)!)
        dropdown.selectionAction = { (index: Int, item: String) in
            if item == "Follow article" {
                self.dataSource.follow(articleId: self.articleId!)
                self.isFollowedByUser = true
            } else if item == "Unfollow article" {
                self.dataSource.unfollow(articleId: self.articleId!)
                self.isFollowedByUser = false
            }
        }
        dropdown.show()
    }
    
    @IBAction func didTapInputSendButton(_ sender: Any) {
        if !isUserEmailVerified(user: user) {
            showEmailVerificationAlert(user: user)
            return
        }
        
        if inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).count < 1 {
            self.view.makeToast("Please write something", duration: 2.0, position: .bottom)
            return
        }
        
        if inputTextView.text.count > 1000 {
            self.view.makeToast("Your comment should be less than 1000 characters", duration: 2.0, position: .bottom)
            return
        }
        
        dataSource.sendComment(articleId: articleId!, commentText: inputTextView.text, commentImageData: nil, onComplete: {
            if self.inputTextHasLink {
                self.dataSource.sendUrlComment(articleId: self.articleId!, urlLink: self.urlLink!, urlTitle: self.urlTitle!, urlImageUrl: self.urlImageUrl, urlSource: self.urlSource)
            }
            if !self.isFollowedByUser {
                self.dataSource.follow(articleId: self.articleId!)
            }
            self.clearCard()
            self.inputTextView.text = nil
        }, onError: { (error) in
            self.view.makeToast(error)
        })
    }
    
    func adjustLayoutForKeyboardShow(_ show: Bool, notification: Notification) {
        let userInfo = notification.userInfo ?? [:]
        let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        self.adjustmentHeight = keyboardFrame.height * (show ? 1 : -1)
        
        if show {
            inputBarViewBottomConstraint.constant = -self.adjustmentHeight!
        } else {
            inputBarViewBottomConstraint.constant = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            if self.comments.count > 0 {
                self.collectionView.scrollToItem(at: NSIndexPath(item: self.comments.count - 1, section: 0) as IndexPath, at: .bottom, animated: false)
            }
        })
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        adjustLayoutForKeyboardShow(true, notification: notification)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        adjustLayoutForKeyboardShow(false, notification: notification)
    }
    
    @IBAction func hideKeyboard(_ sender: AnyObject) {
        inputTextView.endEditing(true)
    }

    @IBAction func didTapCloseCardButton(_ sender: Any) {
        clearCard()
    }
    
    func clearCard() {
        self.inputTextHasLink = false
        self.urlLink = nil
        self.urlTitle = nil
        self.urlImageUrl = nil
        self.urlSource = nil
        cardView.isHidden = true
    }
}



// MARK: - ImagePickerDelegate

extension CommentViewController: ImagePickerDelegate {
    
    @IBAction func didTapInputAddButton(_ sender: Any) {
        
        var config = Configuration()
        config.recordLocation = false
        config.allowMultiplePhotoSelection = false
        config.showsImageCountLabel = false
        
        let imagePicker = ImagePickerController(configuration: config)
        imagePicker.delegate = self
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        guard images.count > 0 else { return }
        
        let lightboxImages = images.map {
            return LightboxImage(image: $0)
        }
        
        let lightbox = LightboxController(images: lightboxImages, startIndex: 0)
        lightbox.dynamicBackground = true
        imagePicker.present(lightbox, animated: true, completion: nil)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        guard images.count > 0 else { return }
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "PreviewImage") as? PreviewImageViewController
        vc?.articleId = articleId
        vc?.image = images[0]
        vc?.commentVC = self
        imagePicker.dismiss(animated: false, completion: nil)
        present(vc!, animated: true, completion: nil)
    }
    
}

extension CommentViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        if !cardView.isHidden { return }
        
        if self.getArticleMetadataIsPending {
            NSObject.cancelPreviousPerformRequests(withTarget: self)
        }
        
        perform(#selector(getArticleMetaData), with: nil, afterDelay: 0.5)
        self.getArticleMetadataIsPending = true
    }
    
    @objc func getArticleMetaData() {
        let urlPattern = try? NSRegularExpression(pattern: "((?:https?://|www\\.)[a-z0-9+&@#/%=˜_|$?!:,.-]*\\b)", options: .caseInsensitive)
        if let firstMatch = urlPattern?.firstMatch(in: self.inputTextView.text, options: [], range: NSMakeRange(0, self.inputTextView.text.count)) {
            self.urlLink = (self.inputTextView.text as NSString).substring(with: firstMatch.range)
            
            
            guard let link = self.urlLink else {
                self.getArticleMetadataIsPending = false
                return
            }
            
            if !link.starts(with: "https://") && !link.starts(with: "http://") {
                self.urlLink = "http://\(link)"
            }
            
            guard let url = URL(string: self.urlLink!) else {
                self.getArticleMetadataIsPending = false
                return
            }
            
            do {
                let htmlString = try String(contentsOf: url, encoding: String.Encoding.utf8)
                let parsedHtml = try SwiftSoup.parse(htmlString)
                
                self.urlTitle = try parsedHtml.title()
                
                let sourceElements = try parsedHtml.select("meta[property=og:site_name]")
                self.urlSource = sourceElements.size() > 0 ? try sourceElements.first()!.attr("content") : nil
                
                let imageElements = try parsedHtml.select("meta[property=og:image]")
                self.urlImageUrl = imageElements.size() > 0 ? try imageElements.first()!.attr("content") : nil
                
                self.cardTitleLabel.text = self.urlTitle
                self.cardSourceLabel.text = self.urlSource
                if let imageUrl = self.urlImageUrl {
                    self.cardImageView.sd_setImage(with: URL(string: imageUrl))
                }
                
                let tempTitleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 158, height: CGFloat.greatestFiniteMagnitude))
                tempTitleLabel.numberOfLines = 0
                tempTitleLabel.lineBreakMode = .byWordWrapping
                tempTitleLabel.font = UIFont.systemFont(ofSize: 16.0)
                tempTitleLabel.text = self.urlTitle
                tempTitleLabel.sizeToFit()
                let titleHeight = tempTitleLabel.frame.height
                
                let cardViewHeight = max(110, 44 + titleHeight)
                self.cardViewHeightConstraint.constant = cardViewHeight
                self.cardView.isHidden = false
                self.inputTextHasLink = true
                
                self.getArticleMetadataIsPending = false
                
            } catch Exception.Error(_, let message) {
                self.clearCard()
                self.getArticleMetadataIsPending = false
                
            } catch let error {
                self.clearCard()
                self.getArticleMetadataIsPending = false
                
            }
        }
    }
}

extension CommentViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        isNewSearch = true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        guard let searchText = searchBar.text else { return }
        
        
        if isNewSearch {
            isNewSearch = false
            searchIndex = 0
            searchResultIndexArray.removeAll()
            removeAllHighlights()
            
            for idx in 0 ..< comments.count {
                if let commentText = comments[idx].commentText {
                    if commentText.contains(searchText) {
                        
                        searchResultIndexArray.append(idx)
                        comments[idx].commentText = commentText.replacingOccurrences(of: searchText, with: "<em>\(searchText)</em>")
                    }
                }
            }
            searchResultIndexArray.reverse()
            
        } else if searchIndex < searchResultIndexArray.count {
            
            collectionView.scrollToItem(at: NSIndexPath(item: searchResultIndexArray[searchIndex], section: 0) as IndexPath, at: .centeredVertically, animated: false)
            searchIndex += 1
        } else {
            isNewSearch = true
            self.view.makeToast("No more results for \(searchText)")
        }
    }
    
    func removeAllHighlights() {
        for comment in comments {
            if let commentText = comment.commentText {
                if (commentText.contains("<em>") || commentText.contains("</em>")) {
                    comment.commentText = commentText.replacingOccurrences(of: "<em>", with: "")
                    comment.commentText = comment.commentText!.replacingOccurrences(of: "</em>", with: "")
                }
            }
        }
    }
}

extension CommentViewController: CommentCvCellDelegate {
    
    func openReportAlert(for comment: Comment) {
        let ac = UIAlertController(title: nil, message: "Report comment for inappropriate content?", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        ac.addAction(UIAlertAction(title: "Report", style: .destructive, handler: { _ in
            self.dataSource.reportComment(articleId: self.articleId!, comment: comment)
        }))
        self.present(ac, animated: true, completion: nil)
    }
}
