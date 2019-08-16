//
//  PopupDownloadViewController.swift
//  eContact Collect
//
//  Created by Dev on 8/15/19.
//

import UIKit

class PopupDownloadViewController: UIViewController, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    // caller pre-set member variables
    public var mWebURL:URL? = nil   // web URL to be downloaded
    public var mCompletionUIthread:((_ docURL:URL) -> Void)? = nil  // completion to be performed after download success dismissal
    
    // member variables
    private var mURLSession:URLSession? = nil
    private var mDownloadTask:URLSessionDownloadTask? = nil

    // member constants and other static content
    private let mCTAG:String = "VCUCD"
    
    // outlets to screen controls
    @IBOutlet weak var label_title: UILabel!
    @IBOutlet weak var button_cancel_okay: UIButton!
    @IBOutlet weak var textview_results: UITextView!
    @IBOutlet weak var activity_indicator: UIActivityIndicatorView!
    @IBOutlet weak var activity_progress: UIProgressView!
    
    @IBAction func button_pressed(_ sender: UIButton) {
        if self.mDownloadTask != nil { self.mDownloadTask!.cancel() }
        self.cleanupVC()
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
        
        assert(self.mWebURL != nil, "\(self.mCTAG).viewDidLoad self.mWebURL == nil")    // this is a programming error
        
        // preset the view's controls
        button_cancel_okay.titleLabel?.text = NSLocalizedString("Cancel", comment:"")
        textview_results.isHidden = true
        activity_indicator.isHidden = true
        activity_progress.progress = 0.0
        activity_progress.isHidden = true
        
        // setup and initiate the download
        self.mURLSession = URLSession(configuration: .background(withIdentifier: "eContactCollect"), delegate: self, delegateQueue: nil)
        self.mURLSession!.configuration.timeoutIntervalForRequest = 60      // seconds aka 1 minutes; maximum inter-packet timeout
        self.mURLSession!.configuration.timeoutIntervalForResource = 300    // seconds aka 5 minutes; maximum total download timeout
        let downloadTask = self.mURLSession!.downloadTask(with: self.mWebURL!)
        downloadTask.resume()
        activity_indicator.isHidden = false
        self.mDownloadTask = downloadTask
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // cleanup the VC upon dismissal to prevent memory leaks
    private func cleanupVC() {
        self.mWebURL = nil
        self.mDownloadTask = nil
        if self.mURLSession != nil { self.mURLSession!.invalidateAndCancel() }
        self.mURLSession = nil
        self.mCompletionUIthread = nil
    }
    
    // provides progress of the download
    // threading:  this will be in a worker thread
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        if downloadTask == self.mDownloadTask {
//debugPrint("\(mCTAG).urlSession.downloadTask.didWriteData STARTED")
            let calculatedProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            DispatchQueue.main.async {
                self.activity_progress.isHidden = false
                self.activity_progress.progress = calculatedProgress
            }
        }
    }
    
    // download was successfully completed
    // threading:  this will be in a worker thread
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
//debugPrint("\(mCTAG).urlSession.downloadTask.didFinishDownloadingTo STARTED")
        self.mDownloadTask = nil
        DispatchQueue.main.async {
            self.activity_indicator.isHidden = true
            self.activity_progress.isHidden = true
        }
        
        // initial checks of the successful download response information
        guard let response:HTTPURLResponse = downloadTask.response as? HTTPURLResponse else {
            DispatchQueue.main.async {
                self.showError(prefix: NSLocalizedString("Internal Error", comment:""), message: NSLocalizedString("iOS did not provide a download response", comment:""))
            }
            self.cleanupVC()
            return
        }
        if response.statusCode != 200 {
            DispatchQueue.main.async {
                self.showError(prefix: NSLocalizedString("Web Error", comment:""), message: NSLocalizedString("Web site returned download failure code ", comment:"") + "\(response.statusCode)")
            }
            self.cleanupVC()
            return
        }
        guard let contentDisp:String = response.allHeaderFields["Content-Disposition"] as? String else {
            DispatchQueue.main.async {
                self.showError(prefix: NSLocalizedString("Web Error", comment:""), message: NSLocalizedString("Web site failed to provide a Content-Disposition header", comment:""))
            }
            self.cleanupVC()
            return
        }
        if contentDisp.isEmpty {
            DispatchQueue.main.async {
                self.showError(prefix: NSLocalizedString("Web Error", comment:""), message: NSLocalizedString("Web site failed to provide a Content-Disposition header", comment:""))
            }
            self.cleanupVC()
            return
        }
        
        // download succeeded; do some more checks
        var fileName:String? = nil
        let contentDispStrings:[String] = contentDisp.components(separatedBy: ";")
        for entry:String in contentDispStrings {
            if entry.starts(with: "filename=") {
                fileName = String(entry.suffix(entry.count - 9)).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }
        }
        if (fileName ?? "").isEmpty {
            DispatchQueue.main.async {
                self.showError(prefix: NSLocalizedString("Web Error", comment:""), message: NSLocalizedString("Web site failed to provide the downloaded file name", comment:""))
            }
            self.cleanupVC()
            return
        }
        
        // download checks out; move it over to the documents folder
        var documentsURL:URL?
        do {
            documentsURL = try FileManager.default.url(for: .documentDirectory,
                                                       in: .userDomainMask,
                                                       appropriateFor: nil,
                                                       create: false)
        } catch {
            DispatchQueue.main.async {
                self.showError(prefix: NSLocalizedString("Filesystem Error", comment:""), errorStruct: error)
            }
            self.cleanupVC()
            return
        }
        let savedURL = documentsURL!.appendingPathComponent(fileName!)
        do {
            try FileManager.default.removeItem(at: savedURL)
        } catch {}
        do {
            try FileManager.default.moveItem(at: location, to: savedURL)
        } catch {
            DispatchQueue.main.async {
                self.showError(prefix: NSLocalizedString("Filesystem Error", comment:""), errorStruct: error)
            }
            self.cleanupVC()
            return
        }
        
        // dismiss; perform only a partial VC memory-leak cleanup
        // perform the invoker's completion handler (if any) after this VC's dismissal is completed
        self.mWebURL = nil
        self.mDownloadTask = nil
        if self.mURLSession != nil { self.mURLSession!.invalidateAndCancel() }
        self.mURLSession = nil
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: {
                if self.mCompletionUIthread != nil {
                    DispatchQueue.main.async {
                        self.mCompletionUIthread!(savedURL)
                        self.mCompletionUIthread = nil
                    }
                }
            })
        }
    }
    
    // called upon completion of download (if failed then error != nil; if success then error == nil
    // threading:  this will be in a worker thread
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//debugPrint("\(mCTAG).urlSession.task.didCompleteWithError STARTED")
        if error != nil {
            // only perform display tasks upon error
            DispatchQueue.main.async {
                self.activity_indicator.isHidden = true
                self.activity_progress.isHidden = true
                self.showError(prefix: NSLocalizedString("Web Error", comment:""), errorStruct: error!)
            }
            self.cleanupVC()
        }
    }
    
    // convert the dialog to show error results
    private func showError(prefix:String, message:String) {
        textview_results.isHidden = false
        button_cancel_okay.titleLabel?.text = NSLocalizedString("Okay", comment:"")
        textview_results.text = prefix + ":\n" + message
    }
    private func showError(prefix:String, errorStruct:Error) {
        textview_results.isHidden = false
        button_cancel_okay.titleLabel?.text = NSLocalizedString("Okay", comment:"")
        textview_results.text = prefix + ":\n" + AppDelegate.endUserErrorMessage(errorStruct: errorStruct)
    }
}
