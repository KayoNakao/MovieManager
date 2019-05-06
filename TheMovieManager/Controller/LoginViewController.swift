//
//  LoginViewController.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginViaWebsiteButton: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        emailTextField.text = ""
        passwordTextField.text = ""
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        
        TMDBClient.getRequestToken(completion: handleRequestTokenResponse(isSuccess:error:))
        //performSegue(withIdentifier: "completeLogin", sender: nil)
    }
    
    @IBAction func loginViaWebsiteTapped() {
        performSegue(withIdentifier: "completeLogin", sender: nil)
    }
    
    func handleRequestTokenResponse(isSuccess: Bool, error: Error?){
        if isSuccess{
            print(TMDBClient.Auth.requestToken)
            DispatchQueue.main.async {
                TMDBClient.login(username: self.emailTextField.text ?? "", password: self.passwordTextField.text ?? "", completion: self.handleLoginResponse(success:error:))
            }
        }
    }
    
    func handleLoginResponse(success:Bool, error:Error?){
        if success{
            print(TMDBClient.Auth.requestToken)
            TMDBClient.createSessionId(requestToken: TMDBClient.Auth.requestToken, completion: handleSessionResponse(success:error:))
        }
    }
    
    func handleSessionResponse(success:Bool, error:Error?){
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "completeLogin", sender: self)
        }
    }
}
