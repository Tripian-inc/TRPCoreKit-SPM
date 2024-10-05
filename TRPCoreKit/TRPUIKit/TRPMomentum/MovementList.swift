//
//  MovementList.swift
//  TRPUIKit
//
//  Created by Evren Yaşar on 28.09.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation
import UIKit
class MovementList: UIView, UITableViewDelegate, UITableViewDataSource {
    
    var tb: UITableView?
    
    var cityName: [String] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    func updateData(_ data: [String]) {
        cityName = data
        tb?.reloadData()
    }
    
    func appendData(_ data: [String]) {
        cityName.append(contentsOf: data)
        tb?.reloadData()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        tb = UITableView()
        addSubview(tb!)
        tb?.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        tb?.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tb?.dataSource = self
        tb?.delegate = self
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cityName.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = cityName[indexPath.row]
        cell.textLabel?.textColor = TRPColor.darkGrey
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
}







import UIKit.UIGestureRecognizerSubclass
class InstantPanGestureRecognizer: UIPanGestureRecognizer {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        self.state = .began
    }
    
}

