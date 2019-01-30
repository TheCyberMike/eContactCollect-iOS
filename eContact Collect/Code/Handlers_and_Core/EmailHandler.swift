//
//  EmailHandler.swift
//  eContact Collect
//
//  Created by Dev on 1/29/19.
//

import Foundation
import MessageUI
import MobileCoreServices

// define the delegate protocol that other portions of the App must use to know the final result of a sent email
public protocol HEM_Delegate {
    func completed_HEM(tagI:Int, tagS:String?, result:EmailHandler.EmailHandlerResults, error:APP_ERROR?)
}

// base handler class for sending emails
public class EmailHandler:NSObject, MFMailComposeViewControllerDelegate {
    // member variables
    public var mEMHstatus_state:HandlerStatusStates = .Unknown
    public var mAppError:APP_ERROR? = nil
    
    // member constants and other static content
    internal var mCTAG:String = "HEM"
    internal var mThrowErrorDomain:String = NSLocalizedString("Email-Handler", comment:"")
    
    public enum EmailHandlerResults: Int {
        case Cancelled = 0, Error = 1, Saved = 2, Sent = 3
    }
    
    // initialization; returns true if initialize fully succeeded;
    // errors are stored via the class members and will already be posted to the error.log;
    // this handler must be mindful that the database initialization may have failed
    public func initialize(method:String) -> Bool {
//debugPrint("\(mCTAG).initialize STARTED")
        // ???
        self.mEMHstatus_state = .Valid
        return true
    }
    
    // first-time setup is needed;
    // this handler must be mindful that if it or the database handler may not have properly initialized that this should be bypassed;
    // errors are stored via the class members and will already be posted to the error.log
    public func firstTimeSetup(method:String) {
//debugPrint("\(mCTAG).firstTimeSetup STARTED")
        // none at this time
    }
    
    // return whether the handler is fully operational
    public func isReady() -> Bool {
        if self.mEMHstatus_state == .Valid { return true }
        return false
    }
    
    // this will not get called during normal App operation, but does get called during Unit and UI Testing
    // perform any shutdown that may be needed
    internal func shutdown() {
        self.mEMHstatus_state = .Unknown
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    // public methods
    /////////////////////////////////////////////////////////////////////////////////////////
    
    // send an email to the developer, optionally including an attachment;
    // initial errors are thrown; email subsystem result success/error is returned via callback
    public func sendEmailToDeveloper(vc:UIViewController, tagI:Int, tagS:String?, delegate:HEM_Delegate?, localizedTitle:String, subject:String?, body:String?, includingAttachment:URL?) throws {
        do {
            try sendEmail(vc: vc, tagI: tagI, tagS: tagS, delegate: delegate, localizedTitle: localizedTitle, to: "theCyberMike@yahoo.com", cc: nil, subject: subject, body: body, includingAttachment: includingAttachment)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).sendEmailToDeveloper")
            throw appError
        } catch { throw error }
    }

    // send an email, optionally including an attachment;
    // initial errors are thrown; email subsystem result success/error is returned via callback
    public func sendEmail(vc:UIViewController, tagI:Int, tagS:String?, delegate:HEM_Delegate?, localizedTitle:String, to:String?, cc:String?, subject:String?, body:String?, includingAttachment:URL?) throws {
        
        // determine the attachment mime type
        var mimeType = "text/plain"
        if includingAttachment != nil {
            let extString = includingAttachment!.pathExtension
            switch extString {
            case "txt":
                mimeType = "text/tab-separated-values"
                break
            case "csv":
                mimeType = "text/csv"
                break
            case "xml":
                mimeType = "text/xml"
                break
            default:
                break
            }
        }
        
        // ???
        // send the email via the iOS Mail App
        do {
            try sendEmailViaAppleMailApp(vc: vc, tagI: tagI, tagS: tagS, delegate: delegate, localizedTitle: localizedTitle, to: to, cc: cc, subject: subject, body: body, includingAttachment: includingAttachment, mimeType: mimeType)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).sendEmail")
            throw appError
        } catch { throw error }
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // private methods
    /////////////////////////////////////////////////////////////////////////////////////////
    
