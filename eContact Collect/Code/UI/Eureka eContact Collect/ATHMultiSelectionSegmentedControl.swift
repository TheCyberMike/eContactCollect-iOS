//
//  ATHMultiSelectionSegmentedControl.swift
//  ATHMultiSelectionSegmentedControl
//
//  Created by Athanasios Theodoridis on 06/06/16.
//  https://github.com/attheodo/ATHMultiSelectionSegmentedControl
//
/*
 Copyright (c) 2016 attheodo <at@atworks.gr>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */
//
import Foundation
import UIKit

/**
 MultiSelectionSegmentedControlDelegate delegate protocol.
 */
public protocol MultiSelectionSegmentedControlDelegate: class {
    /// Gets called *ONLY* if the user interacts with the control and not
    /// when the control is configured programatically
    func multiSelectionSegmentedControl(_ control: MultiSelectionSegmentedControl, selectedIndices indices: [Int])
}

open class MultiSelectionSegmentedControl: UIControl {      // !!! MMM
    
    // MARK: - Private Properties
    fileprivate var _segmentButtons: [ATHMultiSelectionControlSegmentButton]?
    fileprivate var _items: [String]?
    fileprivate var _images: [UIImage]?     // !!! MMM
    
    // MARK: - Public Properties
    open weak var delegate: MultiSelectionSegmentedControlDelegate?
    
    // !!! MMM START
    private var leastCommonWidth:CGFloat = 0.0
    private var _intrinsicContentSize:CGSize = CGSize(width:-1.0, height:-1.0)
    
    override open var intrinsicContentSize:CGSize {
        get { return _intrinsicContentSize }
        set { _intrinsicContentSize = newValue }
    }
    
    public var height:CGFloat = 29.0 {
        didSet {
            self.intrinsicContentSize.height = self.height
            self.frame.size.height = self.height
            if let segmentButtons = _segmentButtons {
                for (_, button) in segmentButtons.enumerated() {
                    button.frame.size.height = self.height
                }
            }
        }
    }
    
    public var apportionsSegmentWidthsByContent = false {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    public var singleSelectionMode:Bool = false
    
    // !!! MMM END
    
    open var cornerRadius: CGFloat = 3 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    
    open var borderWidth: CGFloat = 1 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    open var font: UIFont = UIFont.systemFont(ofSize: 14) {
        didSet {
            self.height = self.sizeOfString(string: "MMMaa..", usingFont: font).height  // !!! MMM
            self.intrinsicContentSize.height = self.height  // !!! MMM
            if let segmentButtons = _segmentButtons {
                for (_, button) in segmentButtons.enumerated() {
                    button.titleLabel?.font = font
                    button.frame.size.height = self.height  // !!! MMM
                }
            }
        }
    }
    
    override open var tintColor: UIColor! {
        didSet {
            layer.borderColor = tintColor.cgColor
            if let segmentButtons = _segmentButtons {
                for (index, button) in segmentButtons.enumerated() {
                    button.isHighlighted = selectedSegmentIndices.contains(index)
                }
            }
        }
    }
    
    open override var backgroundColor: UIColor? {
        didSet {
            if let segmentButtons = _segmentButtons {
                for (index, button) in segmentButtons.enumerated() {
                    button.isHighlighted = selectedSegmentIndices.contains(index)
                }
            }
        }
    }
    
    /// Returns the number of segments the receiver has. (read-only)
    open var numberOfSegments: Int {
        
        guard let segments = _segmentButtons , segments.count > 0 else {
            return 0
        }
        
        return segments.count
    }
    
    /**
     An array with the currently selected segment indices of the receiver.
     */
    open var selectedSegmentIndices: [Int] {
        
        get {
            
            guard let segments = _segmentButtons , segments.count > 0 else {
                return []
            }
            
            var indices: [Int] = []
            
            for (index, segmentButton) in segments.enumerated() {
                if segmentButton.isButtonSelected && segmentButton.isButtonEnabled {
                    indices.append(index)
                }
            }
            
            return indices
            
        }
        
        set {
            
            guard let segments = _segmentButtons , segments.count > 0 else {
                return
            }
            
            _deselectAllSegments()
            
            for index in newValue {
                if segments[index].isButtonEnabled {
                    segments[index].setButtonSelected(true)
                }
                if self.singleSelectionMode { break }   // !!! MMM
            }
            
        }
        
    }
    
    // MARK: - Initialisers
    
    /**
     Initialises and returns a multiple-selection segmented control having the given titles.
     Warning: the segment buttons will not be created until the first iOS LayoutSubviews ... which may prevent initializing the button states
              use insertSegment(...) instead to be able to initialze button states early
     
     - parameter items: An array of `String` objects with the segments titles
     - returns: An initialised `MultiSelectionSegmentedControl` object
     */
    public init(items: [String]? = nil) {
        _items = items
        _images = nil       // !!! MMM
        
        super.init(frame: CGRect.zero)
        _configureAppearance()
        
    }
    
    // !!! MMM START
    /**
     Initialises and returns a multiple-selection segmented control having the given images.
     
     - parameter items: An array of `UIImage` objects with the segments images
     - returns: An initialised `MultiSelectionSegmentedControl` object
     */
    public init(images: [UIImage]? = nil) {
        
        _images = images
        if images != nil {
            _items = []
            for _ in 0...images!.count - 1 {
                _items!.append("")
            }
        } else { _items = nil }
        
        super.init(frame: CGRect.zero)
        _configureAppearance()
        
    }
    // !!! MMM END
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        _configureAppearance()
    }
    
