//  Adapted from:
//  CheckButtonRow.swift
//  Eureka ( https://github.com/xmartlabs/Eureka )
//
//  Copyright (c) 2016 Xmartlabs SRL ( http://xmartlabs.com )
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import UIKit

// MARK: CheckButtonRow

/// A generic row with a button. The action of this button can be anything but normally will push a new view controller
public typealias CheckButtonRow = CheckButtonRowOf<String>

public final class CheckButtonRowOf<T: Equatable> : _CheckButtonRowOf<T>, RowType {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

open class _CheckButtonRowOf<T: Equatable> : Row<CheckButtonCellOf<T>> {
    open var presentationMode: PresentationMode<UIViewController>?
    
    open var checkBoxChanged:((CheckButtonCellOf<T>, _CheckButtonRowOf<T>) -> Void) = { _,_ in }
    
    required public init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = nil
        cellStyle = .default
    }
    
    open override func customDidSelect() {
        super.customDidSelect()
        if !isDisabled {
            if let presentationMode = presentationMode {
                if let controller = presentationMode.makeController() {
                    presentationMode.present(controller, row: self, presentingController: self.cell.formViewController()!)
                } else {
                    presentationMode.present(nil, row: self, presentingController: self.cell.formViewController()!)
                }
            }
        }
    }
    
    open override func customUpdateCell() {
        super.customUpdateCell()
        let leftAligmnment = presentationMode != nil
        cell.textLabel?.textAlignment = leftAligmnment ? .left : .center
        cell.accessoryType = !leftAligmnment || isDisabled ? .none : .disclosureIndicator
        cell.editingAccessoryType = cell.accessoryType
        cell.textLabel?.textColor = !leftAligmnment ? cell.tintColor.withAlphaComponent(isDisabled ? 0.3 : 1.0) : nil
    }
    
    open override func prepare(for segue: UIStoryboardSegue) {
        super.prepare(for: segue)
        (segue.destination as? RowControllerType)?.onDismissCallback = presentationMode?.onDismissCallback
    }
}

// MARK: CheckButtonCell

public typealias CheckButtonCell = CheckButtonCellOf<String>

open class CheckButtonCellOf<T: Equatable>: Cell<T>, CellType {

    @IBOutlet public weak var titleLabel: UILabel?
    @IBOutlet public weak var detailLabel: UILabel?
    @IBOutlet public weak var checkBox: UIButton?
    
    private var dynamicConstraints = [NSLayoutConstraint]()
    
    // cell object instance initialization;
    // via Eureka this usually gets called first at tableView(...estimatedHeightForRowAt:...)
    //            then in Eureka via the cellProvider be set to its default
    // called if a NIB or Storyboard is NOT used; // this will only ever get called once for the life of the row object instance;
    // do NOT put here any initializations that need to be done for both NIB-created or Dynamic-created;
    // all in-Form override { $0.xxx = ... } will be performed immediately after this and before setup() below
    // note: the cell's row property has NOT yet been set; row-property dependent init's cannot be done
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // create all the UI object that are needed
        self.titleLabel = self.textLabel
        self.titleLabel?.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel?.setContentHuggingPriority(UILayoutPriority(rawValue: 500), for: .horizontal)
        
        if style == UITableViewCell.CellStyle.subtitle {
            self.detailLabel = self.detailTextLabel
            self.detailLabel?.translatesAutoresizingMaskIntoConstraints = false
            self.detailLabel?.setContentHuggingPriority(UILayoutPriority(rawValue: 500), for: .horizontal)
        }
        
