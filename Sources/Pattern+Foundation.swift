//
//  Pattern+Foundation.swift
//  SuperCombinators
//
//  Created by Alexandre Lopoukhine on 09/02/2017.
//
//

import Foundation

extension Pattern {

    /**
     Matches all unicode characters `characterSet` does not contain.
    */
    public static func characters(notIn characterSet: CharacterSet) -> Pattern {
        return Pattern { text in
            guard !text.isEmpty else { return nil }
            guard let range = text.rangeOfCharacter(from: characterSet) else {
                return text.endIndex
            }
            guard text.startIndex != range.lowerBound else { return nil }
            return range.lowerBound
        }
    }

    /**
     Matches all unicode characters `characterSet` contains.
    */
    public static func characters(in characterSet: CharacterSet) -> Pattern {
        return characters(notIn: characterSet.inverted)
    }

    /**
     Matches a single unicode character whose UnicodeScalars `characterSet` contains.
    */
    public static func character(in characterSet: CharacterSet) -> Pattern {
        return Pattern { text in
            guard !text.isEmpty else { return nil }
            let suffixIndex = text.index(text.startIndex, offsetBy: 1)
            let prefix = text.substring(to: suffixIndex)
            if let _ = prefix.rangeOfCharacter(from: characterSet) {
                return nil
            } else {
                return suffixIndex
            }
        }
    }
}