    // MARK: - Public Methods
    
    // iOS Auto-Layout system FIRST calls updateConstraints() so that proper contraints can be put into place before doing actual layout
    // !!! MMM START
    open override func updateConstraints() {
//debugPrint("ATHMSSC.updateConstraints STARTED")
        
        // !!! MMM START
        //dynamicConstraints.append(NSLayoutConstraint(item: self.segmentedControl_Multi!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self._height))
        //dynamicConstraints.append(NSLayoutConstraint(item: self.segmentedControl_Multi!, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.segmentedControl_Multi!.frame.size.width))
        // !!! MMM END
        
        // any constraints go here
        super.updateConstraints()
    }
    // !!! MMM END

    // iOS Auto-Layout system SECOND calls layoutSubviews() after constraints are in-place and relative positions and sizes of all elements
    // have been decided by auto-layout
    override open func layoutSubviews() {
//debugPrint("ATHMSSC.layoutSubviews STARTED ApportionMode=\(self.apportionsSegmentWidthsByContent)")
        guard let items = _items , items.count > 0 else {
            return
        }
        
        // MMM !!! START
        let buttonHeight:CGFloat = self.height
        self.intrinsicContentSize.height = self.height
        self.intrinsicContentSize.width = 0.0
        // MMM !!! END
        
        if subviews.count == 0 {
            
            _segmentButtons = []
            
            // !!! MMM START
            var totalApportionedWidth:CGFloat = 0.0
            self.leastCommonWidth = 0.0
            for segmentTitle in items {
                let intrinButtonWidth:CGFloat = self.sizeOfString(string: segmentTitle, usingFont: self.font).width
                totalApportionedWidth = totalApportionedWidth + intrinButtonWidth
                if intrinButtonWidth > self.leastCommonWidth { self.leastCommonWidth = intrinButtonWidth }
            }
            // !!! MMM END
            
            var buttonWidth = frame.width / CGFloat(items.count)    // !!! MMM
            //!!!MMMlet buttonHeight = frame.height
            
            // !!! MMM START
            if buttonWidth == 0.0 { buttonWidth = self.leastCommonWidth }
            // !!! MMM END

            var xPos:CGFloat = 0.0  // !!! MMM
            for (index, segmentTitle) in items.enumerated() {
                //let buttonFrame = CGRect(x: CGFloat(index)*buttonWidth, y: 0, width: buttonWidth, height: buttonHeight)
                // !!! MMM START
                if self.apportionsSegmentWidthsByContent {
                    let intrinButtonWidth:CGFloat = self.sizeOfString(string: segmentTitle, usingFont: self.font).width
                    buttonWidth = (intrinButtonWidth / totalApportionedWidth) * self.frame.width
                    self.intrinsicContentSize.width = self.intrinsicContentSize.width + intrinButtonWidth
                } else {
                    self.intrinsicContentSize.width = self.intrinsicContentSize.width + self.leastCommonWidth
                }
                let buttonFrame = CGRect(x: xPos, y: 0, width: buttonWidth, height: buttonHeight)
                xPos = xPos + buttonWidth
                // !!! MMM END

                let button = ATHMultiSelectionControlSegmentButton(frame: buttonFrame)
                button.titleLabel?.font = font                  // !!! MMM
                button.tintColor = tintColor
                button.backgroundColor = backgroundColor
                button.titleColorSelected = backgroundColor     // !!! MMM
                button.titleLabel?.numberOfLines = 0            // !!! MMM
                button.setButtonSelected(selectedSegmentIndices.contains(index))
                button.addTarget(self, action: #selector(self._didTouchUpInsideSegment(_:)), for: .touchUpInside)
                
                // !!! MMM START
                if _images != nil {
                    button.setImage(_images![index], for: .normal)
                } else {
                    button.setTitle(segmentTitle, for: .normal)
                }
                // !!! MMM END
                
                _segmentButtons?.append(button)
                
                self.addSubview(button)
            }
        }
        else {
            if let segmentButtons = _segmentButtons {
                
                // !!! MMM START
                var totalApportionedWidth:CGFloat = 0.0
                self.leastCommonWidth = 0.0
                for button in segmentButtons {
                    let intrinButtonWidth:CGFloat = self.sizeOfString(string: (button.titleLabel?.text ?? ""), usingFont: self.font).width
                    totalApportionedWidth = totalApportionedWidth + intrinButtonWidth
                    if intrinButtonWidth > self.leastCommonWidth { self.leastCommonWidth = intrinButtonWidth }
                }
                // !!! MMM END
                
                var buttonWidth = frame.width / CGFloat(segmentButtons.count)   // !!! MMM
                //!!!MMMlet buttonHeight = frame.height
                
                // !!! MMM START
                if buttonWidth == 0.0 { buttonWidth = self.leastCommonWidth }
                // !!! MMM END
                
                var xPos:CGFloat = 0.0  // !!! MMM
                for (index, button) in segmentButtons.enumerated() {
                    //!!!MMMlet buttonFrame = CGRect(x: CGFloat(index)*buttonWidth, y: 0, width: buttonWidth, height: buttonHeight)
                    // !!! MMM START
                    if self.apportionsSegmentWidthsByContent {
                        let intrinButtonWidth:CGFloat = self.sizeOfString(string: (button.titleLabel?.text ?? ""), usingFont: self.font).width
                        buttonWidth = (intrinButtonWidth / totalApportionedWidth) * self.frame.width
                        self.intrinsicContentSize.width = self.intrinsicContentSize.width + intrinButtonWidth
                    } else {
                        self.intrinsicContentSize.width = self.intrinsicContentSize.width + self.leastCommonWidth
                    }
                    let buttonFrame = CGRect(x: xPos, y: 0, width: buttonWidth, height: buttonHeight)
                    xPos = xPos + buttonWidth
                    // !!! MMM END
                    
                    button.frame = buttonFrame
                    button.setButtonSelected(selectedSegmentIndices.contains(index))
                }
            }
        }
        invalidateIntrinsicContentSize()
    }
    
    // MARK: Managing Segment Content
    /**
     Sets the title of a segment.
     
     - parameter title: A string to display in the segments as its title.
     - parameter segment: An index number identifying a segment in the control.
     It must be a number between 0 and the number of segments (numberOfSegments) minus 1; values exceeding this upper range are pinned to it.
     */
    open func setTitle(_ title: String, forSegmentAtIndex segment: Int) {
        
        guard let segments = _segmentButtons , segments.count > 0 && segment >= 0 else {
            return
        }
        
        let index = segment > segments.count - 1 ? segments.count - 1 : segment
        
        segments[index].setTitle(title, for: .normal)
        // ???
        
    }
    
    /**
     Returns the title of the specified segment.
     
     - parameter segment: An index number identifying a segment in the control. It must be a number between 0 and the number of segments (numberOfSegments)
     minus 1; values exceeding this upper range are pinned to it.
     - returns: Returns the string (title) assigned to the receiver as content.
     */
    open func titleForSegmentAtIndex(_ segment: Int) -> String? {
        
        guard let segments = _segmentButtons , segments.count > 0 && segment >= 0 else {
            return nil
        }
        
        let index = segment > segments.count - 1 ? segments.count - 1 : segment
        
        return segments[index].titleLabel?.text
        
    }
    
    // !!! MMM START
    /**
     Sets the image of a segment.  Can only have image or title, not both
     
     - parameter image: A UIImage to display in the segments as its title.
     - parameter segment: An index number identifying a segment in the control. It must be a number between 0 and the number of segments (numberOfSegments)
     minus 1; values exceeding this upper range are pinned to it.
     */
    open func setImage(_ image: UIImage?, forSegmentAt segment: Int) {
        
        guard let segments = _segmentButtons , segments.count > 0 && segment >= 0 else {
            return
        }
        
        let index = segment > segments.count - 1 ? segments.count - 1 : segment
        
        segments[index].setImage(image, for: .normal)
    }
    
    /**
     Returns the image of the specified segment.
     
     - parameter segment: An index number identifying a segment in the control. It must be a number between 0 and the number of segments (numberOfSegments)
     minus 1; values exceeding this upper range are pinned to it.
     - returns: Returns the UIImage assigned to the receiver as content.
     */
    open func imageForSegment(at segment: Int) -> UIImage? {
        
        guard let segments = _segmentButtons , segments.count > 0 && segment >= 0 else {
            return nil
        }
        
        let index = segment > segments.count - 1 ? segments.count - 1 : segment
        
        return segments[index].image(for: .normal)
    }
    // !!! MMM END
    
    // MARK: Managing Segment Behavior
    
    /**
     Enables the specified segment.
     
     - parameter enabled: `true` to enable the specified segment or `false` to disable the segment.
     By default all segments are enabled
     */
    open func setEnabled(_ enabled: Bool, forSegmentAtIndex segment: Int) {
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) { () -> Void in
            
            guard let segments = self._segmentButtons , segments.count > 0 && segment >= 0 else {
                return
            }
            
            let index = segment > segments.count - 1 ? segments.count - 1 : segment
            segments[index].setButtonEnabled(enabled)
            
        }
        
    }
    