        let cb = UIButton()
        cb.translatesAutoresizingMaskIntoConstraints = false
        cb.setImage(UIImage(named: "Checkmarkempty", in: Bundle(identifier:"com.xmartlabs.Eureka"), compatibleWith: nil), for: .normal)
        cb.setImage(UIImage(named: "Checkmark", in: Bundle(identifier:"com.xmartlabs.Eureka"), compatibleWith: nil), for: .selected)
        cb.addTarget(self, action: #selector(checkBoxTapped), for: .touchUpInside)
        self.checkBox = cb
        
        self.contentView.addSubview(self.titleLabel!)
        self.contentView.addSubview(self.checkBox!)
        if style == UITableViewCell.CellStyle.subtitle { self.contentView.addSubview(self.detailLabel!) }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // called by Eureka immediately after init() and all in-Form overrides { $0.xxx = ... }
    // which means this normally is called during the larger iOS process at tableView(...estimatedHeightForRowAt:...)
    // this will only ever get called once for the life of the row object instance;
    //the cell's row property has been set; so row-property dependent init's need be done here;
    // (but only inits that cannot be changed by the Form mainline)
    open override func setup() {
        super.setup()
    }
    
    // called for the first time by Eureka as a part of the TableView(...cellForRowAt:...) during initial TableViewCell creation;
    // it will also get called upon rotation;
    // however this is also called by the Form mainline whenever it or the Developer want a Row to be refreshed in terms of its
    // settings (title), contents (value), or display/configuration items; most configuration belongs here
    // the first time this is called by TableView(...cellForRowAt:...) the TableViewCell's frame, bounds, and contentView are NOT properly sized
    // iOS TableView scrolling and Eureka's implementation is buggy in regards to variable height cells; need to not perform relayouts unless utterly necessary
    open override func update() {
        super.update()
        selectionStyle = row.isDisabled ? .none : .default
        accessoryType = .none
        editingAccessoryType = accessoryType
        textLabel?.textAlignment = .center
        textLabel?.textColor = tintColor.withAlphaComponent(row.isDisabled ? 0.3 : 1.0)
    }
    
    @objc func checkBoxTapped() {
        self.checkBox?.isSelected = !self.checkBox!.isSelected
        let cbRow = self.row as! _CheckButtonRowOf
        cbRow.checkBoxChanged(self, cbRow)
    }
    
    open override func didSelect() {
        super.didSelect()
        row.deselect()
    }
    
    /////////////////////////////////////////////////////////////////////////
    // Layout the Cell's textFields and controls, and update constraints
    /////////////////////////////////////////////////////////////////////////
    
    // iOS Auto-Layout system FIRST calls updateConstraints() so that proper contraints can be put into place before doing actual layout
    open override func updateConstraints() {
        contentView.removeConstraints(self.dynamicConstraints)
        self.dynamicConstraints = []
        var views: [String: AnyObject] = [:]
        views["titleLabel"] = self.titleLabel
        views["checkbox"] = self.checkBox
        if row.cellStyle == UITableViewCell.CellStyle.subtitle {
            views["detailLabel"] = self.detailLabel
            self.dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[checkbox]-5-[titleLabel]", options: [], metrics: nil, views: views)
            self.dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[checkbox]-5-[detailLabel]", options: [], metrics: nil, views: views)
            self.dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-[titleLabel]-5-[detailLabel]", options: [], metrics: nil, views: views)
            self.dynamicConstraints += [NSLayoutConstraint(item: self.checkBox!, attribute: .centerY, relatedBy: .equal, toItem: self.contentView, attribute: .centerY, multiplier: 1, constant: 0)]

        } else {
        
            self.dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[checkbox]-5-[titleLabel]", options: [], metrics: nil, views: views)
            self.dynamicConstraints += [NSLayoutConstraint(item: self.titleLabel!, attribute: .centerY, relatedBy: .equal, toItem: self.contentView, attribute: .centerY, multiplier: 1, constant: 0)]
            self.dynamicConstraints += [NSLayoutConstraint(item: self.checkBox!, attribute: .centerY, relatedBy: .equal, toItem: self.contentView, attribute: .centerY, multiplier: 1, constant: 0)]
        }
        contentView.addConstraints(dynamicConstraints)
        super.updateConstraints()
    }
    
    // iOS Auto-Layout system SECOND calls layoutSubviews() after constraints are in-place and relative positions and sizes of all elements
    // have been decided by auto-layout
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        // As titleLabel is the textLabel, iOS may re-layout without updating constraints, for example:
        // swiping, showing alert or actionsheet from the same section.
        // thus we need forcing update to use customConstraints()
        // this can create a nasty loop if constraint failures cause a re-invoke of layoutSubviews()
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
    }
}

