
** Milestone 3 - DSI export fee on Indonesian Ferronickel
** Assumption: 1 commodity, 1 period, competitive exporters
** Using 2025 export data; elasticities and fees are assumed
** X = exports (million tons); P = USD per ton of product
** Revenue, cost, and profit are in million USD


* ----------------------------------------
** 1. Input Values and Elasticities
* ----------------------------------------

scalar
    vbar "2025 export value [million USD]" /16385.06673/
    xbar "2025 export quantity [million tons]" /11.5556/
    pbar "average export price [USD/ton]"
    e_r  "residual demand elasticity [unitless]" /-2/
    e_s  "supply elasticity [unitless]" /1/;

* Average price from 2025 export data
pbar = vbar / xbar;

display vbar, xbar, pbar, e_r, e_s;


* ----------------------------------------
** 2. Determine Inverse Residual Demand and Marginal Cost
* ----------------------------------------

* P(X) = a + bX
* MC(X) = c + dX

scalar
    a "demand intercept"
    b "demand slope"
    c "marginal cost intercept"
    d "marginal cost slope";

* Calibrate using price, quantity, and elasticities
b = pbar / (e_r* xbar);
a = pbar - b * xbar;

d = pbar / (e_s * xbar);
c = pbar - d * xbar;

display a, b, c, d;


* ----------------------------------------
** 3. Direct Selling - No Fee
* ----------------------------------------

* Competitive market, where P = MC

positive variable X "export quantity";
variable social_surplus "total market surplus or equilibrium potential, not national welfare";

equation eq_surplus;

eq_surplus..
    social_surplus =e=
      a*X + 0.5*b*sqr(X)
    - c*X - 0.5*d*sqr(X);

model direct_selling /eq_surplus/;

X.l = xbar;

solve direct_selling using qcp maximizing social_surplus;

* Calculate price and exporter surplus
scalar
    price_base
    exporter_surplus_base;

price_base = a + b*X.l;
exporter_surplus_base = price_base*X.l
                     - (c*X.l + 0.5*d*sqr(X.l));

display X.l, price_base, exporter_surplus_base;



* ----------------------------------------
** 4. Direct Selling - With DSI Fee
* ----------------------------------------

* Exporters pay the fee to DSI for export monitoring and verification
* DSI revenue is not the same as DSI profit

scalar fee "DSI fee [USD/ton]" /5/;

equation eq_fee;

eq_fee..
    social_surplus =e=
      a*X + 0.5*b*sqr(X)
    - c*X - 0.5*d*sqr(X)
    - fee*X;

model with_dsi_fee /eq_fee/;

X.l = xbar;

solve with_dsi_fee using qcp maximizing social_surplus;

* Calculate price, exporter surplus, and DSI revenue
scalar
    price_fee
    net_price_fee
    exporter_surplus_fee
    dsi_revenue_fee
    check_eq;

price_fee = a + b*X.l;
net_price_fee = price_fee - fee;

exporter_surplus_fee = net_price_fee*X.l
                     - (c*X.l + 0.5*d*sqr(X.l));

dsi_revenue_fee = fee*X.l;

* Check if P - fee = MC
check_eq = net_price_fee - (c + d*X.l);

display X.l, price_fee, net_price_fee,
        exporter_surplus_fee, dsi_revenue_fee, check_eq;



* ----------------------------------------
** 5. Fee Sensitivity Analysis
* ----------------------------------------

* Test different DSI fees using the same demand and supply curves

set s "fee scenarios"
    /f0, f0p5, f1, f3, f5, f7, f9/;

parameter fee_value(s) "DSI fee [USD/ton]"
    /f0   0
     f0p5 0.5
     f1   1
     f3   3
     f5   5
     f7   7
     f9   9/;

parameter fee_results(s,*) "results for each fee scenario";

loop(s,

    fee = fee_value(s);
    X.l = xbar;

    solve with_dsi_fee using qcp maximizing social_surplus;

    price_fee = a + b*X.l;
    net_price_fee = price_fee - fee;

    exporter_surplus_fee = net_price_fee*X.l
                         - (c*X.l + 0.5*d*sqr(X.l));

    dsi_revenue_fee = fee*X.l;

    fee_results(s,"fee") = fee;
    fee_results(s,"exports_Mt") = X.l;
    fee_results(s,"price_USD_t") = price_fee;
    fee_results(s,"net_price_USD_t") = net_price_fee;
    fee_results(s,"exporter_surplus_USDm") = exporter_surplus_fee;
    fee_results(s,"dsi_revenue_USDm") = dsi_revenue_fee;

*Changes relative to the no-fee baseline
    fee_results(s,"export_change_pct") = 100*(X.l/xbar - 1);
    fee_results(s,"buyer_price_change") = price_fee - price_base;
    fee_results(s,"exporter_net_price_change") =
        net_price_fee - price_base;

);

display fee_results;




* ----------------------------------------
** 6. Demand Elasticity Sensitivity Analysis
* ----------------------------------------

* Keep DSI fee at USD 5/ton
* Test different foreign demand elasticities

fee = 5;

set t "elasticity scenarios"
    /e1, e2, e4/;

parameter elastic_value(t) "residual demand elasticity"
    /e1 -1
     e2 -2
     e4 -4/;

parameter elastic_results(t,*) "elasticity sensitivity results";

loop(t,

    e_r = elastic_value(t);

*Recalibrate demand for each elasticity
    b = pbar / (e_r * xbar);
    a = pbar - b*xbar;

    X.l = xbar;

    solve with_dsi_fee using qcp maximizing social_surplus;

    price_fee = a + b*X.l;
    net_price_fee = price_fee - fee;

    exporter_surplus_fee = net_price_fee*X.l
                         - (c*X.l + 0.5*d*sqr(X.l));

    dsi_revenue_fee = fee*X.l;

    elastic_results(t,"elasticity") = e_r;
    elastic_results(t,"exports_Mt") = X.l;
    elastic_results(t,"buyer_price_USD_t") = price_fee;
    elastic_results(t,"net_exporter_USD_t") = net_price_fee;
    elastic_results(t,"exporter_surplus_USDm") = exporter_surplus_fee;
    elastic_results(t,"dsi_revenue_USDm") = dsi_revenue_fee;
    elastic_results(t,"export_change_pct") = 100*(X.l/xbar - 1);
    elastic_results(t,"buyer_price_change") = price_fee - pbar;

);

display elastic_results;

* Restore the main elasticity assumption
e_r = -2;
b = pbar / (e_r * xbar);
a = pbar - b*xbar;



* ----------------------------------------
** 7. DSI Operating Margin Sensitivity
* ----------------------------------------

* Assume DSI operating margins of 25%, 50%, and 75%
* Use the DSI revenue from the USD 5/ton fee scenario

set m "DSI margin scenarios"
    /m25, m50, m75/;

parameter margin_value(m) "DSI operating margin"
    /m25 0.25
     m50 0.50
     m75 0.75/;

parameter margin_results(m,*) "DSI operating cost and profit";

scalar revenue_f5 "DSI revenue at USD 5/ton";

revenue_f5 = fee_results("f5","dsi_revenue_USDm");

loop(m,

    margin_results(m,"margin_pct") = 100*margin_value(m);
    margin_results(m,"revenue_USDm") = revenue_f5;
    margin_results(m,"operating_cost_USDm") =
        revenue_f5*(1 - margin_value(m));
    margin_results(m,"operating_profit_USDm") =
        revenue_f5*margin_value(m);

);

display margin_results;



$exit

