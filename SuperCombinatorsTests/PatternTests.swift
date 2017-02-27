//
//  PatternTests.swift
//  SuperCombinators
//
//  Created by Alexandre Lopoukhine on 23/02/2017.
//
//

import Foundation
import XCTest
@testable import SuperCombinators

class PatternTests: XCTestCase {

    func testEmpty() {
        XCTAssert(Pattern.empty.matches(""))
    }

    func testSimple() {
        let a: Pattern = "a"
        let b = Pattern(prefix: "b")

        XCTAssert(a.matches("a"))
        XCTAssert(b.matches("b"))

        XCTAssert((a & b).matches("ab"))

        XCTAssert((a || b).matches("a"))
        XCTAssert((a || b).matches("b"))

        XCTAssertFalse(a.matches("c"))
        XCTAssertFalse(b.matches("c"))
        XCTAssertFalse((a & b).matches("c"))
        XCTAssertFalse((a || b).matches("c"))
    }

    func testRecursive() {
        let bracketed = Pattern.recursive { bracketed in
            let single = Pattern.recursive { single in
                return "(" & single & ")" || "()"
            }
            return single+ || "(" & bracketed & ")"
        }

        XCTAssertFalse(bracketed.matches(""))
        XCTAssertFalse(bracketed.matches("("))
        XCTAssertFalse(bracketed.matches(")"))
        XCTAssertFalse(bracketed.matches("())"))
        XCTAssertFalse(bracketed.matches("(()"))

        XCTAssert(bracketed.matches("()"))
        XCTAssert(bracketed.matches("(())"))
        XCTAssert(bracketed.matches("()()"))
        XCTAssert(bracketed.matches("(()())"))
        XCTAssert(bracketed.matches("(())(())()"))
    }
    }
}
