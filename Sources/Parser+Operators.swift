//
//  Parser+Operators.swift
//  SuperCombinators
//
//  Created by Alexandre Lopoukhine on 09/02/2017.
//
//
//

/**
 Parses the using the left-hand parser.
 If the result exists, then return that.
 Otherwise, attempt using right-hand parser.
*/
public func || <Value>(lhs: Parser<Value>, rhs: Parser<Value>) -> Parser<Value> {
    return lhs.or(rhs)
}

extension Parser {

    /**
     Attemps to use `self` `number` times.
    */
    public func count(_ number: Int) -> Parser<[Value]> {
        precondition(0 <= number, "Can't invoke parser negative number of times")
        return Parser<[Value]> { text in
            var values = [Value]()
            var suffixIndex = text.startIndex

            for _ in 0 ..< number {
                guard let result = self.parseSuffix(of: text, after: suffixIndex) else { return nil }
                values.append(result.value)
                suffixIndex = result.suffixIndex
                guard suffixIndex != text.endIndex else { break }
            }

            return ParseResult<[Value]>(
                value: values,
                suffixIndex: suffixIndex
            )
        }
    }

    /**
     Attemps to use `self` as many times as possible. Never fails.
    */
    public func zeroOrMore() -> Parser<[Value]> {
        return Parser<[Value]> { text in
            var values = [Value]()
            var suffixIndex = text.startIndex

            while let next = self.parseSuffix(of: text, after: suffixIndex) {
                values.append(next.value)
                suffixIndex = next.suffixIndex
                guard suffixIndex != text.endIndex else { break }
            }

            return ParseResult<[Value]>(
                value: values,
                suffixIndex: suffixIndex
            )
        }
    }

    /**
     Attemps to use `self` as many times as possible. Fails if there is not at least one match.
    */
    public func oneOrMore() -> Parser<[Value]> {
        return Parser<[Value]> { text in
            guard let first = self.parse(text) else { return nil }

            var values = [first.value]
            var suffixIndex = first.suffixIndex

            while let next = self.parseSuffix(of: text, after: suffixIndex) {
                values.append(next.value)
                suffixIndex = next.suffixIndex
                guard suffixIndex != text.endIndex else { break }
            }

            return ParseResult<[Value]>(value: values, suffixIndex: suffixIndex)
        }
    }
}

/**
 Attemps to use `self` as many times as possible. Never fails.
*/
public postfix func * <Value>(single: Parser<Value>) -> Parser<[Value]> {
    return single.zeroOrMore()
}

/**
 Attemps to use `self` as many times as possible. Fails if there is not at least one match.
*/
public postfix func + <Value>(single: Parser<Value>) -> Parser<[Value]> {
    return single.oneOrMore()
}
