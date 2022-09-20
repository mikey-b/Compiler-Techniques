#include <cstdint>
#include <cstdio>
#include <type_traits>

// Primes: 2,3,5,7,11,13,17,19,23,29,31
enum class prime_type_id_table: uint32_t {
    animal = 2,
    food = 3,
        mammal = animal * 5,
            aardvark = mammal * 13,
            hamster = mammal * 17,

        bird = animal * 7,
            chicken = bird * 13 * food,
            falcon = bird * 17,

        fish = animal * 11,
            minnows = fish * 13,
            salmon = fish * 17 * food,
    

};


consteval uint64_t compute(prime_type_id_table t) {
    uint32_t d = static_cast<uint32_t>(t);
    return 1 + UINT64_C(0xffffffffffffffff) / d;
}

enum class global_type_table: uint64_t {
    animal = compute(prime_type_id_table::animal),
    mammal = compute(prime_type_id_table::mammal),
    bird = compute(prime_type_id_table::bird),
    fish = compute(prime_type_id_table::fish),
    aardvark = compute(prime_type_id_table::aardvark),
    hamster = compute(prime_type_id_table::hamster),
    chicken = compute(prime_type_id_table::chicken),
    falcon = compute(prime_type_id_table::falcon),
    minnows = compute(prime_type_id_table::minnows),
    salmon = compute(prime_type_id_table::salmon),
    food = compute(prime_type_id_table::food),
};

bool is(prime_type_id_table _this, global_type_table oneOfThese) {
    return static_cast<uint32_t>(_this) * static_cast<uint64_t>(oneOfThese) <= static_cast<uint64_t>(oneOfThese) - 1;
}

class animal {
 public:
    static inline auto type_id = global_type_table::animal;

    prime_type_id_table my_type;
};

class mammal: public animal {
 public:
    static inline auto type_id = global_type_table::mammal;
};

class aardvark: public mammal {
 public:
    static inline auto type_id = global_type_table::aardvark;
 
    aardvark() {
        my_type = prime_type_id_table::aardvark;
    }   
};

// NOTE: Remove FINAL to see the other dynamic_cast implementatation.
class hamster final: public mammal {
 public:
    // If class is made FINAL, we can remove type_id and just have prime_type_id. You never need both.
    static inline auto type_id = global_type_table::hamster;
    static inline auto prime_type_id = prime_type_id_table::hamster;

 
    hamster() {
        my_type = prime_type_id_table::hamster;
    }    
};

template<class T, class U>
T prime_dynamic_cast(U original) {
    using target_type = typename std::remove_pointer<T>::type;

    // For FINAL classes, we can just do a cmp
    if constexpr (std::is_final<target_type>::value) {
        if ( original->my_type == target_type::prime_type_id ) {
            return static_cast<T>(original);
        }
    } else {
        if (is(original->my_type, target_type::type_id)) {
            return static_cast<T>(original);
        }
    }
    return nullptr;
}


int main() {
// === is() type tests ===
/*
    printf("Chicken is a fish %d\n", is(prime_type_id_table::chicken, global_type_table::fish));
    printf("Chicken is a bird %d\n", is(prime_type_id_table::chicken, global_type_table::bird));
    printf("Chicken is food %d\n", is(prime_type_id_table::chicken, global_type_table::food));
*/

// === Dynamic cast tests ===
    //animal* test = new aardvark();
    animal* test = new hamster();

    if (auto r = prime_dynamic_cast<hamster*>(test)) {
        printf("We have a hamster\n");
    } else {
        printf("This is not a hamster\n");
    }
}

