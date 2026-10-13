** Milestone 2 - Direct selling versus "DSI" an Indonesian Centralized export desk on Ferronickel
** Assumption: 1 commodity, 1 period, and unit are still illustrative 
** X = exports; where price is monetary units per quantity unit


* ----------------------------------------
** 1. Input Values and Elasticities 
* ----------------------------------------

scalar 
    pbar "export price [money/unit]" /100/
    xbar "export quantity [unit]" /100/
    e_r  "residual demand elasticity [unitless]" /-2/
    e_s  "supply elasticity [unitless]" /1/;


* ----------------------------------------
** 2. Determine inverse residual demand and marginal cost 
* ----------------------------------------
* Price = a + b*X 
* MC = c + d*X

scalar a, b, c, d;
b = pbar / (e_r * xbar);
a = pbar - b * xbar; 
d = pbar / (e_s * xbar);
c = pbar - d * xbar;

display a, b, c, d;


* ----------------------------------------
** 3. Variables and objective equations 
* ----------------------------------------

positive variable X "Indonesian exports" ; 

variable
    social_surplus "surplus objective for competitive equilibrium"
    profit "joint Indonesian producer/export surplus" ;

equation social_surplus_max, profit_max;
* Direct-selling benchmark:
* producers/exporters act as price takers.
* The objective is area under residual demand minus total resource cost.
* Maximizing this objective gives P = MC when X > 0.
* It is used as a computational device to recover the competitive equilibrium.
* Its objective value is not interpreted as Indonesian or global welfare.

social_surplus_max.. social_surplus =e= a*X + b*X*X/2 - c*X - d*X*X/2 ; 

* Centralized export desk:
* the centralized desk acts as a price maker.
* It maximizes export revenue minus total resource cost.
* Maximizing this objective gives MR = MC when X > 0.
* Profit represents joint producer/export surplus, not DSI corporate profit.

profit_max.. profit =e= (a+b*X)*X - c*X - d*X*X/2 ;

* where each model contrains only its own objective function, and the other is flexible to adjust.

model direct_selling /social_surplus_max/ ;
model centralized_desk /profit_max/ ;

parameter rep "comparable results for both regimes" ;

* ----------------------------------------
** 4. Simulate the direct-selling regime, where the Indonesian producers/exporters are price takers and maximize social surplus.
* ----------------------------------------

solve direct_selling using qcp maximizing social_surplus;
rep("direct_selling","exports") = X.l ;
rep("direct_selling","price") = a + b*X.l ;
rep("direct_selling","revenue") = (a + b*X.l) * X.l ;
rep("direct_selling","cost") = c*X.l + d*X.l*X.l/2;
rep("direct_selling","producer_surplus") = rep("direct_selling","revenue") - rep("direct_selling","cost") ;

display rep;

* ----------------------------------------
** 5. Simulate the centralized desk regime, where the Indonesian producers/exporters are price setters and maximize joint profit.
* ----------------------------------------

solve centralized_desk using qcp maximizing profit;
rep("centralized_desk","exports") = X.l ;
rep("centralized_desk","price") = a + b*X.l ;
rep("centralized_desk","revenue") = (a + b*X.l) * X.l ;
rep("centralized_desk","cost") = c*X.l + d*X.l*X.l/2;
rep("centralized_desk","producer_surplus") = rep("centralized_desk","revenue") - rep("centralized_desk","cost") ;  

display rep;

