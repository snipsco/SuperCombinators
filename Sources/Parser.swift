//
//  Parser.swift
//  SuperCombinators
//
//  Created by Alexandre Lopoukhine on 09/02/2017.
//
//

/**
 Contains the semantics and end index of a prefix of a string.
*/
public struct ParseResult<Value> {

    public let value: Value
    public let suffixIndex: String.Index

    public init(value: Value, suffixIndex: String.Index) {
        self.value = value
        self.suffixIndex = suffixIndex
    }
}

/**
 Parses a prefix of a string, returning the prefix's end index and value on success.
*/
public final class Parser<Value> {

    public typealias Result = ParseResult<Value>

    /**
     Parses a prefix of a string, returning the prefix's end index and value on success.
    */
    public let parsePrefix: (String) -> Result?

    public init(parsePrefix: @escaping (String) -> Result?) {
        self.parsePrefix = parsePrefix
    }

    /**
     Parses a prefix of a string, returning the string's value only if it exists for the whole string.
     */
    public func parse(_ text: String) -> Value? {
        guard let result = parsePrefix(text), text.endIndex == result.suffixIndex else { return nil }
        return result.value
    }
}

extension Parser {

    /**
     Creates a `Parser` that parses an empty prefix and returns the specified value.
    */
    public static func pure(_ value: Value) -> Parser {
        return Parser { text in Result(value: value, suffixIndex: text.startIndex) }
    }

    /**
     Creates a `Parser` that always succeeds, giving the result of `self.parse` if it exists.
    */
    public var optional: Parser<Value?> {
        return Parser<Value?> { text in
            let result = self.parsePrefix(text)
            return ParseResult<Value?>(
                value: result?.value,
                suffixIndex: result?.suffixIndex ?? text.startIndex
            )
        }
    }

    /**
     Creates a `Parser` that parses the same prefix as `self`, and contains the transformed value.
    */
    public func map<NewValue>(_ transform: @escaping (Value) -> NewValue) -> Parser<NewValue> {
        return Parser<NewValue> { text in
            guard let result = self.parsePrefix(text) else { return nil }
            return ParseResult<NewValue>(
                value: transform(result.value),
                suffixIndex: result.suffixIndex
            )
        }
    }

    /**
     Creates a `Parser` that 
     1. parses the same prefix as `self`
     2. creates a new parser using `transform`
     3. parses the prefix of the newly created suffix using the new parser
    */
    public func flatMap<NewValue>(_ transform: @escaping (Value) -> Parser<NewValue>) -> Parser<NewValue> {
        return Parser<NewValue> { text in
            guard let r0 = self.parsePrefix(text) else { return nil }
            return transform(r0.value).parseSuffix(of: text, after: r0.suffixIndex)
        }
    }

    /**
     Returns the result of 'self.parse' if the extracted value passes the `test`.
    */
    public func test(_ test: @escaping (Value) -> Bool) -> Parser {
        return Parser { characters in
            guard let result = self.parsePrefix(characters), test(result.value) else { return nil }
            return result
        }
    }
}

// MARK: Apply

/**
 Parses the text first using the left parser, then the right, and calls the value of the right-hand result on the value of the left-hand result.
*/
public func / <A, B>(lhs: Parser<A>, rhs: Parser<(A) -> B>) -> Parser<B> {
    return lhs.and(rhs).map { $0.1($0.0) }
}

/**
 Parses the text first using the left parser, then the right, and calls the value of the left-hand result on the value of the right-hand result.
*/
public func / <A, B>(lhs: Parser<(A) -> B>, rhs: Parser<A>) -> Parser<B> {
    return lhs.and(rhs).map { $0.0($0.1) }
}