    /**
     Returns whether the indicated segment is enabled.
     
     - parameter segment: An index number identifying a segment in the control. It must be a number between 0 and the number of segments (numberOfSegments) minus 1;
     values exceeding this upper range are pinned to it.
     
     - returns: `true` if the given segment is enabled and `false` if the segment is disabled. By default, segments are enabled.
     */
    open func isEnabledForSegmentAtIndex(_ segment: Int) -> Bool {
        
        guard let segments = _segmentButtons , segments.count > 0 && segment >= 0 else {
            return false
        }
        
        let index = segment > segments.count - 1 ? segments.count - 1 : segment
        
        return segments[index].isButtonEnabled
        
    }
    
    // MARK: Managing Segments
    /**
     Creates a number of segments based on the passed array of titles
     
     - parameter titles: The titles of the segments to create.
     */
    open func insertSegmentsWithTitles(_ titles: [String]) {
        
        _items = titles
        _configureAppearance()
        
        setNeedsLayout()
        
    }
    
    /**
     Inserts a segment at a specific position in the receiver and gives it a title as content.
     
     - parameter title: A string to use as the segment’s title.
     - parameter segment: An index number identifying a segment in the control. The new segment is inserted just before the designated one.
     - parameter animated: true if the insertion of the new segment should be animated, otherwise false.
     */
    open func insertSegment(_ withTitle: String, at: Int, animated: Bool) {     /// !!! MMM
        insertSegmentWithTitle(withTitle, atIndex:at, animated:animated)
    }
    open func insertSegmentWithTitle(_ title: String, atIndex segment: Int, animated: Bool) {
        guard segment >= 0 else {
            return
        }
        
        if numberOfSegments == 0 {
            _configureAppearance()
        }
        
        let index = segment
        
        if _items == nil { _items = [] }
        if _segmentButtons == nil { _segmentButtons = [] }
        
        if index > _items!.count {
            _items!.append(title)
        } else {
            _items!.insert(title, at: index)
        }
        
        var buttonHeight:CGFloat = self.height  // !!! MMM
        // !!! MMM START
        self.intrinsicContentSize.height = self.height
        self.intrinsicContentSize.width = 0.0
        // !!! MMM END
        
        let button = ATHMultiSelectionControlSegmentButton(frame: CGRect(x: self.frame.width, y: 0, width: 0, height: buttonHeight))  // !!! MMM

        button.titleLabel?.font = font                  // !!! MMM
        button.tintColor = tintColor
        button.backgroundColor = backgroundColor
        button.titleColorSelected = backgroundColor     // !!! MMM
        button.titleLabel?.numberOfLines = 0            // !!! MMM
        button.addTarget(self, action: #selector(self._didTouchUpInsideSegment(_:)), for: .touchUpInside)
        
        button.setTitle(title, for: .normal)
        
        addSubview(button)
        
        if index > _segmentButtons!.count {
            _segmentButtons?.append(button)
        } else {
            _segmentButtons!.insert(button, at: index)
        }
        // !!! MMM START
        if button.intrinsicContentSize.height > self.height {
            self.height = button.intrinsicContentSize.height
            buttonHeight = button.intrinsicContentSize.height
        }
        var totalApportionedWidth:CGFloat = 0.0
        self.leastCommonWidth = 0.0
        for segment in self._segmentButtons! {
            let intrinButtonWidth:CGFloat = self.sizeOfString(string: (segment.titleLabel?.text ?? ""), usingFont: self.font).width
            totalApportionedWidth = totalApportionedWidth + intrinButtonWidth
            if intrinButtonWidth > self.leastCommonWidth { self.leastCommonWidth = intrinButtonWidth }
        }
        // !!! MMM END
        
        var buttonWidth = self.frame.width / CGFloat(self._items!.count)    // !!! MMM
        // !!! MMM START
        if buttonWidth == 0.0 { buttonWidth = self.leastCommonWidth }
        // !!! MMM END
        
        let duration = animated ? 0.35 : 0
        
        UIView.animate(withDuration: duration, animations: {

            var xPos:CGFloat = 0.0  // !!! MMM
            //!!!MMMfor (index, segment) in self._segmentButtons!.enumerated() {
            for segment in self._segmentButtons! {
                // !!! MMM let buttonFrame = CGRect(x: CGFloat(index)*buttonWidth, y: 0, width: buttonWidth, height: buttonHeight)
                // !!! MMM START
                if self.apportionsSegmentWidthsByContent {
                    let intrinButtonWidth:CGFloat = self.sizeOfString(string: (segment.titleLabel?.text ?? ""), usingFont: self.font).width
                    buttonWidth = (intrinButtonWidth / totalApportionedWidth) * self.frame.width
                    self.intrinsicContentSize.width = self.intrinsicContentSize.width + intrinButtonWidth
                } else {
                    self.intrinsicContentSize.width = self.intrinsicContentSize.width + self.leastCommonWidth
                }
                let buttonFrame = CGRect(x: xPos, y: 0, width: buttonWidth, height: buttonHeight)
                xPos = xPos + buttonWidth
                // !!! MMM END
                segment.frame = buttonFrame
                
            }
        })
        invalidateIntrinsicContentSize()
    }

    // !!! MMM START
    /**
     Creates a number of segments based on the passed array of images
     
     - parameter images: The UIImages of the segments to create.
     */
    open func insertSegmentsWithImages(_ images: [UIImage]) {
        
        _images = images
        _items = []
        for _ in 0...images.count - 1 {
            _items!.append("")
        }
        
        _configureAppearance()
        
        setNeedsLayout()
        
    }
    
    /**
     Inserts a segment at a specific position in the receiver and gives it a title as content.
     
     - parameter image: A UIImage to use for the segment.
     - parameter segment: An index number identifying a segment in the control. The new segment is inserted just before the designated one.
     - parameter animated: true if the insertion of the new segment should be animated, otherwise false.
     */
    open func insertSegment(_ with: UIImage, at: Int, animated: Bool) {     /// !!! MMM
        insertSegmentWithImage(with, atIndex:at, animated:animated)
    }
    open func insertSegmentWithImage(_ image: UIImage, atIndex segment: Int, animated: Bool) {
        
        guard segment >= 0 else {
            return
        }
        
        if numberOfSegments == 0 {
            _configureAppearance()
        }
        
        let index = segment
        
        if _items == nil { _items = [] }
        if _segmentButtons == nil { _segmentButtons = [] }
        
        if index > _items!.count {
            _items!.append("")
            _images!.append(image)
        } else {
            _items!.insert("", at: index)
            _images!.insert(image, at: index)
        }
        
        let buttonHeight:CGFloat = self.height  // !!! MMM
        self.intrinsicContentSize.height = self.height  // !!! MMM
        self.intrinsicContentSize.width = frame.width  // !!! MMM
        
        let button = ATHMultiSelectionControlSegmentButton(frame: CGRect(x: self.frame.width, y: 0, width: 0, height: buttonHeight)) // !!! MMM
        
        button.titleLabel?.font = font                  // !!! MMM
        button.tintColor = tintColor
        button.backgroundColor = backgroundColor
        button.titleColorSelected = backgroundColor     // !!! MMM
        button.titleLabel?.numberOfLines = 0            // !!! MMM
        button.addTarget(self, action: #selector(self._didTouchUpInsideSegment(_:)), for: .touchUpInside)
        
        button.setImage(image, for: .normal)
        
        addSubview(button)
        
        if index > _segmentButtons!.count {
            _segmentButtons?.append(button)
        } else {
            _segmentButtons!.insert(button, at: index)
        }
        
        let duration = animated ? 0.35 : 0
        
        UIView.animate(withDuration: duration, animations: {
            
            for (index, segment) in self._segmentButtons!.enumerated() {
                
                let buttonWidth = self.frame.width / CGFloat(self._items!.count)
                let buttonHeight = self.height  // !!! MMM
                
                let buttonFrame = CGRect(x: CGFloat(index)*buttonWidth, y: 0, width: buttonWidth, height: buttonHeight)
                segment.frame = buttonFrame
                
            }
            
        })
        
    }
    // !!! MMM END
    
    /**
     Removes the specified segment from the receiver, optionally animating the transition.
     
     - parameter segment: An index number identifying a segment in the control. It must be a number between 0 and the number of segments (numberOfSegments) minus 1;
     values exceeding this upper range are pinned to it.
     - parameter animated: `true` if the removal of the new segment should be animated, otherwise `false`.
     */
    open func removeSegmentAtIndex(_ segment: Int, animated: Bool) {
        
        guard var segments = _segmentButtons , segments.count > 0 && segment >= 0 else {
            return
        }
        
        // if segment is out of range pin it
        let index = segment > segments.count - 1 ? segments.count - 1 : segment
        
        _items!.remove(at: index)
        
        segments[index].removeFromSuperview()
        segments.remove(at: index)
        _segmentButtons!.remove(at: index)
        
        let duration = animated ? 0.35 : 0
        
        UIView.animate(withDuration: duration, animations: {
            for (index, _) in segments.enumerated() {
                
                let buttonWidth = self.frame.width / CGFloat(segments.count)
                let buttonHeight = self.height  // !!! MMM
                
                segments[index].frame = CGRect(x: CGFloat(index)*buttonWidth, y: 0, width: buttonWidth, height: buttonHeight)
                
            }
        })
        
        if segments.count == 0 {
            layer.borderWidth = 0
        }
        
    }
    
    /**
     Removes all segments of the receiver.
     */
    open func removeAllSegments() {
        layer.borderWidth = 0
        
        _segmentButtons?.forEach { segment in
            segment.removeFromSuperview()
        }
        _segmentButtons?.removeAll()
        _items?.removeAll()
    }
    
    // MARK: - Private Methods
    
    // !!! MMM START
    func sizeOfString(string:String, usingFont font: UIFont) -> CGSize {
        let fontAttributes = [NSAttributedString.Key.font: font]
        return string.size(withAttributes: fontAttributes)
    }
    // !!! MMM END
    
    /**
     Configures the control's appearance:
     - Clears background color
     - Sets corner radius
     - Sets border width and color
     */
    fileprivate func _configureAppearance() {
        
        //        backgroundColor = UIColor.clearColor()
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        layer.borderWidth = 1.0
        layer.borderColor = tintColor.cgColor
    }
    
    /**
     Selector to the control's segment buttons. Handles selecting/deselecting segments
     according to whether they are enabled or not.
     */
    @objc fileprivate func _didTouchUpInsideSegment(_ segmentButton: ATHMultiSelectionControlSegmentButton) {
        
        guard let segmentButtons = _segmentButtons , segmentButtons.count > 0 else {
            return
        }
        
        guard segmentButton.isButtonEnabled else {
            return
        }
        
        // !!! MMM START
        if singleSelectionMode {
            _deselectAllSegments()
            segmentButton.setButtonSelected(true)
        // !!! MMM END
        } else if segmentButton.isButtonSelected {  // !!! MMM
            segmentButton.setButtonSelected(false)
        } else {
            segmentButton.setButtonSelected(true)
        }
        
        sendActions(for: .valueChanged) // !!! MMM
        
        delegate?.multiSelectionSegmentedControl(self, selectedIndices: selectedSegmentIndices)
        
    }
    
    /**
     Deselects all segments of the segmented control
     */
    fileprivate func _deselectAllSegments() {
        
        guard let segments = _segmentButtons , segments.count > 0 else {
            return
        }
        
        segments.forEach { segment in
            segment.setButtonSelected(false)
        }
        
        //sendActions(for: .valueChanged) // !!! MMM
        
    }
    
    /**
     Flips (horizontally) the segmented control and all its component segments
     */
    fileprivate func _flipHorizontally() {
        
        guard let segments = _segmentButtons , segments.count > 0 else {
            return
        }
        
        self.transform = CGAffineTransform(scaleX: -1, y: 1)
        
        segments.forEach { segment in
            segment.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
        
    }
    
}
