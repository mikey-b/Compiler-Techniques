# Indexed List
[Godbolt Example Code](https://godbolt.org/z/d6TqEf)

This is an extension to the C style lists which has a pointer held inside the value item, normally called `next`.

This produces a compile time string that can be used as an "indexed" pointer - grouping a set of children. This is done with a (weak) pointer `indexed_next` which points to the next sibling in the same grouping.

This code is demonstration code only.

**Usage**
```cpp
int main(int, char**) {
    // Create the list, with two indexing keys. "test" and "x"
    indexed_list<int, "test"_k, "x"_k> list;

    list.emplace_back("test", 42);
    list.emplace_back("x", 24);
    list.emplace_back("test", 33);

    for(auto& i: test) {
        // ... do something will all elements ...
    }
    
    for(auto& i: test["test"]) {
        // ... do something with only test elements ...
    }

    for(auto& i: test["x"]) {
        // ... do something with only x elements ...
    }

    return 0;
}
```