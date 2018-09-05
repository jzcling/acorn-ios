//
//  CreatePostViewController.swift
//  Acorn
//
//  Created by macOS on 27/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit
import FirebaseUI
import Firebase
import DropDown
import ImagePicker
import Lightbox
import SDWebImage
import Toast_Swift
import SwiftSoup

protocol CreatePostDelegate: class {
    func postCreated()
}

class CreatePostViewController: UIViewController {
    
    weak var delegate: CreatePostDelegate?
    
    var spinner: UIView?
    
    @IBOutlet weak var themeSelectionMenu: UIStackView!
    @IBOutlet weak var themeSelectionLabel: UILabel!
    @IBOutlet weak var postTextView: UITextView!
    @IBOutlet weak var postImageGroupView: UIView!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var cardImageView: UIImageView!
    @IBOutlet weak var cardTitleLabel: UILabel!
    @IBOutlet weak var cardSourceLabel: UILabel!
    @IBOutlet weak var toolbar: UIToolbar!
    
    @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
    
    var getArticleMetadataIsPending = false
    var cardLink: String?
    var cardTitle: String?
    var cardImageUrl: String?
    var cardSource: String?
    
    @IBOutlet weak var postStackView: UIStackView!
    @IBOutlet weak var cardViewHeightConstraint: NSLayoutConstraint!
    
    lazy var postStackViewWidth = postStackView.frame.width
    var adjustmentHeight: CGFloat?
    var cardViewHeight: CGFloat?
    
    lazy var user = Auth.auth().currentUser!
    lazy var uid = user.uid
    lazy var userDisplayName = user.displayName
    var token: String?
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    let dataSource = DataSource.instance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print(error)
            } else if let result = result {
                self.token = result.token
            }
        }
        
        cardView.layer.cornerRadius = 6
        cardView.layer.masksToBounds = true
        cardView.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        cardView.layer.shadowRadius = 4
        cardView.layer.shadowOpacity = 1.0
        cardView.layer.shadowColor = UIColor.gray.cgColor
        cardView.layer.masksToBounds = false
        
        postImageGroupView.isHidden = true
        cardView.isHidden = true
        
        themeSelectionLabel.layer.borderWidth = 0.3
        themeSelectionLabel.layer.borderColor = UIColor.lightGray.cgColor
        
        postTextView.delegate = self
        postTextView.text = "Write something..."
        postTextView.textColor = .lightGray
        themeSelectionMenu.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openThemeDropdown)))
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapCloseButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapRemoveAttachmentButton(_ sender: Any) {
        print("removeAttachmentButton: Tapped")
        clearAttachments()
    }
    
    func clearAttachments() {
        DispatchQueue.main.async {
            self.postImageGroupView.isHidden = true
            self.cardView.isHidden = true
        }
        
        self.postImageView.image = nil
        self.cardLink = nil
        self.cardTitle = nil
        self.cardSource = nil
        self.cardImageUrl = nil
    }
    
    
    @IBAction func didTapPostButton(_ sender: Any) {
        checkEmailVerified(user: user)
        
        if (postTextView.text.count < 1 || postTextView.text == "Write something...") {
            self.view.makeToast("Please write something before posting", duration: 2.0, position: .bottom)
            return
        }
        
        if themeSelectionLabel.text == "  Please select" {
            self.view.makeToast("Please select a theme", duration: 2.0, position: .bottom)
            return
        }
        
        spinner = displaySpinner()
        
        let postDate = -floor(Double(Date().timeIntervalSince1970 * 1000))
        let objectID = "\(String(format: "%.0f", 5000000000000000 + postDate))_-1"
        let postText = postTextView.text
        let mainTheme = themeSelectionLabel.text?.trimmingCharacters(in: .whitespaces)
        print("postDate: \(postDate), objectID: \(objectID)")
        
        let postAsDict: [String: Any?] = [
            "entityId": -1,
            "objectID": objectID,
            "type": "post",
            "postAuthorUid": uid,
            "postAuthor": userDisplayName ?? "",
            "postText": postText ?? "",
            "postImageUrl": nil,
            "postDate": postDate,
            "title": self.cardTitle,
            "source": self.cardSource,
            "pubDate": postDate,
            "imageUrl": self.cardImageUrl,
            "link": self.cardLink,
            "trendingIndex": "500000_\(objectID)",
            "category": [mainTheme ?? ""],
            "theme": [mainTheme ?? ""],
            "mainTheme": mainTheme ?? "",
            "notificationTokens": [uid: token],
            "changedSinceLastJob": true
        ]
        
        if let image = postImageView.image {
            let compressedImageData = UIImageJPEGRepresentation(image, 0.3)
            
            dataSource.createPost(post: postAsDict, postImageData: compressedImageData, onComplete: {
                self.delegate?.postCreated()
            }) { (error) in
                print(error)
                if let spinner = self.spinner {
                    self.removeSpinner(spinner)
                }
                DispatchQueue.main.async {
                    self.view.makeToast("Post creation failed")
                }
            }
        } else {
            dataSource.createPost(post: postAsDict, postImageData: nil, onComplete: {
                    self.delegate?.postCreated()
            }) { (error) in
                print(error)
                if let spinner = self.spinner {
                    self.removeSpinner(spinner)
                }
                DispatchQueue.main.async {
                    self.view.makeToast("Post creation failed")
                }
            }
        }
    }
    
    @objc private func openThemeDropdown() {
        let dropdown = DropDown()
        dropdown.anchorView = themeSelectionMenu
        dropdown.dataSource = Resources.THEME_LIST
        dropdown.width = themeSelectionMenu.frame.width
        dropdown.direction = .bottom
        dropdown.backgroundColor = Resources.CREATE_POST_BG_COLOR
        dropdown.textColor = .black
        dropdown.bottomOffset = CGPoint(x: 0, y: (dropdown.anchorView?.plainView.bounds.height)!)
        dropdown.selectionAction = { (index: Int, item: String) in
            self.themeSelectionLabel.text = "  \(Resources.THEME_LIST[index])"
        }
        dropdown.show()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func adjustLayoutForKeyboardShow(_ show: Bool, notification: Notification) {
        let userInfo = notification.userInfo ?? [:]
        let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        self.adjustmentHeight = keyboardFrame.height * (show ? 1 : -1)
        
        if show {
            toolbarBottomConstraint.constant = -self.adjustmentHeight!
        } else {
            toolbarBottomConstraint.constant = 0
        }
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        adjustLayoutForKeyboardShow(true, notification: notification)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        adjustLayoutForKeyboardShow(false, notification: notification)
    }

    @IBAction func hideKeyboard(_ sender: AnyObject) {
        postTextView.endEditing(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        if let spinner = spinner {
            removeSpinner(spinner)
        }
    }
}

extension CreatePostViewController: ImagePickerDelegate {
    
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
        vc?.image = images[0]
        vc?.createPostVC = self
        imagePicker.dismiss(animated: false, completion: nil)
        present(vc!, animated: true, completion: nil)
    }
    
}

