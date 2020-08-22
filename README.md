# typee

We all love types, right? They allowe us to capture errors early on and make our lifes more available to the rest of th great stuff out there.
Indeed types are neat, and the types we all probably familiar with are the part of the Hindley-Milner type system of simply typed lambda calculus with polymorphisms, but while they definetly provide help, they are not what type systems and mathematical constructivism can offer. Namely, swift's property wrapper allow us to write the programm with more rigorous requirements and thus help us capture more bugs in our code. This library relies on these two constructs:
1. Hoare functions - named after Tony Hoare, these functions allow you to specify preconditions - what your code should be before it gets into function - and postconditions - what your code should be after it gets out of the function. These cheks ensure that invariants are handled properly at type and subtype level.
2. Linear types - gracefully stolen from linear logic and adopted for formal verification, they ensure the exact path of the transition for your types to be taken. For example, a record that describes user can be specified to be mutated only after the name was assigned.
3. Refined types - they are essentially type predicates, and ensure that value of a type meet requirements. For example, a name field in user record may be set to start with capital letter, and be longer than certain amount of character or not contain nonallphabetic symbols.
4. Uniqueness types - you can use them only once, yeap that is all to them.
