//
//  Pattern+Operators.swift
//  SuperCombinators
//
//  Created by Alexandre Lopoukhine on 14/02/2017.
//
//

/**
 Parses the using the left-hand parser. 
 If the result exists, then return that.
 Otherwise, attempt using right-hand pattern.
*/
public func || (lhs: Pattern, rhs: Pattern) -> Pattern {
    return lhs.or(rhs)
}

extension Pattern {

    /**
     Attemps to use `self` `number` times.
    */
    public func count(_ number: Int) -> Pattern {
        precondition(0 <= number, "Can't invoke parser negative number of times")
        return Pattern { text in
            var suffixIndex = text.startIndex

            for _ in 0 ..< number {
                guard let next = self.parseSuffix(of: text, after: suffixIndex) else { return nil }
                suffixIndex = next
                guard suffixIndex != text.endIndex else { break }
            }

            return suffixIndex
        }
    }

    /**
     Attemps to use `self` as many times as possible. Never fails.
    */
    public func zeroOrMore() -> Pattern {
        return Pattern { text in
            var suffixIndex = text.startIndex

            while let next = self.parseSuffix(of: text, after: suffixIndex) {
                suffixIndex = next
                guard suffixIndex != text.endIndex else { break }
            }

            return suffixIndex
        }
    }
    
    /**
     Attemps to use `self` as many times as possible. Fails if there is not at least one match.
    */
    public func oneOrMore() -> Pattern {
        return Pattern { text in
            guard var suffixIndex = self.parse(text) else { return nil }

            while let next = self.parseSuffix(of: text, after: suffixIndex) {
                suffixIndex = next
                guard suffixIndex != text.endIndex else { break }
            }

            return suffixIndex
        }
    }
}

/**
 Attemps to use `self` as many times as possible. Never fails.
*/
public postfix func * (single: Pattern) -> Pattern {
    return single.zeroOrMore()
}

/**
 Attemps to use `self` as many times as possible. Fails if there is not at least one match.
*/
public postfix func + (single: Pattern) -> Pattern {
    return single.oneOrMore()
}
