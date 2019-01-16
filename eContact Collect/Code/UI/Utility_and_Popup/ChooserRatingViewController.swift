//
//  ChooserRatingViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/17/18.
//

import UIKit
import Eureka

// define the delegate protocol that other portions of the App must use to know when the choice is made or cancelled
protocol CRVC_Delegate {
    func completed_CRVC(fromVC:ChooserRatingViewController, wasCancelled:Bool, collectorsRatings:String?)
}

class ChooserRatingViewController: UIViewController {
    // caller pre-set member variables
    public var mCRVCdelegate:CRVC_Delegate? = nil   // optional callback

    // member variables
    internal var mForCCindex:Int64 = 0
    internal var mInitialValue:String? = nil
    
    // member constants and other static content
    private let mCTAG:String = "VCUCR"
    
    // outlets to screen controls
    @IBOutlet weak var view_multi_segctrl: MultiSelectionSegmentedControl!
    @IBAction func button_done_pressed(_ sender: UIButton) {
        if self.mCRVCdelegate != nil {
            var ratings:String = ""
            for index in view_multi_segctrl.selectedSegmentIndices {
                switch index {
                case 0:
                    ratings = ratings + "!"
                    break
                case 1:
                    ratings = ratings + "5"
                    break
                case 2:
                    ratings = ratings + "3"
                    break
                case 3:
                    ratings = ratings + "1"
                    break
                case 4:
                    ratings = ratings + "?"
                    break
                case 5:
                    ratings = ratings + "X"
                    break
                default:
                    break
                }
            }
//debugPrint("\(self.mCTAG).button_done_pressed RATING=\(ratings)")
            self.mCRVCdelegate!.completed_CRVC(fromVC:self, wasCancelled:false, collectorsRatings:ratings)
        }
        dismiss(animated: true, completion: nil)
    }
    @IBAction func button_cancel_pressed(_ sender: UIButton) {
        // cancel button pressed; tell delegate as such, then dismiss and return to the parent view controller
        if self.mCRVCdelegate != nil { self.mCRVCdelegate!.completed_CRVC(fromVC:self, wasCancelled:true, collectorsRatings:nil) }
        dismiss(animated: true, completion: nil)
    }
    
    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED")
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB, but NOT called during a fully programmatic startup;
    // only children (no parents) will be available but not yet initialized (not yet viewDidLoad)
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        view_multi_segctrl.insertSegmentsWithImages([#imageLiteral(resourceName: "Exclaim"), #imageLiteral(resourceName: "Star Five"), #imageLiteral(resourceName: "Star Three"), #imageLiteral(resourceName: "Star One"), #imageLiteral(resourceName: "Question"), #imageLiteral(resourceName: "Not")])
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
    }
    
    // called by the framework after the view is fully shown
    override func viewDidAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewDidAppear STARTED")
        super.viewDidAppear(animated)
        
        if self.mInitialValue != nil {
            var selectedIndexes:[Int] = []
            for char in self.mInitialValue! {
                switch char {
                case "!":
                    selectedIndexes.append(0)
                    break
                case "5":
                    selectedIndexes.append(1)
                    break
                case "3":
                    selectedIndexes.append(2)
                    break
                case "1":
                    selectedIndexes.append(3)
                    break
                case "?":
                    selectedIndexes.append(4)
                    break
                case "X":
                    selectedIndexes.append(5)
                    break
                default:
                    break
                }
            }
            view_multi_segctrl.selectedSegmentIndices = selectedIndexes
        }
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

