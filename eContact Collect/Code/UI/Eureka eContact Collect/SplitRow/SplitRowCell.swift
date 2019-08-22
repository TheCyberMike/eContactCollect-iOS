//
//  SplitRowCell.swift
//  Valletti
//
//  Created by Marco Betschart on 30.11.17.
//  Copyright © 2017 MANDELKIND. All rights reserved.
//
//  https://github.com/EurekaCommunity/SplitRow
//

open class SplitRowCell<L: RowType, R: RowType>: Cell<SplitRowValue<L.Cell.Value,R.Cell.Value>>, CellType where L: BaseRow, R: BaseRow{
	var tableViewLeft: SplitRowCellTableView<L>!
	var tableViewRight: SplitRowCellTableView<R>!
	
	open override var isHighlighted: Bool {
		get { return super.isHighlighted || (tableViewLeft.row?.cell?.isHighlighted ?? false) || (tableViewRight.row?.cell?.isHighlighted ?? false) }
		set { super.isHighlighted = newValue }
	}
	
    public required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		self.tableViewLeft = SplitRowCellTableView()
		tableViewLeft.separatorStyle = .none
		tableViewLeft.leftSeparatorStyle = .none
		tableViewLeft.translatesAutoresizingMaskIntoConstraints = false
		
		self.tableViewRight = SplitRowCellTableView()
		tableViewRight.separatorStyle = .none
		tableViewRight.leftSeparatorStyle = .singleLine
		tableViewRight.translatesAutoresizingMaskIntoConstraints = false
		
		contentView.addSubview(tableViewLeft)
        contentView.addConstraint(NSLayoutConstraint(item: tableViewLeft as Any, attribute: .left, relatedBy: .equal, toItem: contentView, attribute: .left, multiplier: 1.0, constant: 0.0))
		
		contentView.addSubview(tableViewRight)
        contentView.addConstraint(NSLayoutConstraint(item: tableViewRight as Any, attribute: .right, relatedBy: .equal, toItem: contentView, attribute: .right, multiplier: 1.0, constant: 0.0))
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	open override func setup(){
		selectionStyle = .none
		
		//ignore Xcode Cast warning here, it works!
		guard let row = self.row as? _SplitRow<L,R> else{ return }
		
		//TODO: If we use UITableViewAutomaticDimension instead of 44.0 we encounter constraint errors :(
		let maxRowHeight = max(row.rowLeft?.cell?.height?() ?? 44.0, row.rowRight?.cell?.height?() ?? 44.0)
        if maxRowHeight != UITableView.automaticDimension{
			self.height = { maxRowHeight }
			row.rowLeft?.cell?.height = self.height
			row.rowRight?.cell?.height = self.height
		}
		
		tableViewLeft.row = row.rowLeft
		tableViewLeft.isScrollEnabled = false
		tableViewLeft.setup()
		
		tableViewRight.row = row.rowRight
		tableViewRight.isScrollEnabled = false
		tableViewRight.setup()
		
		setupConstraints()
	}
	
	
	open override func update(){
		tableViewLeft.update()
		tableViewRight.update()
	}
    
    public func constraintsNeedBeUpdated() {
        guard let row = self.row as? _SplitRow<L,R> else{ return }
        
        for aConstraint in self.contentView.constraints {
            if aConstraint.identifier == "Eureka.SplitRow.LeftWidth" {
                let _ = aConstraint.setMultiplier(multiplier: row.rowLeftPercentage)
                //self.contentView.removeConstraint(aConstraint)
                //self.contentView.addConstraint(newConstraint)
            } else if aConstraint.identifier == "Eureka.SplitRow.RightWidth" {
                let _ = aConstraint.setMultiplier(multiplier: row.rowRightPercentage)
                //self.contentView.removeConstraint(aConstraint)
                //self.contentView.addConstraint(newConstraint)
            }
        }
        setNeedsLayout()
        layoutIfNeeded()
        tableViewLeft.reloadData()
        tableViewRight.reloadData()
    }
	