extension CreatePostViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Write something.."
            textView.textColor = .lightGray
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if !cardView.isHidden || !postImageGroupView.isHidden { return }
        
        let getArticleMetadataTask = DispatchWorkItem {
            let urlPattern = try? NSRegularExpression(pattern: "((?:https?://|www\\.)[a-z0-9+&@#/%=˜_|$?!:,.-]*\\b)", options: .caseInsensitive)
            if let firstMatch = urlPattern?.firstMatch(in: textView.text, options: [], range: NSMakeRange(0, textView.text.count)) {
                self.cardLink = (textView.text as NSString).substring(with: firstMatch.range)
                
                guard let link = self.cardLink else {
                    self.getArticleMetadataIsPending = false
                    return
                }
                
                if !link.starts(with: "https://") {
                    self.cardLink = "https://\(link)"
                }
                
                guard let url = URL(string: self.cardLink!) else {
                    self.getArticleMetadataIsPending = false
                    return
                }
                
                do {
                    print("url: \(url)")
                    let htmlString = try String(contentsOf: url, encoding: String.Encoding.utf8)
                    print(htmlString)
                    let parsedHtml = try SwiftSoup.parse(htmlString)
                    
                    self.cardTitle = try parsedHtml.title()
                    
                    let sourceElements = try parsedHtml.select("meta[property=og:site_name]")
                    self.cardSource = sourceElements.size() > 0 ? try sourceElements.first()!.attr("content") : nil
                    
                    let imageElements = try parsedHtml.select("meta[property=og:image]")
                    self.cardImageUrl = imageElements.size() > 0 ? try imageElements.first()!.attr("content") : nil
                    
                    self.cardTitleLabel.text = self.cardTitle
                    self.cardSourceLabel.text = self.cardSource
                    if let imageUrl = self.cardImageUrl {
                        self.cardImageView.sd_setImage(with: URL(string: imageUrl))
                    }
                    
                    let tempTitleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.postStackViewWidth - 142, height: CGFloat.greatestFiniteMagnitude))
                    tempTitleLabel.numberOfLines = 0
                    tempTitleLabel.lineBreakMode = .byWordWrapping
                    tempTitleLabel.font = UIFont.systemFont(ofSize: 16.0)
                    tempTitleLabel.text = self.cardTitle
                    tempTitleLabel.sizeToFit()
                    let titleHeight = tempTitleLabel.frame.height
                    
                    self.cardViewHeight = max(110, 44 + titleHeight)
                    self.cardViewHeightConstraint.constant = self.cardViewHeight!
                    self.cardView.isHidden = false
                    
                    self.getArticleMetadataIsPending = false
                    
                } catch Exception.Error(_, let message) {
                    self.getArticleMetadataIsPending = false
                    print(message)
                } catch let error {
                    self.getArticleMetadataIsPending = false
                    print(error)
                }
            }
        }
        
        if self.getArticleMetadataIsPending {
            getArticleMetadataTask.cancel()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: getArticleMetadataTask)
        self.getArticleMetadataIsPending = true
    }
}
