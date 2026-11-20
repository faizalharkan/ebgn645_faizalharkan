
** Milestone 3 - DSI export fee on Indonesian Ferronickel
** Assumption: 1 commodity, 1 period, competitive exporters
** Using 2025 export data; elasticities and fees are assumed
** X = exports (million tons); P = USD per ton of product
** Revenue, cost, and profit are in million USD
** version 2



* ----------------------------------------
** 1. Input Values and Elasticities
* ----------------------------------------

scalar
    vbar "2025 export value [million USD]" /16385.06673/
    xbar "2025 export quantity [million tons]" /11.5556/
    pbar "average export price [USD/ton]"
    e_r  "residual demand elasticity [unitless]" /-2/
    e_s  "supply elasticity [unitless]" /1/;

* Average price from 2025 export data (WITS)
pbar = vbar / xbar;

display vbar, xbar, pbar, e_r, e_s;



* ----------------------------------------
** 2A. Determine Inverse Residual Demand and Marginal Cost
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
** 2B. Two Producer Types - Cost Calibration
* ----------------------------------------

* Two representative NPI producer types, adopted from S&P Capital IQ Pro for Indonesian Nickel Producers identified producing FeNi/NPI (HS: 720260) in 2025
* Cash costs are illustrative estimates based on 2025 producer data and callibrated based on reported grade Ni in FeNi/NPI production on 8 smelters as an initial sample for model purposes. 
*The two producer types are assumed to be "low cost" and "high cost" producers, with equal shares of the 2025 export quantity. The marginal cost functions are linear and calibrated to match the assumed average cash costs at the baseline export quantities.
* All quantities are in million tons of product

set i "producer types"
    /low, high/;

parameter
    share(i)      "assumed baseline export share"
    ac_target(i)  "average cash cost [USD/ton product]"
    qbar(i)       "baseline exports by producer [million tons]"
    c_type(i)     "marginal cost intercept"
    d_type(i)     "marginal cost slope"
    mc_check(i)   "marginal cost at baseline"
    ac_check(i)   "average cost at baseline";

* Initial assumptions
share("low")  = 0.50;
share("high") = 0.50;

ac_target("low")  = 1150;
ac_target("high") = 1330;

* Allocate baseline exports
qbar(i) = xbar * share(i);

* Calibrate linear marginal cost for each producer
* MC_i = c_i + d_i * q_i
* AC_i = c_i + 0.5 * d_i * q_i

d_type(i) = 2 * (pbar - ac_target(i)) / qbar(i);
c_type(i) = pbar - d_type(i) * qbar(i);

* Check calibration at baseline
mc_check(i) = c_type(i) + d_type(i) * qbar(i);
ac_check(i) = c_type(i) + 0.5 * d_type(i) * qbar(i);

display share, ac_target, qbar,
        c_type, d_type, mc_check, ac_check;



* ----------------------------------------
** 3. Direct Selling - No Fee
* ----------------------------------------

* Competitive market, where P = MC

positive variable X "export quantity";
variable social_surplus "total market surplus";

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



* ----------------------------------------
** 8. Two Producer Types - Baseline Equilibrium
* ----------------------------------------

* Both producers face the same export market price
* Each producer has a different marginal cost function
* No DSI fee in this first test

positive variable Q2(i) "exports by producer type [million tons]";
variable obj_two "competitive equilibrium potential";

equation eq_obj_two;

eq_obj_two..
    obj_two =e=
      a*sum(i,Q2(i))
    + 0.5*b*sqr(sum(i,Q2(i)))
    - sum(i, c_type(i)*Q2(i)
           + 0.5*d_type(i)*sqr(Q2(i)));

model two_type_base /eq_obj_two/;

* Initialize exports at calibrated baseline
Q2.l(i) = qbar(i);

solve two_type_base using qcp maximizing obj_two;

* Calculate equilibrium outcomes
scalar
    exports_two
    price_two
    quantity_gap_two
    price_gap_two;

parameter
    mc_two(i) "marginal cost by type"
    eq_gap_two(i) "price minus marginal cost";

exports_two = sum(i,Q2.l(i));
price_two   = a + b*exports_two;

mc_two(i) = c_type(i) + d_type(i)*Q2.l(i);
eq_gap_two(i) = price_two - mc_two(i);

* Check against observed WITS benchmark
quantity_gap_two = exports_two - xbar;
price_gap_two = price_two - pbar;

display Q2.l, exports_two, price_two,
        mc_two, eq_gap_two,
        quantity_gap_two, price_gap_two;



