# SuperCombinators

A parser combinator framework written in Swift. SuperCombinators tries to optimise for legibility, and provides a number of ways to combine familiar Cocoa string parsing techniques with the power of parser combinators.

## Parser Combinators

Parser combinators are composable parsers. In general, they traverse some prefix of a sequence, and return the value extracted and a way to carry on parsing the rest of the sequence.

## Why use SuperCombinators

There are already a few open source parser combinator libraries in Swift. Why use this one?

1. Integration of familiar Cocoa parsing approaches such as using regular expressions and `CharacterSet`s
2. Minimal use of custom operators
3. Recursive parsing implementation without memory leaks

## Framework Overview

### Types

There are two types that implement the concept of a parser, `Parser` and `Pattern`. Conceptually, `Pattern` only checks whether the prefix of a string is formatted correctly, whereas `Parser` also extracts some value from the prefix. This differentiation at the type level enhances readability and helps Swift infer the right thing while keeping code concise.

### Operators

#### Binary operators

`||`, `&` and `&&` are overloaded in this library to provide a concise way to combine parsers and patterns. They mirror existing methods `.or`, `.and` and `also` on instances of `Pattern` and `Parser`. The Swift type system allows us to define these on all reasonable combinations of `Pattern` and `Parser`, and expect a reasonable result.

Conceptually, the **or** operator attempts to use the result of the left operand and, if that fails, attempts to use the result of the right operand. Naturally, the types of the inputs have to be the same, and are the same as the resulting output.

The **and** operator attempts to parse the string first using the left operand, then, on the remainder of the string, using the right operand, succeeding only if both succeed.

The **also** operator is useful when combining together more than two parsers. Instead of nesting 2-tuples, by using the `&` operator, you can use the `&&` operator to create a parser of a flat tuple of the appropriate number of elements.

#### Custom Postfix Operators

This framework defines two custom operators: `postfix +` and `postfix *`

These mirror the familiar regex quantifiers, and transform a `Parser<Value>` into a `Parser<[Value]>`, parsing using the original as many times as possible and failing on an empty input in the case of the `+` operator.

## Example: Parsing Floats

> You can find this example and more in the Playground by cloning this project and opening the XCode Workspace.

Parsing floating point numbers, such as you might see in Swift, is a good place to start. Below is an implementation of a very basic floating point number parser that extracts the value of the number as a `Double`, if the format is correct.

The aim is to correctly parse floating point numbers written in the following formats:

1. `"123"`
2. `"123.456"`
3. `".456"`
4. `"-123"`
5. `"-123.456"`
6. `"-.456"`

As you can see, this is a rather tedious way of defining all the possible strings that you might like to accept, so it is usually useful to first define what you would like to parse in terms of some sort of a grammar. We can do this informally:

A floating point number is:

* an optional minus
* one or two of the following
 * some digits
 * a `.` followed by some digits.

This gives us enough structure to define the building blocks of our parser.

``` Swift
let digits = Pattern.characters(in: .decimalDigits)     // 1
let uint = digits.stringParser.map { Int($0)! }         // 2, 3
let ufloat0 = uint.map(Double.init)                     // 4

let ufloat1 = ("." & ufloat0).map { float -> Double in  // 5 - 8
    guard 0 < float else { return 0 }                   // 9
    let power = log10(float).rounded(.down) + 1
    return float / pow(10, power)
}

let ufloat = (ufloat0.optional & ufloat1.optional)      // 10, 11
    .test { nil != $0 || nil != $1 }                    // 12
    .map { ($0 ?? 0) + ($1 ?? 0) }                      // 13

let float = ufloat || ("-" & ufloat).map { -$0 }        // 14
```

Let's go through this example.

1. `digits: Pattern` is created from a `CharacterSet`. This pattern greedily consumes all unicode codepoints from this set, if there are any.
2. a `Parser<String>` is created from digits using the `.stringParser` computed variable that returns the `String` traversed
3. this parser is immediately mapped using the built-in optional `Int` initializer to `uint: Parser<Int>`
4. we create `float0: Parser<Double>`
5. a `Pattern` is created using a String literal from `"."`
6. it is then combined with `ufloat0` using the `&` operator, to give a `Parser<Double>`
7. the result of this parser is transformed using `.map`
8. the return type of the closure is necessary for Swift to infer the type of the resulting `Parser`
9. the value of the fraction part is calculated
10. the two components are converted to `Parser<Double?>` by using the `.optional` computed variable
11. they are combined using the `&` operator into a `Parser<(Double?, Double?)>`
11. by using `.test` we can test the extracted value, making the parser fail if the predicate does not hold
12. in this case, one of the two fields has to be non-nil
13. add the two fields of the tuple to give us the unsigned result
14. we add support for the optional minus sign in front of the floating point
