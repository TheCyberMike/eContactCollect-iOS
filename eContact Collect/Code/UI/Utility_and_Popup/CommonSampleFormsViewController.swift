//
//  CommonSampleFormsViewController.swift
//  eContact Collect
//
//  Created by Dev on 8/30/19.
//

import UIKit
import WebKit

// define the delegate protocol that other portions of the App may use to know when a sample form import succeeded;
// note this could get called several times if the end-user imports more than one form
protocol CSFVC_Delegate {
    func completed_CSFVC(fromVC:SampleFormsViewController, orgWasImported:String, formWasImported:String?)
}

class SampleFormsViewController: UIViewController, WKNavigationDelegate, CIVC_Delegate {
    // caller pre-set member variables
    public var mForOrgShortCode:String? = nil   // target Org code (optional)
    public var mDelegate:CSFVC_Delegate? = nil  // optional callback when an org or form sucessfully imports
    
    // member variables
    private var mWebView:WKWebView!
    
    // member constants and other static content
    private let mCTAG:String = "VCUCSF"
    
    // outlets to screen controls
    
    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED")
    }
    
    // called by the framework when there is no storyboard entry defined for the UI Class
    override func loadView() {
//debugPrint("\(self.mCTAG).loadView STARTED")
        let webConfiguration = WKWebViewConfiguration()
        self.mWebView = WKWebView(frame: .zero, configuration: webConfiguration)
        self.mWebView.navigationDelegate = self
        view = self.mWebView
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB, but NOT called during a fully programmatic startup;
    // only children (no parents) will be available but not yet initialized (not yet viewDidLoad)
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        
        // set overall form options
        navigationItem.title = NSLocalizedString("Sample Forms", comment:"")
        
        // load the proper page
        let myURL = URL(string:"https://sites.google.com/view/econtactcollect/home/samples")
        let myRequest = URLRequest(url: myURL!)
        self.mWebView.load(myRequest)
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
    }
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    // need to forceably clear the form else this VC will not deinit()
    override func viewDidDisappear(_ animated:Bool) {
        if self.isBeingDismissed || self.isMovingFromParent ||
            (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND VC IS DISMISSED")
        } else {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED BUT VC is not being dismissed")
        }
        super.viewDidDisappear(animated)
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // a link was clicked; what should be done?
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url, let scheme = url.scheme, scheme.contains("http") else {
            // This is not HTTP/HTTPS link - can be a local file or a mailto but we do not intend to support it
            decisionHandler(.cancel)
            return
        }
        
        // This is a HTTP/HTTPS link
        guard let domain = url.host, domain.contains("drive.google.com") else {
            // This is a HTTP/HTTPS link within the Support web site; allow it
            decisionHandler(.allow)
            return
        }
        
        // its a download of a sample form
        decisionHandler(.cancel)
        
        // open the new view controller to perform the download into the Documents directory
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "VC PopupDownload") as! PopupDownloadViewController
        newViewController.mWebURL = url
        newViewController.mCompletionUIthread = { docURL in
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let newViewController = storyBoard.instantiateViewController(withIdentifier: "VC PopupImport") as! PopupImportViewController
            newViewController.mForOrgShortCode = self.mForOrgShortCode
            newViewController.mCIVCdelegate = self
            newViewController.mFromExternal = false
            newViewController.mFileURL = docURL
            newViewController.modalPresentationStyle = .custom
            self.present(newViewController, animated: true, completion: nil)
        }
        newViewController.modalPresentationStyle = .custom
        self.present(newViewController, animated: true, completion: nil)
    }
    
    // handle web errors
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Web Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Web Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
    }
    
    // callback from the import popup screen
    public func completed_CIVC_ImportSuccess(fromVC:PopupImportViewController, orgWasImported:String, formWasImported:String?) {
        if self.mDelegate != nil {
            self.mDelegate!.completed_CSFVC(fromVC: self, orgWasImported: orgWasImported, formWasImported: formWasImported)
        }
    }
}
