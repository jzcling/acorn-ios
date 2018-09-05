//
//  BounceButton.swift
//  Acorn
//
//  Created by macOS on 31/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import UIKit

class BounceButton: UIButton {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 6, options: .allowUserInteraction, animations: { self.transform = CGAffineTransform.identity }, completion: nil)
        
        super.touchesBegan(touches, with: event)
    }
}
