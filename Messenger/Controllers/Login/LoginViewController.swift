//
//  LoginViewController.swift
//  Messenger
//
//  Created by Ha Duyen Quang Huy on 25/11/2021.
//

import UIKit

class LoginViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log In"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                               style: .done,
                                                               target: self,
                                                               action:#selector(didTapRegister))

    }
    
    @objc private func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }

}