    // send the email using the iOS Mail App
    private func sendEmailViaAppleMailApp(vc:UIViewController, tagI:Int, tagS:String?, delegate:HEM_Delegate?, localizedTitle:String, to:String?, cc:String?, subject:String?, body:String?, includingAttachment:URL?, mimeType:String) throws {
//debugPrint("\(self.mCTAG).sendEmailViaAppleMailApp STARTED")
        
        // build up the needed to/cc arrays
        var emailToArray:[String] = []
        var emailCCArray:[String] = []
        if !(to ?? "").isEmpty {
            emailToArray = to!.components(separatedBy: ",")
        }
        if !(cc ?? "").isEmpty {
            emailCCArray = cc!.components(separatedBy: ",")
        }

        // validate the iOS Mail subsystem
        if !MFMailComposeViewController.canSendMail() {
            throw APP_ERROR(funcName: "\(self.mCTAG).sendEmailViaAppleMailApp", during: "MFMailComposeViewController.canSendMail()", domain: self.mThrowErrorDomain, errorCode: .IOS_EMAIL_SUBSYSTEM_DISABLED, userErrorDetails: nil)
        }
        
        // invoke the iOS Mail compose subsystem
        let mailVC = MFMailComposeViewControllerExt()
        mailVC.mailComposeDelegate = self
        mailVC.tagI = tagI
        mailVC.tagS = tagS
        mailVC.delegateHEM = delegate
        mailVC.title = localizedTitle
        if !(to ?? "").isEmpty { mailVC.setToRecipients(emailToArray) }
        if !(cc ?? "").isEmpty { mailVC.setCcRecipients(emailCCArray) }
        if !(subject ?? "").isEmpty { mailVC.setSubject(subject!) }
        if !(body ?? "").isEmpty { mailVC.setMessageBody(body!, isHTML: false) }
        if includingAttachment != nil {
            let fileName:String = includingAttachment!.lastPathComponent
            let fileData:Data = FileManager.default.contents(atPath: includingAttachment!.path)!
            mailVC.addAttachmentData(fileData, mimeType: mimeType, fileName: fileName)
        }
        vc.present(mailVC, animated: true, completion: nil)
    }
    
    // callback from iOS Mail App indicating rejection or success
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
//debugPrint("\(self.mCTAG).mailComposeController.didFinishWith for \(controller.title!)")
        if let controllerHEM:MFMailComposeViewControllerExt = controller as? MFMailComposeViewControllerExt {
            if controllerHEM.delegateHEM != nil {
                var errorHEM:APP_ERROR? = nil
                var resultHEM:EmailHandler.EmailHandlerResults
                if error != nil {
                    errorHEM = APP_ERROR(funcName: "\(self.mCTAG).mailComposeController.didFinishWith", domain: self.mThrowErrorDomain, error: error!, errorCode: .IOS_EMAIL_SUBSYSTEM_ERROR, userErrorDetails: nil)
                    resultHEM = .Error
                } else {
                    switch result {
                    case .cancelled:
                        resultHEM = .Cancelled
                        break
                    case .failed:
                        resultHEM = .Error
                        break
                    case .saved:
                        resultHEM = .Saved
                        break
                    case .sent:
                        resultHEM = .Sent
                        break
                    }
                }
                controllerHEM.delegateHEM!.completed_HEM(tagI: controllerHEM.tagI, tagS: controllerHEM.tagS, result: resultHEM, error: errorHEM)
                controller.dismiss(animated: true, completion: nil)
                return
            }
        }
        if error != nil {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).mailComposeController.didFinishWith.noDelegate", errorStruct: error!, extra: nil)
        }
        controller.dismiss(animated: true, completion: nil)
    }
}

// extend the MFMailComposeViewController class to store some needed callback members
public class MFMailComposeViewControllerExt:MFMailComposeViewController {
    // preset members by invoker
    var tagI:Int = 0
    var tagS:String? = nil
    var delegateHEM:HEM_Delegate? = nil
}
