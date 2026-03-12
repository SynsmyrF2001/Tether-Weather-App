//
//  UIApplication+Extension.swift
//  Tether_iOS
//
//  Created by Ferguson Sam Forgue on 11/29/23.
//

import UIKit

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
