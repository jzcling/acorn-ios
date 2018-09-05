//
//  PreviewImageViewController.swift
//  Acorn
//
//  Created by macOS on 24/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit
import FirebaseUI

class PreviewImageViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    var image: UIImage?
    @IBOutlet weak var inputBarView: UIStackView!
    
    let dataSource = DataSource.instance
    
    var article: Article?
    
    lazy var user = Auth.auth().currentUser!
    
    var commentVC: CommentViewController?
    var createPostVC: CreatePostViewController?
    
    lazy var inputBarYPosition = inputBarView.frame.origin.y
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.image = image
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @IBAction func didTapSendButton(_ sender: Any) {
        checkEmailVerified(user: user)
        
        if let vc = createPostVC {
            vc.clearAttachments()
            
            if inputTextView.text.isEmpty {
                DispatchQueue.main.async {
                    vc.cardView.isHidden = true
                    vc.postImageGroupView.isHidden = false
                
//                    vc.postTextViewHeightConstraint.constant = vc.scrollViewHeight - vc.postImageView.frame.height
                    vc.postImageView.image = self.image
                }
            } else {
                DispatchQueue.main.async {
                    vc.postImageGroupView.isHidden = true
                    vc.cardView.isHidden = false
                    
                    vc.cardTitleLabel.text = self.inputTextView.text
                    vc.cardSourceLabel.text = nil
                    vc.cardImageView.image = self.image
                }
            }
            dismiss(animated: true, completion: nil)
        } else if let _ = commentVC {
            let imageData = UIImageJPEGRepresentation(imageView.image!, 0.3)
            dataSource.sendComment(article: article!, commentText: inputTextView.text, commentImageData: imageData, onComplete: { self.dismiss(animated: true, completion: nil) }) { (error) in
                self.view.makeToast("An error occurred while posting")
                print(error)
            }
        }
    }
    
    @IBAction func didTapCloseButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func adjustLayoutForKeyboardShow(_ show: Bool, notification: Notification) {
        let userInfo = notification.userInfo ?? [:]
        let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let adjustmentHeight = keyboardFrame.height * (show ? 1 : -1)
        
        if show {
            inputBarView.frame.origin.y = self.inputBarYPosition - adjustmentHeight
        } else {
            inputBarView.frame.origin.y = self.inputBarYPosition
        }
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

}
