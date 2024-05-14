#include <iostream>

class foo
{
    public:
    int val;

    foo(int num)
    {
        val = num;
    }

    foo operator+(foo num)
    {
        std::cout<<"in here";
        return foo(val + num.val);
    }

    int get_val(void)
    {
        return val;
    }
};


int main(void)
{
    foo obj1 = foo(5);
    foo obj2 = foo(2);

    std::cout<<"\n obj1val = "<<obj1.val;

    foo obj3 = obj1+obj2;

    std::cout<<"\noutput"<<obj3.get_val()<<"next"<<obj2.get_val();

    return 0;
}