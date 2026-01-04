//
//  CoordinatorProtocol.swift
//  Wiserr
//
//  Created by Evren Yaşar on 2021-02-15.
//

import Foundation
import UIKit

//Coordinator yapılarının generic olmasını sağlaar
protocol CoordinatorProtocol: AnyObject {
    
    var navigationController: UINavigationController? {get set}
    
    var childCoordinators: [CoordinatorProtocol] { get set }
    
    //Coordinator ın çalışacağı zaman tetiklenmesi gereken method
    func start()
    
    // Coordinator yaşam döngüsünü bitiridiğinde çağrılılması gereken method.
    // Observer gibi methodlar burada öldürülmeli.
    func finish()
    
}

extension CoordinatorProtocol {
    
    func finish() {
        
    }
    
}
