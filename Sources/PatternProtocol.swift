//
//  PatternProtocol.swift
//  SuperCombinators
//
//  Created by Alexandre Lopoukhine on 10/02/2017.
//
//

postfix operator *
postfix operator +

protocol PatternProtocol: class {

    associatedtype Result

    var parsePrefix: (String) -> Result? { get }

    init(parsePrefix: @escaping (String) -> Result?)

    static func extractSuffixIndex(from result: Result) -> String.Index
    static func result(_ result: Result, with newSuffixIndex: String.Index) -> Result
}

extension PatternProtocol {

    /**
     Captures the string parsed using `self`.
    */
    public var stringParser: Parser<String> {
        return Parser<String> { text in
            guard let result = self.parsePrefix(text) else { return nil }
            let suffixIndex = Self.extractSuffixIndex(from: result)
            return ParseResult<String>(
                value: text.substring(to: suffixIndex),
                suffixIndex: suffixIndex
            )
        }
    }

    /**
     Parses the using the left-hand parser.
     If the result exists, then return that.
     Otherwise, attempt using right-hand pattern.
    */
    public func matches(_ text: String) -> Bool {
        guard let result = parsePrefix(text) else { return false }
        return text.endIndex == Self.extractSuffixIndex(from: result)
    }

    public func or(_ other: Self) -> Self {
        return Self { text in self.parsePrefix(text) ?? other.parsePrefix(text) }
    }

    public static func either(_ patterns: Self...) -> Self {
        return Self { text in
            for pattern in patterns {
                if let result = pattern.parsePrefix(text) { return result }
            }
            return nil
        }
    }
}

extension Parser: PatternProtocol {

    static func extractSuffixIndex(from result: Parser<Value>.Result) -> String.Index {
        return result.suffixIndex
    }

    static func result(_ result: Result, with newSuffixIndex: String.Index) -> Parser<Value>.Result {
        return Result(value: result.value, suffixIndex: newSuffixIndex)
    }
}

extension Pattern: PatternProtocol {

    typealias Result = String.Index

    static func extractSuffixIndex(from result: String.CharacterView.Index) -> String.Index {
        return result
    }

    static func result(_ result: String.CharacterView.Index, with newSuffixIndex: String.Index) -> String.CharacterView.Index {
        return newSuffixIndex
    }
}

extension PatternProtocol {

    func parseSuffix(of text: String, after substringIndex: String.Index) -> Result? {
        let substring = text.substring(from: substringIndex)
        guard let result = parsePrefix(substring) else { return nil }
        let firstSuffixIndex = Self.extractSuffixIndex(from: result)
        let suffixIndex0 = String.UTF16View.Index(firstSuffixIndex, within: substring.utf16)
        let substringPrefixDistance = substring.utf16.distance(from: substring.utf16.startIndex, to: suffixIndex0)
        let substringIndex = String.UTF16View.Index(substringIndex, within: text.utf16)
        let newSuffixIndexUTF16 = text.utf16.index(substringIndex, offsetBy: substringPrefixDistance)
        let newSuffixIndex = newSuffixIndexUTF16.samePosition(in: text) ?? text.endIndex
        return Self.result(result, with: newSuffixIndex)
    }
}
