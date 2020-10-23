//
//  String+toString.swift
//  codeclip
//
//  Created by Kevin Unkrich on 10/22/20.
//

import Foundation

extension Date
{
    func toString( dateFormat format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
