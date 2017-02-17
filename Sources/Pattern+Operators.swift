//
//  Pattern+Operators.swift
//  SuperCombinators
//
//  Created by Alexandre Lopoukhine on 14/02/2017.
//
//

public func || (lhs: Pattern, rhs: Pattern) -> Pattern {
    return lhs.or(rhs)
}

extension Pattern {

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

public postfix func * (single: Pattern) -> Pattern {
    return single.zeroOrMore()
}

public postfix func + (single: Pattern) -> Pattern {
    return single.oneOrMore()
}
