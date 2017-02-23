# SuperCombinators

A parser combinator framework written in Swift.
SuperCombinators tries to optimise for legibility, and provides a number of ways to combine familiar Cocoa string parsing techniques with the power of parser combinators.

## Example 1: CSV

Here is an example implementation of a CSV parser:

``` Swift
import SuperCombinators

private extension CharacterSet {

    static var stringBody = CharacterSet(charactersIn: "\"").inverted
    static var cellBody = CharacterSet(charactersIn: ",\n").inverted
}

let notQuote = Pattern.characters(in: .stringBody).stringParser
let cellBody = Pattern.characters(in: .cellBody).stringParser

let cell = "\"" & notQuote & "\"" || cellBody

let row = cell.separated(by: ",")
let csv = row.separated(by: "\n")

csv.parseAll("11,\"one\"\n2,\"two\"")
```

1. You can use the familiar CharacterSet to match a prefix of a string
2. Any parser can be transformed into a String parser
3. You can use String literals for efficient definitions of simple matching patterns
4. You can use familiar operators to combine parsers
5. You can easily create a parser that matches repeated elements

The above API using `Parser.separated(by:)` is useful when you don't want to require a separator at the end.
If instead you wanted to require a newline at the end of the file, you could do it like so:

``` Swift
let csv = (row & "\n")+ // At least one line required
```

or

``` Swift
let csv = (row & "\n")* // Empty file accepted
```

Note: the `a.separated(by: b)` syntax is equivalent to `a & (b & a)*.map { [$0] + $1 }`

## Example 2: Simple Calculator

Here is an example implementation of a parser that parses simple arithmetic operations on integers:

``` Swift
import SuperCombinators

let expression = Parser<Int>.recursive { expression -> Parser<Int> in

    // Match all characters in CharacterSet.decimalDigits
    let int = Pattern.characters(in: .decimalDigits)                       
        .stringParser
        .map { Int($0)! }

    let factor = int || "(" & expression & ")"

    // * and / have higher precedence, and should be processed first
    let term = Parser<Int>.recursive { term -> Parser<Int> in              

        let multiply = factor & " * " & term                               
        let divide = factor & " / " & term

        return multiply.map(*)
            || divide.map(/)
            || factor
    }

    let add = term & " + " & expression
    let subtract = term & " - " & expression

    return add.map(+)
        || subtract.map(-)
        || term
}

expression.parseAll("((3 + 3) * 4 - 6) / 2")
expression.parseAll("(3 + 3) * 4 - 6 / 2")

```

The above example shows a few more features of this framework:

1. You can use `map` to transfrom the value that a parser captures
2. A recursive parser that is simple to define, while not leaking memory

## Motivation

At the time of writing, there are already a number of parser combinator libraries written in Swift, with many articles written about them. Why not just use those? First, there is a number of inconveniences with the popular approach of adapting existing patterns from functional programming languages, which have popularised the use of parser combinators. The heavy use of custom operators makes for a very steep learning curve, and a focus on genericity of the type being parsed makes optimising for string parsing difficult. There also seemed to be no libraries where recursive parsers don't form strong memory cycles.

This framework attempts to solve these issues in the following way:

### Operator confusion

There are only two operators declared in this framework:

``` Swift
postfix operator *
postfix operator +
```

The fact that these operators are postfix means that there can be no possible precedence or associativity conflict when combined with other libraries.

The other operators used in this library are native Swift operators, with familiar associativity and precedence rules, that behave about as you would expect without seeing the documentation.

An additional help is the introduction of a `Pattern` class, that matches the prefix of a string, but does not contain any value. This makes ignoring a part of the parsing explicit, allowing Swift to automatically extract the right values when combining parsers.

### Memory leaks

Memory leaks are avoided by adding a private class whose `parse` function does not hold a strong reference to itself encapsulated in a `Parser`.

The implementation can be found in [Recursive.swift](Sources/Recursive.swift)
