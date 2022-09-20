# Faster Dynamic Test/Cast

![](https://www.redditstatic.com/desktop2x/img/renderTimingPixel.png)

Hi all,

In statically typed languages with subtype polymorphism, a useful tool is the ability to downcast. To take a refence by base* and convert it into a derived*.

API design debates aside, this allows you to access information in the derived that is not available from the base.

It also allows the opportunity to remove the method call indirections in code sections by accessing an instance by its concrete type.

I have seen two implementations of the runtime type test, both were string comparisions. One of those languages was C++, which has publicly accessible information so will use that language as a reference.

**dynamic_cast is slow**

The C++ runtime type test implementation is currently a string comparison. This works because the shorter target type_id will be compared with the longer concrete type_id. If the concrete type_id starts with (prefix) the target, its a successful match. You can see these strings with typeid(class).name().

This is flexible, but slow. There was a cppcon talk from Microsoft categorising vunrabilities (Sorry can't find it again!). The wrong use of static_cast instead of dynamic_cast was mentioned and a noticable % of bugs. I think this slowness cost is a key hurdle to why were making that choice. It is impossible to make a dynamic_cast zero cost, but we can certainly make it cheaper.

**Previous Attempt**

An alternative was already proposed in 2004, https://www.stroustrup.com/fast_dynamic_casting.pdf - Which uses prime factorisation. String comparison is still used today. I can only guess on why there was no movement on this.

ABI breakage might have been one objection. The other two issues with this strategy I can see is the (1) compactness of type_id's, and (2) use of modulus.

*Compactness of type_ids*

The use of multiplied primes, and the fact that most hierarchy's are quite simple and linear results in sparse type_ids. The scheme already uses a nested approach, but the bit pattern's provided could definitely be improved on.

The linked paper has some information on the current scheme (Page 20). "On average, for a hierarchy with 8192 classes, the type ID of a class with 11 ancestors will just fit in a 64-bit integer". I would argue that 8000 classes would be a large C++ project and would cover the majority of C++ projects today, and if required, a fallback to another method would be a solution.

I would also not be surprised if a similar principle but other arthimetic operation could provide the same benefits, but with a more compact type_id. I suspect more cycle-costly, trading-off space when used with over 8000 classes. Or just use 128bit type_ids (We're storing strings at present!)

*Modulus*

A modulus operation is not the fastest. I would need to benchmark to find the break even point, but I would say a string comparsion of a small class hierarchy could still win compared to a modulus.

However, If the class hierachy is known at compile type - We can reduce that modulus to a multiplication. Which is 2-3x faster. This great post outlines this [Faster remainders when the divisor is a constant: beating compilers and libdivide &#8211; Daniel Lemire&#039;s blog](https://lemire.me/blog/2019/02/08/faster-remainders-when-the-divisor-is-a-constant-beating-compilers-and-libdivide/). We only need a divisibility test (n % m == 0). Which can be done with a multiply, subtract 1 and cmp.

**More Optimisations**

- Type id is now an integer. They fit in registers.

- Final Class - If the class is marked as `final`, we can just do a cmp test instead. This optimisation is in the demo code. This is similiar to the string ptr comparison, but you only pay for this when you know it is worthwhile - instead of every time.

- If you have a series of type tests (like with the visitor pattern), and all those classes are `final`, you can use a `switch` instead.

Heres the demo code: [Compiler Explorer](https://godbolt.org/z/qf5sYxq37)

M ✌

**Further Thoughts**

- I'm not sure why the subtract is needed for the divisibility test? Isn't `a <= b - 1` equal to `a < b` ?

- We only need to generate a type_id for classes that are actually dynamically tested.










