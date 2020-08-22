import XCTest
@testable import typee

protocol Lifestep {}
final class typeeTests: XCTestCase {
    func testFunction() {
        //Trivial test to a custom function
        let lowercaser = Function { () -> String in
            return "ABCDEFGH".lowercased()
        }
        XCTAssert((lowercaser <<! ()) == "abcdefgh")
        
        
        let repeater = Function { (count: Int, value: String) -> String in
            return String(repeating: value, count: count)
        }
        XCTAssert((repeater <<! (count: 8, value: "a")) == "aaaaaaaa")
        
        
        let multiplier = Function { (value: Int) -> Int in
            return value * Int.random(in: 1...0)
        }
        multiplier.afterCall({_ in print("happens after call to this function")})
        multiplier.beforeCall({_ in print ("happens after call")})
        multiplier.addPostcondition({$0 > 0})
        multiplier.addPostcondition({$0 > 0})
    }
    
    
    struct Innocence: Lifestep {}
    struct Adulthood: Lifestep {}
    struct Maturity: Lifestep {}
    func testWrappers () {
        //the order of assignment is crucial here.
        //any other ordering would ruin it all.
        //fun thing to point out is that I cannot test code
        //with XCTAssert constructs, because this code fails
        //with fatalErrors().
        
        struct Test {
            @Constrained(by: {$0 > 0 && $0 < 150})
            var age: Int = 19
            
            @Linear([
                {$0 is Innocence},
                {$0 is Adulthood},
                {$0 is Maturity}])
            var transition: Lifestep = Innocence()
            
            @Unique
            var secret: String = "The Kennedy was killed by ..."
        }
        var test = Test()
        test.transition = Adulthood()
        test.transition = Maturity()
        test.age = Int.random(in: 1..<150)
        
        _ = test.secret
        XCTAssert(test.$secret.isEmpty == true)
    }

    
}
