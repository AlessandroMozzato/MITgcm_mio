%mw = 0.18 + 9.2*10^(-8)*x + 0.9*log(x);

x = linspace(0,10000,1000);

plot(x, 0.18 + 9.2*10^(-8)*x + 0.9*log(x))

syms x
f(x) = 0.18 + 9.2*10^(-8)*x + 0.9*log(x);
g = finverse(f) ;

g(x)

plot(7.2,g(7.2))