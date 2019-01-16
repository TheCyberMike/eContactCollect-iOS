//
//  HexKeyboard.swift
//  eContact Collect
//
//  Created by Yo on 10/30/18.
//

import UIKit

class HexKeyboardView: UIInputView {
    weak var delegate: UIKeyInput?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeSubviews()
    }
    
    override init(frame: CGRect, inputViewStyle: UIInputView.Style) {
        super.init(frame: frame, inputViewStyle: inputViewStyle)
        initializeSubviews()
    }
    
    func initializeSubviews() {
        let xibFileName = "HexKeyboard"
        let view = Bundle.main.loadNibNamed(xibFileName, owner: self, options: nil)![0] as! UIView
        self.addSubview(view)
        view.frame = self.bounds
    }
    
    @IBAction func button_backspace_pressed(_ sender: UIButton) {
        self.delegate?.deleteBackward()
    }
    @IBAction func button_char_pressed(_ sender: UIButton) {
        self.delegate?.insertText(sender.titleLabel!.text!)
    }
}

class HexKeyboardViewController: UIInputViewController, UIKeyInput {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadInterface()
    }
    
    func loadInterface() {
        let keyboardView = HexKeyboardView(frame: CGRect(x:0, y:0, width:414, height:169), inputViewStyle: .keyboard)
        keyboardView.delegate = self
        self.inputView = keyboardView
        self.view.autoresizingMask = UIView.AutoresizingMask.flexibleWidth
        self.view.translatesAutoresizingMaskIntoConstraints = true
    }
    
    public var hasText: Bool {
        get {
            return self.textDocumentProxy.hasText
        }
    }
    
    public func insertText(_ text: String) {
        let current = self.textDocumentProxy.documentContextBeforeInput
        if (current ?? "").isEmpty {
            self.textDocumentProxy.insertText(text)
        } else if current!.count == 1 {
            self.textDocumentProxy.insertText(text)
        } else {
            let last2Index = current!.index(current!.endIndex, offsetBy: -2)
            let last2Str = current![last2Index...]
            if !last2Str.contains(":")  {
                self.textDocumentProxy.insertText(":")
            }
            self.textDocumentProxy.insertText(text)
        }
    }
    
    public func deleteBackward() {
        self.textDocumentProxy.deleteBackward()
        let current = self.textDocumentProxy.documentContextBeforeInput
        if !((current ?? "").isEmpty) {
            if current!.last == ":" { self.textDocumentProxy.deleteBackward() }
        }
    }
}


