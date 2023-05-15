#include <array>
#include <utility>
#include <cstddef>

#ifndef NDEBUG
#include <stdexcept>
#include <iostream>

template<typename T, T... ints>
void print_sequence(std::integer_sequence<T, ints...> int_seq)
{
    std::cout << "The sequence of size " << int_seq.size() << ": ";
    ((std::cout << ints << ' '),...);
    std::cout << '\n';
}

#endif // NDEBUG

struct hashkey_t {
	size_t v = 0;

	consteval hashkey_t(char const * input) {
		size_t hash = sizeof(size_t) == 8 ? 0xcbf29ce484222325 : 0x811c9dc5;
		const size_t prime = sizeof(size_t) == 8 ? 0x00000100000001b3 : 0x01000193;

		while (*input) {
			hash ^= static_cast<size_t>(*input);
			hash *= prime;
			++input;
		}

		v = hash;
	}

	consteval operator size_t() const { return v; }
};

template<std::size_t N>
struct lit_hashkey_t
{
	size_t v = 0;

	consteval lit_hashkey_t( char const(&pp)[N] )
	{
		size_t hash = sizeof(size_t) == 8 ? 0xcbf29ce484222325 : 0x811c9dc5;
		const size_t prime = sizeof(size_t) == 8 ? 0x00000100000001b3 : 0x01000193;

		for(decltype(N) i = 0; i < N - 1; i++) {
			hash ^= static_cast<size_t>(pp[i]);
			hash *= prime;
		}

		v = hash;
	};
};

template<lit_hashkey_t A>
constexpr auto operator"" _k() {
	return std::integral_constant<size_t, A.v>{};
}

template<typename node_t, size_t ...Keys>
class indexed_list {

	static consteval auto index_builder() {
		using T = std::integer_sequence<size_t, Keys...>;

		return std::make_pair(
			[](hashkey_t key) constexpr noexcept -> size_t {
				auto arr = []<typename T, T... ints>(std::integer_sequence<T, ints...> ) {
					return std::array<size_t, sizeof...(ints)>{ ints... };
				}(T{});

				for(decltype(arr.size()) i = 0; i < arr.size(); i++) {
					if (arr[i] == key.v) return i + 1;
				}

	#ifndef NDEBUG
				print_sequence(T{});
				throw std::invalid_argument("Index Not Found!");
	#else
				return 0; // 0 is an error result.
	#endif
			},
			sizeof...(Keys) + 1
		);
	}

	struct list_element {
		// Contains the sibling link, and the sibling indexed link (A node can only exist in one index list)
		std::array<list_element*,2> next{nullptr};
		node_t data;

		template<typename ...Args>
		list_element(Args&&... args) {
			data = node_t(std::forward<Args>(args)...);
		}

		node_t& operator*() { return data; }
	};

public:

	struct Index_Itr_Struct {
		struct Index_Iterator {
			using iterator_category = std::forward_iterator_tag;
			using difference_type   = std::ptrdiff_t;
			using value_type        = list_element;
			using pointer           = list_element*;
			using reference         = list_element&;

			Index_Iterator(pointer ptr) : m_ptr(ptr) {}

			reference operator*() const { return *m_ptr; }
			pointer operator->() { return m_ptr; }
			Index_Iterator& operator++() {
				m_ptr = m_ptr->next[1];
				return *this;
			}
			Index_Iterator operator++(int) { Index_Iterator tmp = *this; ++(*this); return tmp; }
			friend bool operator== (const Index_Iterator& a, const Index_Iterator& b) { return a.m_ptr == b.m_ptr; };
			friend bool operator!= (const Index_Iterator& a, const Index_Iterator& b) { return a.m_ptr != b.m_ptr; };
		private:
			pointer m_ptr;
		};

        Index_Iterator begin() { return Index_Iterator(m_ptr2); }
        Index_Iterator end() { return Index_Iterator(nullptr); }
        Index_Itr_Struct(list_element* p): m_ptr2(p) {}
         private:
            list_element* m_ptr2;
    };

	struct Children_Iterator {
        using iterator_category = std::forward_iterator_tag;
        using difference_type   = std::ptrdiff_t;
        using value_type        = list_element;
        using pointer           = list_element*;
        using reference         = list_element&;

        Children_Iterator(pointer ptr) : m_ptr(ptr) {}

        reference operator*() const { return *m_ptr; }
        pointer operator->() { return m_ptr; }
        Children_Iterator& operator++() {
        	m_ptr = m_ptr->next[0];
        	return *this;
		}
        Children_Iterator operator++(int) { Children_Iterator tmp = *this; ++(*this); return tmp; }
        friend bool operator== (const Children_Iterator& a, const Children_Iterator& b) { return a.m_ptr == b.m_ptr; };
        friend bool operator!= (const Children_Iterator& a, const Children_Iterator& b) { return a.m_ptr != b.m_ptr; };
    private:
        pointer m_ptr;
    };

    static constexpr auto offsets = index_builder();
    std::array<list_element*, offsets.second> head{nullptr};
    std::array<list_element*, offsets.second> tail{nullptr};

    Children_Iterator begin() { return Children_Iterator(head[0]); }
    Children_Iterator end() { return Children_Iterator(nullptr); }

    Index_Itr_Struct operator[](hashkey_t l) const {
        size_t idx = offsets.first(l);
        return Index_Itr_Struct(head[idx]);
    }

    template<typename ...Args>
    auto unindexed_emplace_back(Args&&... args) {
        auto tmp = new list_element(std::forward<Args>(args)...);

        if (head[0] == nullptr) {
            head[0] = tmp;
        } else {
            tail[0]->next[0] = tmp;
        }
        tail[0] = tmp;

        return tmp;
    }

    template<typename ...Args>
    auto emplace_back(hashkey_t l, Args&&... args) {
        size_t idx = offsets.first(l);

        auto tmp = unindexed_emplace_back(std::forward<Args>(args)...);

        if (head[idx] == nullptr) {
            head[idx] = tmp;
        } else {
            tail[idx]->next[1] = tmp;
        }
        tail[idx] = tmp;

        return tmp;
    }

    ~indexed_list() {
        delete (head[0]);
    }
};


#include <cstdio>


int main(int, char**) {
    indexed_list<int, "test"_k, "x"_k> test;

    test.emplace_back("test", 42);
    test.emplace_back("x", 24);
    test.emplace_back("test", 33);



    int z = 0;
    for(auto& i: test) {
        printf("'ForEach' Indexed Child #%d: Ptr is: %p - ", z, static_cast<void*>(&i) );
        printf("Value = %d\n", *i);
        z+=1;
    }

    z = 0;
    for(auto& i: test["test"]) {
        printf("'ForEach test' Indexed Child #%d: Ptr is: %p - ", z, static_cast<void*>(&i) );
        printf("Value = %d\n", *i);
        z+=1;
    }

    z = 0;
    for(auto& i: test["x"]) {
        printf("'ForEach x' Indexed Child #%d: Ptr is: %p - ", z, static_cast<void*>(&i) );
        printf("Value = %d\n", *i);
        z+=1;
    }

    return 0;
}
