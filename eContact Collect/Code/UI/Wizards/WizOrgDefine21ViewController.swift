//
//  WizOrgDefine21ViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/4/18.
//

import UIKit

class WizOrgDefine21ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // member variables
    var mHasALogo:Bool = false
    var mLogoUIImage:UIImage? = nil
    
    // member constants and other static content
    private let mCTAG:String = "VCW2-21"
    private weak var mRootVC:WizMenuViewController? = nil

    // outlets to screen controls
    @IBOutlet weak var switch_has_logo: UISwitch!
    @IBOutlet weak var label_instructions: UILabel!
    @IBOutlet weak var button_logo: UIButton!
    @IBOutlet weak var button_delete_logo: UIButton!
    @IBAction func button_cancel_pressed(_ sender: UIBarButtonItem) {
        self.mRootVC!.mWorking_Org_Rec = nil
        self.navigationController?.popToRootViewController(animated: true)
    }
    @IBAction func button_has_logo_changed(_ sender: UISwitch) {
        if sender.isOn {
            self.label_instructions.isEnabled = true
            self.button_logo.isHidden = false
            self.button_delete_logo.isHidden = false
        } else {
            self.label_instructions.isEnabled = false
            self.button_logo.isHidden = true
            self.button_delete_logo.isHidden = true
        }
    }
    @IBAction func button_logo_pressed(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .savedPhotosAlbum;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated:true, completion:nil)
        } else {
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Permission Error", comment:""), message: NSLocalizedString("iOS is not allowing the App to access the Photo Library", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
        }
    }
    @IBAction func button_delete_logo_pressed(_ sender: UIButton) {
        self.mLogoUIImage = nil
        self.mRootVC!.mWorking_Org_Rec!.rOrg_Logo_Image_PNG_Blob = nil
        self.button_logo.setImage(#imageLiteral(resourceName: "Add Image"), for:UIControl.State.normal)
        self.mHasALogo = false
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
        self.mRootVC = self.navigationController!.viewControllers.first as? WizMenuViewController
        assert(self.mRootVC != nil, "\(self.mCTAG).viewDidLoad self.mRootVC == nil")
        assert(self.mRootVC!.mWorking_Org_Rec != nil, "\(self.mCTAG).viewDidLoad self.mRootVC!.mWorking_Org_Rec == nil")
        
        self.button_logo.setImage(#imageLiteral(resourceName: "Add Image"), for:UIControl.State.normal)
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        self.reload()
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // insert any existing Org logo
    private func reload() {
        if self.mRootVC!.mWorking_Org_Rec!.rOrg_Logo_Image_PNG_Blob == nil {
            self.mLogoUIImage = nil
            self.mHasALogo = false
            self.switch_has_logo.isOn = false
            self.label_instructions.isEnabled = false
            self.button_logo.isHidden = true
            self.button_delete_logo.isHidden = true
        } else {
            self.mLogoUIImage = UIImage(data:self.mRootVC!.mWorking_Org_Rec!.rOrg_Logo_Image_PNG_Blob!)!
            self.button_logo.setImage(mLogoUIImage, for:UIControl.State.normal)
            self.mHasALogo = true
            self.switch_has_logo.isOn = true
            self.label_instructions.isEnabled = true
            self.button_logo.isHidden = false
            self.button_delete_logo.isHidden = false
        }
    }
    
    // intercept the Next segue
    override open func shouldPerformSegue(withIdentifier identifier:String, sender:Any?) -> Bool {
        if identifier != "Segue Next_W_ORG_21_26" { return true }
        
        if switch_has_logo.isOn == true && self.mHasALogo == false {
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("A Logo has not yet been loaded", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
            return false
        }
        
        if switch_has_logo.isOn == true  && self.mLogoUIImage != nil {
            self.mRootVC!.mWorking_Org_Rec!.rOrg_Logo_Image_PNG_Blob = self.mLogoUIImage!.pngData()
            if self.mRootVC!.mWorking_Org_Rec!.rOrg_Title_Mode == RecOrganizationDefs.ORG_TITLE_MODE.ONLY_TITLE {
                self.mRootVC!.mWorking_Org_Rec!.rOrg_Title_Mode = RecOrganizationDefs.ORG_TITLE_MODE.BOTH_50_50
            }
        } else {
            self.mRootVC!.mWorking_Org_Rec!.rOrg_Logo_Image_PNG_Blob = nil
        }
        return true
    }
    
    ///////////////////////////////////////////////////////////////////
    // Methods related to the ImageView or Button for the Logo
    ///////////////////////////////////////////////////////////////////
    
    // an image was picked by the end-user
    func imagePickerController(_ picker:UIImagePickerController, didFinishPickingMediaWithInfo info:[UIImagePickerController.InfoKey : Any]) {
        if var pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            // an image was indeed returned;
            // the view height for logos and titles is 50 ... for 3x imagery thus we need 150 height
            let newHeight:CGFloat = 150.0
            if pickedImage.size.height != newHeight {
                let newWidth:CGFloat = pickedImage.size.width * (newHeight / pickedImage.size.height)
                UIGraphicsBeginImageContext(CGSize(width:newWidth, height:newHeight))
                pickedImage.draw(in:CGRect(x:0.0, y:0.0, width:newWidth, height:newHeight))
                if let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() {
                    pickedImage = newImage
                }
                UIGraphicsEndImageContext()
            }
            self.mLogoUIImage = pickedImage
            self.mRootVC!.mWorking_Org_Rec!.rOrg_Logo_Image_PNG_Blob = pickedImage.pngData()
            self.button_logo.setImage(pickedImage, for:UIControl.State.normal)
            self.mHasALogo = true
        }
        
        // dismiss the picker regardless
        self.dismiss(animated:true, completion:nil)
    }
    
    // an image was not picked by the end-user
    func imagePickerControllerDidCancel(_ picker:UIImagePickerController) {
        self.dismiss(animated: true, completion:nil)
    }
}