* ----------------------------------------
** 9. Two Producer Types - With DSI Fee
* ----------------------------------------

* Both producer types pay the same DSI fee
* Fee is USD per ton of exported NPI

fee = 5;

equation eq_obj_two_fee;

eq_obj_two_fee..
    obj_two =e=
      a*sum(i,Q2(i))
    + 0.5*b*sqr(sum(i,Q2(i)))
    - sum(i, c_type(i)*Q2(i)
           + 0.5*d_type(i)*sqr(Q2(i)))
    - fee*sum(i,Q2(i));

model two_type_fee /eq_obj_two_fee/;

* Start from the calibrated baseline
Q2.l(i) = qbar(i);

solve two_type_fee using qcp maximizing obj_two;

* Calculate market outcomes
scalar
    exports_two_fee
    price_two_fee
    net_price_two_fee
    dsi_revenue_two_fee;

parameter
    q_fee_two(i)             "exports by producer [Mt]"
    mc_fee_two(i)            "marginal cost [USD/ton]"
    eq_gap_fee_two(i)        "net price minus marginal cost"
    exporter_surplus_two(i)  "producer surplus [million USD]"
    export_change_two(i)    "export change from baseline [%]";

exports_two_fee = sum(i,Q2.l(i));

price_two_fee = a + b*exports_two_fee;

net_price_two_fee = price_two_fee - fee;

dsi_revenue_two_fee = fee*exports_two_fee;

* Producer-specific results
q_fee_two(i) = Q2.l(i);

mc_fee_two(i) = c_type(i) + d_type(i)*Q2.l(i);

eq_gap_fee_two(i) = net_price_two_fee - mc_fee_two(i);

exporter_surplus_two(i) =
    net_price_two_fee*Q2.l(i)
    - (c_type(i)*Q2.l(i)
    + 0.5*d_type(i)*sqr(Q2.l(i)));

export_change_two(i) =
    100*(Q2.l(i)/qbar(i) - 1);

display q_fee_two, exports_two_fee,
        price_two_fee, net_price_two_fee,
        dsi_revenue_two_fee,
        mc_fee_two, eq_gap_fee_two,
        exporter_surplus_two, export_change_two;



* ----------------------------------------
** 10. Two Producer Types - Fee Sensitivity
* ----------------------------------------

* Small fees: policy scenarios
* Large fees: hypothetical stress tests

set u "two-type fee scenarios"
    /f0, f0p5, f1, f3, f5, f7, f9,
     f50, f100, f200, f400, f600, f650, f800/;

parameter fee_test(u) "DSI fee [USD/ton]"
    /f0   0
     f0p5 0.5
     f1   1
     f3   3
     f5   5
     f7   7
     f9   9
     f50  50
     f100 100
     f200 200
     f400 400
     f600 600
     f650 650
     f800 800/;

parameter
    results_two(u,*)      "market results"
    exports_type(u,i)    "exports by type [Mt]"
    surplus_type(u,i)    "producer surplus [million USD]"
    kkt_check(u,i)       "equilibrium condition violation";

loop(u,

    fee = fee_test(u);

    Q2.l(i) = qbar(i);

    solve two_type_fee using qcp maximizing obj_two;

    exports_two_fee = sum(i,Q2.l(i));
    price_two_fee = a + b*exports_two_fee;
    net_price_two_fee = price_two_fee - fee;

* Market-level results
    results_two(u,"fee") = fee;
    results_two(u,"exports_Mt") = exports_two_fee;
    results_two(u,"buyer_price") = price_two_fee;
    results_two(u,"net_price") = net_price_two_fee;
    results_two(u,"DSI_revenue") = fee*exports_two_fee;

    results_two(u,"export_change_pct") =
        100*(exports_two_fee/xbar - 1);

    results_two(u,"model_status") = two_type_fee.modelstat;
    results_two(u,"solver_status") = two_type_fee.solvestat;

* Producer-level results
    exports_type(u,i) = Q2.l(i);

    surplus_type(u,i) =
        net_price_two_fee*Q2.l(i)
        - c_type(i)*Q2.l(i)
        - 0.5*d_type(i)*sqr(Q2.l(i));

* For active producers, net price must equal MC
    kkt_check(u,i) =
        abs(net_price_two_fee
        - (c_type(i) + d_type(i)*Q2.l(i)));

* For inactive producers, net price must not exceed MC(0)
    kkt_check(u,i)$(Q2.l(i) < 1e-6) =
        max(0, net_price_two_fee - c_type(i));

);

display results_two, exports_type,
        surplus_type, kkt_check;

* Restore the reference fee
fee = 5;




$exit

