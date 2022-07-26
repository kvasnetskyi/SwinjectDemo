# SwinjectDemo

You can find more information in the [presentation](https://github.com/kvasnetskyi/SwinjectDemo/files/9146989/Swinject.Report.pdf) and [video](https://chiswdevelopment.sharepoint.com/:v:/s/iOSteam/EUvSU4qw0LdFt4_1cT_0S2ABm8TlrmZUesyjAkLbu9YHRg?e=B6Lrwf).

1. [Dependency injection](#dependency-injection)
2. [Circular Dependencies](#circular-dependencies)
3. [Dependency injection: Pros and cons](#pros-and-cons)
4. [DI Libraries and Frameworks](#di-libraries-and-frameworks)
5. [Swinject](#swinject)
6. [Object Scope](#object-scope)
7. [Thread Safety](#thread-safety)
8. [Container Hierarchy](#container-hierarchy)
9. [Assembly & Assembler](#assembly-&-assembler)

# Dependency injection
Dependency injection is a design pattern in which all the dependencies of an object are passed externally. This pattern is one implementation of the **Inversion of Control** principle.

**Inversion of Control** – is a kind of abstract principle for writing weakly coupled code. The essence of which is that each component of the system should be as isolated as possible from the others, not relying on the details of a particular implementation of the other components in its operation.

The DI concept invites us to create and store all necessary data in a container, and to transfer it to dependent objects.

There are several ways of introducing dependency:
- **Interface injection** – this is implemented by using protocols. Objects subscribe to one interface that accepts the dependencies you want, then the injector injects those dependencies based on the interface.

- **Constructor injection** – this is the most popular type of injection, where we pass all the dependencies to the object through the initializer.

- **Property injection** – in this injection method, we declare the dependencies inside the object as optional properties, and inject them into the object after it is initialized.

- **Method injection** – this works in the same way as Property injection, but creates a method that sets the needed dependency into a private property.

Property and Method injection have the same disadvantage - the object is initialised, but it has no dependencies. In some cases this can lead to unexpected situations, as the object is incomplete after initialisation. But, at the same time, it is sometimes necessary, namely when there are **cyclical dependencies**.

# Circular Dependencies
These are dependencies of instances that depend on each other.

```swift
class A {
    private weak var b: B!
    
    init(b: B) { // Constructor injection
        self.b = b
    }
}

class B {
    private let a: A
    
    init(a: A) { // Constructor injection
        self.a = a
    }
}
```

It is at a time like this that we will need the Property injection.
```swift
class A {
    weak var b: B!
}

class B {
    private let a: A
    
    init(a: A) { // Constructor injection
        self.a = a
    }
}

let a = A()
let b = B(a: A)
a.b = b // Property injection
```

# Pros and cons
Dependency injection has more pros than cons.
- **Explicit object dependencies** – this gives better control over the complexity of the object, and eradicates the possibility of problems with implicit dependencies.

- **External object dependencies** – this allows object creation code to be separated from the business logic, improving segregation of responsibility.

- **Flexible dependencies** – it is possible to substitute an object for another. Objects become easy to test.

- **Reduces coupling** – this is what the Inversion of Control principle requires.

- **Simplifies object reuse**

But there are also disadvantages:
- **More code**
- **More time wasted**

# DI Libraries and Frameworks
If a project contains many different services that depend on other services - use the library to make life easier for yourself and for other developers who will then deal with these dependencies.

Roughly speaking, DI libraries or frameworks for IOS development can be classified into [reflection-based](#reflection) and [code generation-based](#code-generation).

The most popular types of DI libraries/frameworks for IOS development are reflection-based. And the most popular of them is [Swinject](#swinject).

## Reflection
These are libraries where the container works according to the dictionary principle – one key per object.

**Pros**: Easy to understand.
**Cons**: All errors occur in runtime.

## Code generation
Libraries that generate code to inject dependencies based on protocols or attributes (library dependent).

**Pros**: Compile time safety.
**Cons**: Difficult to understand.

# Swinject
A lightweight DI framework for Swift. The idea is to register a dependency in a container, and resolve it.

Registering a dependency is done using the `register` method, with a mandatory parameter of the dependency type and a block that stores a description of the object's creation. The block takes a `resolver` from which you can get another dependency and different types of arguments to pass when trying to resolve a dependency.

Also, register can contain the optional parameter name, a unique name for the dependency which is used to identify the dependency among others of the same type. 
```swift
/// Register & resolve service with type
container.register(AppConfiguration.self) { resolver in
    AppConfigurationImpl()
}

let _ = container.resolve(AppConfiguration.self)

/// Register & resolve service with type and name
container.register(AppConfiguration.self, name: "Some name") { resolver in
    AppConfigurationImpl()
}

let _ = container.resolve(AppConfiguration.self, name: "Some name")

/// Register & resolve service with type, name and argument
container.register(AppConfiguration.self, name: "Some name 2") { resolver, argument in
    AppConfigurationImpl(bundle: argument)
}

let _ = container.resolve (AppConfiguration.self, name: "Some name 2", argument: Bundle.main)
```

Swinject works on a dictionary principle, where the key is the `ServiceKey` type and the object is `ServiceEntryProtocol`. 
```swift
internal struct ServiceKey {
    internal let serviceType: Any.Type
    internal let argumentsType: Any.Type
    internal let name: String?
    internal let option: ServiceKeyOption? // Used for SwinjectStoryboard or other extensions.

    internal init(
        serviceType: Any.Type,
        argumentsType: Any.Type,
        name: String? = nil,
        option: ServiceKeyOption? = nil
    ) {
        self.serviceType = serviceType
        self.argumentsType = argumentsType
        self.name = name
        self.option = option
    }
}
```
- serviceType - type of dependency to be registered.
- argumentsType - types of arguments to pass when resolving a dependency.
- name - a unique name for the dependency which is used to identify it among other dependencies of the same type.

This structure is needed to get a unique hash for different dependencies. 

```swift
internal protocol ServiceEntryProtocol: AnyObject {
    func describeWithKey(_ serviceKey: ServiceKey) -> String
    var objectScope: ObjectScopeProtocol { get }
    var storage: InstanceStorage { get }
    var factory: FunctionType { get }
    var initCompleted: (FunctionType)? { get }
    var serviceType: Any.Type { get }
}
```
- describeWithKey - method which generates a description of the registered dependency for the logger. 
- objectScope - object which describes how dependency is shared in the system. You can read more about [it](#object-scope).
- storage - where the dependency is stored. The objectScope is responsible for the creation of storage. 
- factory - is the block which is responsible for creating the dependency. 
- initCompleted - the block, which is called after the completion of object initialization. It is used for property and method injection to resolve [circular dependencies](#circular-dependencies). 

More information can be found in the [documentation](https://github.com/Swinject/Swinject/blob/master/Documentation/DIContainer.md).

# Object Scope
A description of how the dependency is shared in the system. It is represented as an enum.

Swinject provides four types of Object Scope:
- **Transient** – each time a dependency is resolved, the Swinject will return a new object.
- **Graph** – each time a dependency is resolved directly, Swinject will return a new object, just like `transient`. However, if the object is resolved within the register clause, the object can be reused in the context of the graph creation.
- **Container** – Swinject creates an object the first time a resolve is attempted, and then reuses this object every time. Great for replacing the Singleton pattern.
- **Weak** – works in the same way as `Container`, but the object can be deleted from memory if there is not at least one strong reference to it.

The `inObjectScope` method is used to use the correct Object Scope. The default is `graph` Object Scope.
```swift
container.register(AppConfiguration.self) { _ in
    AppConfigurationImpl()
}
.inObjectScope(.container)
```

More information can be found in the [documentation](https://github.com/Swinject/Swinject/blob/master/Documentation/ObjectScopes.md).

# Thread Safety
Containers in Swinject, are **not thread-safety**. But Swinject provides the functionality to resolve dependencies in parallel.

It is worth remembering that **we must always register the dependency from the same thread.**
```swift
let container = Container()

func threadSafeContainerTest() {
    container.register (AppConfiguration.self) {_ in AppConfigurationImpl() }
    
    let threadSafeContainer = container.synchronize()
    
    // Do something concurrently
    for _ in 0..<10 {
        DispatchQueue.global().async {
            let _ = threadSafeContainer.resolve(AppConfiguration.self)
        }
    }
}
```

More information can be found in the [documentation](https://github.com/Swinject/Swinject/blob/master/Documentation/ThreadSafety.md).

# Container Hierarchy
Containers, like classes, can inherit from each other.

A container hierarchy is a tree of containers for sharing registered dependencies.
```swift
let parentContainer = Container()
lazy var childContainer = Container(parent: parentContainer)
    
func parentContainerTest(){
    parentContainer.register(AppConfiguration.self) { in
        AppConfigurationImpl()
    }

    let service = childContainer.resolve(AppConfiguration.self)
    print(service != nil) // prints "true"
}
```

More information can be found in the [documentation](https://github.com/Swinject/Swinject/blob/master/Documentation/ContainerHierarchy.md).

# Assembly & Assembler
This functionality allows you to break down your dependency registration into separate modules.

The functionality contains two component parts:
- **Assembly** – this is the protocol to which the shared container is provided. The shared container will contain all registered dependencies from each Assembly.
- **Assembler** – responsible for managing Assembly instances and the container. It stores an array of Assembly instances that will use the shared container.

**You must hold a strong reference to the Assembler otherwise the Container will be deallocated along with your assembler.**

```swift
// Service Assembly
class ServiceAssembly: Assembly {
    func assemble(container: Container) {
        container.register(ServiceA.self) { resolver in
            return ServiceA()
        }
        
        container.register(ServiceB.self) { resolver in
            return ServiceB()
        }
    }
}

// Manager Assembly
class ManagerAssembly: Assembly {
    func assemble(container: Container) {
        container.register(ManagerA.self) { resolver in
            return ManagerA(
                resolver.resolve(ServiceA.self)!
            )
        }
        
        container.register(ManagerB.self) { resolver in
            return ManagerB(
                resolver.resolve(ServiceB.self)!
            )
        }
    }
}

// Assembler
let assembler = Assembler([
    ServiceAssembly(),
    ManagerAssembly()
])

// Resolve manager from Manager Assembly via assembler
func resolveTest() {
    let _ = assembler.resolver.resolve(ManagerB.self)
}
```

Also, you can lazy load an assembly to the assembler using the apply method:
```swift
func addAssemblyTest() {
    assembler.apply(assemblies: [
        LazyLoadedAssembly()
    ])
}
```

More information can be found in the [documentation](https://github.com/Swinject/Swinject/blob/master/Documentation/Assembler.md).

Developed By
------------

* Kvasnetskyi Artem, Kosyi Vlad, CHI Software

License
--------

Copyright 2022 CHI Software.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