	private func setupConstraints(){
		guard let row = self.row as? _SplitRow<L,R> else{ return }
		
		if let height = self.height?(){
            self.contentView.addConstraint(NSLayoutConstraint(item: tableViewLeft as Any, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .height, multiplier: 1.0, constant: height))
            self.contentView.addConstraint(NSLayoutConstraint(item: tableViewRight as Any, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .height, multiplier: 1.0, constant: height))
		}
		
        let leftConstraint = NSLayoutConstraint(item: tableViewLeft as Any, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .width, multiplier: row.rowLeftPercentage, constant: 0.0)
        leftConstraint.identifier = "Eureka.SplitRow.LeftWidth"
        self.contentView.addConstraint(leftConstraint)
        let rightConstraint = NSLayoutConstraint(item: tableViewRight as Any, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .width, multiplier: row.rowRightPercentage, constant: 0.0)
        rightConstraint.identifier = "Eureka.SplitRow.RightWidth"
        self.contentView.addConstraint(rightConstraint)
	}
	
	private func rowCanBecomeFirstResponder(_ row: BaseRow?) -> Bool{
		guard let row = row else{ return false }
		return false == row.isDisabled && row.baseCell?.cellCanBecomeFirstResponder() ?? false
	}
	
	open override var isFirstResponder: Bool{
		guard let row = self.row as? _SplitRow<L,R> else{ return false }
		
		let rowLeftFirstResponder = row.rowLeft?.cell.findFirstResponder()
		let rowRightFirstResponder = row.rowRight?.cell?.findFirstResponder()
		
		return rowLeftFirstResponder != nil || rowRightFirstResponder != nil
	}
	
	open override func cellCanBecomeFirstResponder() -> Bool{
		guard let row = self.row as? _SplitRow<L,R> else{ return false }
		guard false == row.isDisabled else{ return false }
		
		let rowLeftFirstResponder = row.rowLeft?.cell.findFirstResponder()
		let rowRightFirstResponder = row.rowRight?.cell?.findFirstResponder()
		
		if rowLeftFirstResponder == nil && rowRightFirstResponder == nil{
			return rowCanBecomeFirstResponder(row.rowLeft) || rowCanBecomeFirstResponder(row.rowRight)
		
		} else if rowLeftFirstResponder == nil{
			return rowCanBecomeFirstResponder(row.rowLeft)
			
		} else if rowRightFirstResponder == nil{
			return rowCanBecomeFirstResponder(row.rowRight)
		}
		
		return false
	}
	
	open override func cellBecomeFirstResponder(withDirection: Direction) -> Bool {
		guard let row = self.row as? _SplitRow<L,R> else{ return false }
		
		let rowLeftFirstResponder = row.rowLeft?.cell.findFirstResponder()
		let rowLeftCanBecomeFirstResponder = rowCanBecomeFirstResponder(row.rowLeft)
		var isFirstResponder = false
		
		let rowRightFirstResponder = row.rowRight?.cell?.findFirstResponder()
		let rowRightCanBecomeFirstResponder = rowCanBecomeFirstResponder(row.rowRight)
		
		if withDirection == .down{
			if rowLeftFirstResponder == nil, rowLeftCanBecomeFirstResponder{
				isFirstResponder = row.rowLeft?.cell?.cellBecomeFirstResponder(withDirection: withDirection) ?? false
				
			} else if rowRightFirstResponder == nil, rowRightCanBecomeFirstResponder{
				isFirstResponder = row.rowRight?.cell?.cellBecomeFirstResponder(withDirection: withDirection) ?? false
			}
			
		} else if withDirection == .up{
			if rowRightFirstResponder == nil, rowRightCanBecomeFirstResponder{
				isFirstResponder = row.rowRight?.cell?.cellBecomeFirstResponder(withDirection: withDirection) ?? false
				
			} else if rowLeftFirstResponder == nil, rowLeftCanBecomeFirstResponder{
				isFirstResponder = row.rowLeft?.cell?.cellBecomeFirstResponder(withDirection: withDirection) ?? false
			}
		}
		
		if isFirstResponder {
			formViewController()?.beginEditing(of: self)
		}
		
		return isFirstResponder
	}
	
	open override func cellResignFirstResponder() -> Bool{
		guard let row = self.row as? _SplitRow<L,R> else{ return false }
		
		let rowLeftResignFirstResponder = row.rowLeft?.cell?.cellResignFirstResponder() ?? false
		let rowRightResignFirstResponder = row.rowRight?.cell?.cellResignFirstResponder() ?? false
		let resignedFirstResponder = rowLeftResignFirstResponder && rowRightResignFirstResponder
		
		if resignedFirstResponder {
			formViewController()?.endEditing(of: self)
		}
		
		return resignedFirstResponder
	}
}
