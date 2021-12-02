//
//  NewConversationViewController.swift
//  Messenger
//
//  Created by Ha Duyen Quang Huy on 25/11/2021.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    public var completion :(([String: String ]) -> (Void))?

    private let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String: String]]()
    
    private var results = [[String: String]]()
    
    private var hasFetched = false
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for Users..."
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    private let noResultLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "No Results"
        label.textAlignment = .center
        label.textColor = .green
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(noResultLabel)
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        view.backgroundColor = .white
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
        performSelector(onMainThread: #selector(displayKeyboard), with: nil, waitUntilDone: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultLabel.frame = CGRect(x: view.width/4, y: (view.height - 200)/2, width: view.width/2, height: 200)
    }

    @objc func displayKeyboard(){
        searchBar.becomeFirstResponder()
    }
    
    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
}

extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // start conversation
        let targetUserData = results[indexPath.row]
        dismiss(animated: true, completion:{[weak self] in
            self?.completion?(targetUserData)
        })
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = results[indexPath.row]["name"]
        return cell
    }
}

extension NewConversationViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        searchBar.resignFirstResponder()
        results.removeAll()
        spinner.show(in: view)
        
        self.searchUsers(query: text)
        
    }
    
    func searchUsers(query: String) {
        if hasFetched {
            // check if array has firebase results
            // if it does: filter
            filterUsers(with: query)
            
        } else {
            // if not, fetch then filter
            DatabaseManager.shared.getAllUsers(completion: {[weak self] result in
                switch result {
                case .success(let userCollection):
                    self?.hasFetched = true
                    self?.users  = userCollection
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print("Failed to get users: \(error)")
                }
            })
        }
        // if not, fetch the user
        
        // update UI, show user table or show no user label
    }
    
    func filterUsers(with term: String){
        guard hasFetched else {
            return
        }
        
        self.spinner.dismiss(animated: true)
        
        let results: [[String: String]] = self.users.filter({
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        })
        
        self.results = results
        updateUI()
    }
    
    func updateUI() {
        let isEmpty = results.isEmpty
        self.noResultLabel.isHidden = !isEmpty
        self.tableView.isHidden = isEmpty
        if !isEmpty {
            self.tableView.reloadData()
        }
    }
}
