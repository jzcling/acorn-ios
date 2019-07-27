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
    @IBOutlet weak var inputBarView: UIView!
    
    let dataSource = DataSource.instance
    
    var articleId: String?
    
    lazy var user = Auth.auth().currentUser!
    
    var commentVC: CommentViewController?
    var createPostVC: CreatePostViewController?
    
    lazy var inputBarYPosition = inputBarView.frame.origin.y
    
    let nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.image = image
        
        let backSwipeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(didSwipeBack(_:)))
        backSwipeGesture.edges = .left
        backSwipeGesture.delegate = self
        self.view.addGestureRecognizer(backSwipeGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @IBAction func didTapSendButton(_ sender: Any) {
        if !isUserEmailVerified() {
            showEmailVerificationAlert(user: user)
            return
        }
        
        if let vc = createPostVC {
            vc.clearAttachments()
            
            if inputTextView.text.isEmpty {
                DispatchQueue.main.async {
                    vc.cardView.isHidden = true
                
                    vc.postImageGroupView.isHidden = false
                
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
            
            let imageData = imageView.image!.jpegData(compressionQuality: 0.3)
            dataSource.sendComment(articleId: articleId!, commentText: inputTextView.text, commentImageData: imageData, onComplete: { (userStatus) in
                if let userStatus = userStatus {
                    self.view.makeToast("Congratulations! You have grown into a \(userStatus)")
                }
                self.dismiss(animated: true, completion: nil)
                
            }) { (error) in
                self.view.makeToast("An error occurred while posting")
                
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
        let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
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

extension PreviewImageViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if nightModeOn {
            textView.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        } else {
            textView.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        }
        if textView.text == "Write something..." {
            textView.text = nil
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if nightModeOn {
            textView.textColor = ResourcesNight.COLOR_DEFAULT_TEXT
        } else {
            textView.textColor = ResourcesDay.COLOR_DEFAULT_TEXT
        }
        if textView.text.isEmpty {
            textView.text = "Write something..."
        }
    }
}

extension PreviewImageViewController: UIGestureRecognizerDelegate {
    @objc func didSwipeBack(_ sender: UIScreenEdgePanGestureRecognizer) {
        let dX = sender.translation(in: self.view).x
        if sender.state == .ended {
            let fraction = abs(dX/self.view.bounds.width)
            if fraction > 0.3 {
                dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
