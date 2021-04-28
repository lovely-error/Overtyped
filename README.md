# Overtyped
> To conceive of types as of something designating only a set of possible values an entity can be is correct;
> the erroneous assumption is one that dictates this not to be considered about the whole programm.
> *-- Me to Myself*

To construct programms with some typing discipline being involved in the process is efficacious. You are a human and thus you make mistakes; thankfully to us all, a computer can aid you in preventing errors to contagiously propagate through your programm. Many techniques are possible, and you are familiar with at least one - to annotate expressions with tags. While useful, this solution is partial - you can only expect certain variables to be one of the possible values, and certainly, you cannot put constraints on how components of your programms interact. This package is an attempt to remediate the aforementioned issue. It affords six constructions to specify how variables must evolve during the execution.

1. Hoare functions - allow you to specify what your code should be before it gets into a function (this is named precondition check) - and what your code should be after it gets out of the function (this is named postcondition check).
```
import Typee

@Function var viewTransformer =  { (view: View) -> () in
    view = HorizontalView().append(subview: view)
}
let argument = (view: Image(named: "dog.png"))
$viewTransformer.addPostcondition {$0.size.width == argument.size.width}
viewTransformer(argument)
```

2. Linear types - set the range of uses of values
```
@Linear(range: ..1) var someProperty: Int = 123
let a = someProperty \\ ok
let b = someProperty \\ NOPE!
```

3. Refinements - allows to set conditions on values
```
@Constrained(by: {$0 > 0 && $0 < 150}) var age: Int = 19
age = 1_000_000 //fatal error!
```

4. Uniques - you can use them only once.
```
@Unique var rareMaterial: Antimatter = ...
use(rareMaterial) //ok
useOnceMore(rareMaterial) //opps! its gone...
```

5. Stateful values - which are represented by a complete deterministic state machine.
```
@Stateful(configuration: {
    let emptyString = State(
        name: "empty string",
        predicate: { ($0 as? String)?.isEmpty ?? false })
    let nonEmptyString = State(
        name: "non empty string",
        predicate: { !(($0 as? String)?.isEmpty ?? true)})
        
    emptyString =>> nonEmptyString =>> emptyString
    
    return TransitionGraph(initialState: emptyString)
}())
var emptyHalfOfTheTime = ""
emptyHalfOfTheTime = "!"
emptyHalfOfTheTime = ""
emptyHalfOfTheTime = "!"
emptyHalfOfTheTime = "Screw it.." //obvious error
```

6. Modal values - allow you to listen to conditions and perform checks. It is a less strict version of state machine.
```
struct T {
   @Modal var name: String = "L"
   init() {
      _name.nessecairily(
         after: {$0.count == 0},
         ensure: {$0.count > 0 ? .allOk : .violation},
         description: {_ in """
         After string become empty, it must later be replaced with another
         nonempty string before performing any other operations
         """},
         discard: .onCondition({$0.hasPrefix("sme")}))
      _name.nessecairily(
         after: {$0.hasPrefix("Lo")},
         ensure: {$0.hasSuffix("ki") ? .allOk : .violation},
         description: { _ in "After name start to have Lo it must always end with ki"})
   }
}
var test = T()
test.name = ""
//test.name = "" //would be an error 
test.name = "smeshariki"
test.name = "" //not an error anymore. Guard is lifted.
```
