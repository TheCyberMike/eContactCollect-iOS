//
//  NumberKeyboard.swift
//  eContact Collect
//
//  Created by Yo on 10/29/18.
//

import UIKit

class NumberKeyboardView: UIInputView {
    weak var delegate: UIKeyInput?
    private var mAllows:String = "+-,."
    
    init(frame: CGRect, inputViewStyle: UIInputView.Style, allows:String) {
        super.init(frame: frame, inputViewStyle: inputViewStyle)
        self.mAllows = allows
        initializeSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeSubviews()
    }
    
    override init(frame: CGRect, inputViewStyle: UIInputView.Style) {
        super.init(frame: frame, inputViewStyle: inputViewStyle)
        initializeSubviews()
    }
    
    func initializeSubviews() {
        let xibFileName = "NumberKeyboard"
        let view = Bundle.main.loadNibNamed(xibFileName, owner: self, options: nil)![0] as! UIView
        self.addSubview(view)
        view.frame = self.bounds
        
        if self.mAllows.contains("+") { self.setButtonState(button: button_plus, allowed: true) }
        else { self.setButtonState(button: button_plus, allowed: false) }
        if self.mAllows.contains("-") { self.setButtonState(button: button_minus, allowed: true) }
        else { self.setButtonState(button: button_minus, allowed: false) }
        if self.mAllows.contains(".") { self.setButtonState(button: button_period, allowed: true) }
        else { self.setButtonState(button: button_period, allowed: false) }
        if self.mAllows.contains(",") { self.setButtonState(button: button_comma, allowed: true) }
        else { self.setButtonState(button: button_comma, allowed: false) }
    }
    
    private func setButtonState(button:UIButton, allowed:Bool) {
        if allowed {
            button.isEnabled = true
            button.backgroundColor = UIColor.white
            button.setTitleColor(UIColor.black, for: UIControl.State.normal)
        } else {
            button.isEnabled = false
            button.backgroundColor = UIColor.clear
            button.setTitleColor(UIColor.clear, for: UIControl.State.normal)
        }
    }
    
    
    @IBOutlet weak var button_period: UIButton!
    @IBOutlet weak var button_comma: UIButton!
    @IBOutlet weak var button_plus: UIButton!
    @IBOutlet weak var button_minus: UIButton!
    @IBAction func button_backspace_pressed(_ sender: UIButton) {
        self.delegate?.deleteBackward()
    }
    @IBAction func button_char_pressed(_ sender: UIButton) {
        self.delegate?.insertText(sender.titleLabel!.text!)
    }
}

class NumberKeyboardViewController: UIInputViewController, UIKeyInput {
    public var mAllows:String = "+-,."
    
    init(allows: String) {
        super.init(nibName: nil, bundle: nil)
        self.mAllows = allows
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadInterface()
    }
    
    func loadInterface() {
        let keyboardView = NumberKeyboardView(frame: CGRect(x:0, y:0, width:414, height:169), inputViewStyle: .keyboard, allows: self.mAllows)
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
        } else {
            if text == "+" || text == "-"  {
                // plus or minus can only be the first character
            } else if current!.contains(".") && (text == "." || text == ",")  {
                // only one period is allowed
            } else {
                self.textDocumentProxy.insertText(text)
            }
        }
    }
    
    public func deleteBackward() {
        self.textDocumentProxy.deleteBackward()
    }
}

