//
//  ViewController.swift
//  AllergyInsider
//
//  Created by 임현진 on 2021/08/12.
//

import UIKit
import GoogleSignIn
import Firebase

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }

   // GIDSignIn.sharedInstance()?.presentingViewController = self
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        print("User email: \(user.profile?.email ?? "No email")")
       }
    
    @IBAction func btnGoogleGIDSignIn(_ sender: GIDSignInButton) {
            
            guard let clientID = FirebaseApp.app()?.options.clientID else { return }
            
            // Create Google Sign In configuration object.
            let config = GIDConfiguration(clientID: clientID)
            
            // Start the sign in flow!
            GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [unowned self] user, error in
                
                if let error = error {
                    // ...
                    print("Google Login error = \(error)")
                    return
                }
                
                guard
                    let authentication = user?.authentication,
                    let idToken = authentication.idToken
                else {
                    
                    return
                }
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                               accessToken: authentication.accessToken)
                
                // ...
                
                print("clientID = \(clientID)")
                print("config = \(config)")
                print("authentication = \(authentication)")
                print("idToken = \(idToken)")
                print("credential = \(credential)")
                
                
                // MARK: Google Login - Firebase에 인증, 이전 단계에서 만든 인증 사용자 인증 정보를 사용하여 Firebase 로그인 프로세스를 완료
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        let authError = error as NSError
                        if authError.code == AuthErrorCode.secondFactorRequired.rawValue {  // MARK: if isMFAEnabled, - error
                            // The user is a multi-factor user. Second factor challenge is required.
                            let resolver = authError
                                .userInfo[AuthErrorUserInfoMultiFactorResolverKey] as! MultiFactorResolver
                            var displayNameString = ""
                            for tmpFactorInfo in resolver.hints {
                                displayNameString += tmpFactorInfo.displayName ?? ""
                                displayNameString += " "
                            }
                            self.showTextInputPrompt(
                                withMessage: "Select factor to sign in\n\(displayNameString)",
                                completionBlock: { userPressedOK, displayName in
                                    var selectedHint: PhoneMultiFactorInfo?
                                    for tmpFactorInfo in resolver.hints {
                                        if displayName == tmpFactorInfo.displayName {
                                            selectedHint = tmpFactorInfo as? PhoneMultiFactorInfo
                                        }
                                    }
                                    PhoneAuthProvider.provider()
                                        .verifyPhoneNumber(with: selectedHint!, uiDelegate: nil,
                                                           multiFactorSession: resolver
                                                            .session) { verificationID, error in
                                            if error != nil {
                                                print(
                                                    "Multi factor start sign in failed. Error: \(error.debugDescription)"
                                                )
                                            } else {
                                                self.showTextInputPrompt(
                                                    withMessage: "Verification code for \(selectedHint?.displayName ?? "")",
                                                    completionBlock: { userPressedOK, verificationCode in
                                                        let credential: PhoneAuthCredential? = PhoneAuthProvider.provider()
                                                            .credential(withVerificationID: verificationID!,
                                                                        verificationCode: verificationCode!)
                                                        let assertion: MultiFactorAssertion? = PhoneMultiFactorGenerator
                                                            .assertion(with: credential!)
                                                        resolver.resolveSignIn(with: assertion!) { authResult, error in
                                                            if error != nil {
                                                                print(
                                                                    "Multi factor finanlize sign in failed. Error: \(error.debugDescription)"
                                                                )
                                                            } else {
                                                                self.navigationController?.popViewController(animated: true)
                                                            }
                                                        }
                                                    }
                                                )
                                            }
                                        }
                                }
                            )
                        } else {
                            self.showMessagePrompt(error.localizedDescription)
                            return
                        }
                        // ...
                        return
                    }
                    // User is signed in
                    // ...
                    
                    // MARK: Google Login - 사용자 프로필 가져오기
                    let user = Auth.auth().currentUser
                    if let user = user {
                        // The user's ID, unique to the Firebase project.
                        // Do NOT use this value to authenticate with your backend server,
                        // if you have one. Use getTokenWithCompletion:completion: instead.
                        let uid = user.uid
                        let email = user.email
                        let photoURL = user.photoURL
                        
                        
                        
                        var multiFactorString = "MultiFactor: "
                        for info in user.multiFactor.enrolledFactors {
                            multiFactorString += info.displayName ?? "[DispayName]"
                            multiFactorString += " "
                        }
                        // ...
                        print("uid = \(uid)")
                        print("email = \(String(describing: email))")
                        print("photoURL = \(String(describing: photoURL))")
                        
                        // MARK: Google Login - user email 받아 UserDefault에 등록
    //                    if email != nil {
    //                        currentUserEmail = email!
    //                    }else{
    //                        //currentUserEmail = "방문자"
    //                    }
                        
                        guard let email = email else {
                            return
                        }
                        myUserDefaults.set(email, forKey: "userEmail")
                        
                        performSegue(withIdentifier: "loginSegue", sender: self)
                        
    //                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    //                    let destinationVC = storyboard.instantiateViewController(withIdentifier: "MyPageViewController") as! MyPageViewController
    //                    self.present(destinationVC, animated: true, completion: nil)
                    }
                    
                    // MARK: Google Login - user email 받아 UserDefault에 등록
    //                myUserDefaults.set(currentUserEmail, forKey: "userEmail")
    //                print("currentUserEmail = \(myUserDefaults.string(forKey: "userEmail"))")
                    
                    
                    // MARK: Email UserDefault를 Label에 띄우기
                    //self.infoLabel.text = myUserDefaults.string(forKey: "userEmail")
                    
                    // MARK: Google Login - 로그인 성공 후 마이페이지 띄우기
    //                let storyboard = UIStoryboard(name: "Main", bundle: nil)
    //                let destinationVC = storyboard.instantiateViewController(withIdentifier: "MyPageViewController") as! MyPageViewController
    //                self.present(destinationVC, animated: true, completion: nil)
                    
                }
                
                //            // MARK: Google Login - user email 받아 UserDefault에 등록
                //            myUserDefaults.set(currentUserEmail, forKey: "userEmail")
                //            print("currentUserEmail = \(myUserDefaults.string(forKey: "userEmail"))")
                //
                //
                //            // MARK: Email UserDefault를 Label에 띄우기
                //            self.infoLabel.text = myUserDefaults.string(forKey: "userEmail")
                //
                //            // MARK: Google Login - 로그인 성공 후 마이페이지 띄우기
                //            let storyboard = UIStoryboard(name: "JyKim", bundle: nil)
                //            let destinationVC = storyboard.instantiateViewController(withIdentifier: "MyPageViewController") as! MyPageViewController
                //            self.present(destinationVC, animated: true, completion: nil)
                
                
            }
            
        }
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            self.userEmailInsert(myUserDefaults.string(forKey: "userEmail")!)
            
            // MARK: userNumberQuery 실행
            self.userNumberQuery()
            Util.shared.id = usernoUserDefaults.string(forKey: "userno") ?? "0"
            print("id is \(Util.shared.id)")
        }
        
        // MARK: Google Login - Firebase에 인증 시 사용
        func showTextInputPrompt(withMessage message: String,
                                 completionBlock: @escaping ((Bool, String?) -> Void)) {
            let prompt = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completionBlock(false, nil)
            }
            weak var weakPrompt = prompt
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                guard let text = weakPrompt?.textFields?.first?.text else { return }
                completionBlock(true, text)
            }
            prompt.addTextField(configurationHandler: nil)
            prompt.addAction(cancelAction)
            prompt.addAction(okAction)
            present(prompt, animated: true, completion: nil)
        }
        
        // MARK: Google Login - Firebase에 인증 시 사용
        func showMessagePrompt(_ message: String) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: false, completion: nil)
        }
        
        
        // MARK: 로그인 공통 - user email 받아 DB에 입력
        func userEmailInsert(_ id: String) {
            print("id to insert in userEmailInsert func = \(id)")
            if myUserDefaults.string(forKey: "userEmail") != "방문자" {
    //            let id = myUserDefaults.string(forKey: "userEmail")
                
                let userInsertModel = UserInsertModel()
                let result = userInsertModel.insertItems(id: id)
                
                if result{
                    print("입력 완료 - email : \(String(describing: myUserDefaults.string(forKey: "userEmail")))")
        //            let resultAlert = UIAlertController(title: "완료", message: "입력이 되었습니다!", preferredStyle: .alert)
        //            let onAction = UIAlertAction(title: "OK", style: .default, handler: { ACTION in
        //                self.navigationController?.popViewController(animated: true)
        //            })
        //
        //            resultAlert.addAction(onAction)
        //            present(resultAlert, animated: true, completion: nil)
                    
                }else{
                    print("에러 발생 - email : \(String(describing: myUserDefaults.string(forKey: "userEmail")))")
        //            let resultAlert = UIAlertController(title: "실패", message: "에러가 발생 되었습니다!", preferredStyle: .alert)
        //            let onAction = UIAlertAction(title: "OK", style: .default, handler: { ACTION in
        //                self.navigationController?.popViewController(animated: true)
        //            })
        //
        //            resultAlert.addAction(onAction)
        //            present(resultAlert, animated: true, completion: nil)
                }
                
            } else{
                return
            }

        }
        
        // MARK: 로그인 공통 - user email(id) 이용해 DB에서 user number(userno) 가져와 user default에 등록
        func userNumberQuery() {
            print("id to download userno in userNumberQuery func = \(String(describing: myUserDefaults.string(forKey: "userEmail")))")
            let queryModel = UserQueryModel()
            queryModel.downloadItems(id: myUserDefaults.string(forKey: "userEmail")!)
            
        }

        
        
    }

}
