
** Final Project - DSI export fee on Indonesian Ferronickel
** Prepared by Faiz Al Harkan

** Phase 1 - Welfare analysis and fee incidence
** Assumption: 1 commodity, 1 period, competitive exporters
** Using 2025 export data; elasticities and fees are assumed
** X = exports (million metric tons); P = USD per ton of product
** Revenue, cost, surplus, and profit are in million USD
** CS refers to surplus under foreign residual demand.
** Total surplus excludes real DSI operating costs and governance benefits.

option decimals = 6;

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
b = pbar / (e_r * xbar);
a = pbar - b * xbar;

d = pbar / (e_s * xbar);
c = pbar - d * xbar;

display a, b, c, d;

* ----------------------------------------
** 3. Direct Selling - No Fee
* ----------------------------------------

* Competitive market, where P = MC

positive variable X "export quantity";
variable equilibrium_potential "equilibrium potential, not national welfare";

equation eq_surplus;

eq_surplus..
   equilibrium_potential =e=
     a*X + 0.5*b*sqr(X)
   - c*X - 0.5*d*sqr(X);

model direct_selling /eq_surplus/;

X.l = xbar;

solve direct_selling using qcp maximizing equilibrium_potential;

abort$(direct_selling.solvestat ne 1 or
      (direct_selling.modelstat ne 1 and direct_selling.modelstat ne 2))
   "No-fee solve did not terminate at an optimum";

* Calculate baseline price, exporter surplus, and welfare
scalar
   exports_base "baseline export quantity [Mt]"
   price_base "baseline buyer and exporter price [USD/ton]"
   exporter_surplus_base "baseline producer surplus [million USD]"
   consumer_surplus_base "baseline residual buyer surplus [million USD]"
   total_surplus_base "baseline modeled market surplus [million USD]";

exports_base = X.l;
price_base = a + b*exports_base;

exporter_surplus_base = price_base*exports_base
                      - (c*exports_base + 0.5*d*sqr(exports_base));

* Phase 1: consumer surplus and total surplus
consumer_surplus_base = -0.5*b*sqr(exports_base);

total_surplus_base = consumer_surplus_base + exporter_surplus_base;

display exports_base, price_base, exporter_surplus_base,
        consumer_surplus_base, total_surplus_base;

* ----------------------------------------
** 4. Direct Selling - With DSI Fee
* ----------------------------------------

* Exporters pay a hypothetical fee to DSI for monitoring and verification.
* DSI revenue is not the same as DSI profit.
* The fee is deducted in the equilibrium potential to obtain P - fee = MC.
* It is added back in total surplus because it is a transfer before costs.

scalar fee "DSI fee [USD/ton]" /5/;

equation eq_fee;

eq_fee..
   equilibrium_potential =e=
     a*X + 0.5*b*sqr(X)
   - c*X - 0.5*d*sqr(X)
   - fee*X;

model with_dsi_fee /eq_fee/;

X.l = xbar;

solve with_dsi_fee using qcp maximizing equilibrium_potential;

abort$(with_dsi_fee.solvestat ne 1 or
      (with_dsi_fee.modelstat ne 1 and with_dsi_fee.modelstat ne 2))
   "Main fee solve did not terminate at an optimum";

scalar
   exports_fee "export quantity with fee [Mt]"
   price_fee "foreign buyer price [USD/ton]"
   net_price_fee "net exporter price [USD/ton]"
   exporter_surplus_fee "producer surplus [million USD]"
   dsi_revenue_fee "DSI gross revenue [million USD]"
   consumer_surplus_fee "residual buyer surplus [million USD]"
   total_surplus_fee "modeled market surplus before DSI costs [million USD]"
   change_cs "change in consumer surplus [million USD]"
   change_ps "change in producer surplus [million USD]"
   change_ts "change in total surplus [million USD]"
   deadweight_loss "loss in total surplus before DSI costs [million USD]"
   buyer_incidence "buyer share of per-ton fee [percent]"
   exporter_incidence "exporter share of per-ton fee [percent]"
   check_eq "fee-adjusted equilibrium residual [USD/ton]";

exports_fee = X.l;
price_fee = a + b*exports_fee;
net_price_fee = price_fee - fee;

exporter_surplus_fee = net_price_fee*exports_fee
                    - (c*exports_fee + 0.5*d*sqr(exports_fee));

dsi_revenue_fee = fee*exports_fee;

* Phase 1: welfare with DSI fee
consumer_surplus_fee = -0.5*b*sqr(exports_fee);

total_surplus_fee = consumer_surplus_fee
                 + exporter_surplus_fee
                 + dsi_revenue_fee;

change_cs = consumer_surplus_fee - consumer_surplus_base;
change_ps = exporter_surplus_fee - exporter_surplus_base;
change_ts = total_surplus_fee - total_surplus_base;

deadweight_loss = total_surplus_base - total_surplus_fee;

* Phase 1: fee incidence (undefined at zero fee)
buyer_incidence = NA;
exporter_incidence = NA;

if(fee > 0,
   buyer_incidence = 100*(price_fee - price_base)/fee;
   exporter_incidence = 100*(price_base - net_price_fee)/fee;
);

* Check if P - fee = MC (interior solution)
check_eq = net_price_fee - (c + d*exports_fee);

display exports_fee, price_fee, net_price_fee,
        exporter_surplus_fee, dsi_revenue_fee, check_eq,
        consumer_surplus_fee, total_surplus_fee,
        change_cs, change_ps, change_ts, deadweight_loss,
        buyer_incidence, exporter_incidence;

* Phase 1: preserve the main comparison before subsequent loops
parameter main_results(*,*) "baseline and main policy scenario";

main_results("no_fee","fee_USD_t") = 0;
main_results("no_fee","exports_Mt") = exports_base;
main_results("no_fee","buyer_price_USD_t") = price_base;
main_results("no_fee","net_price_USD_t") = price_base;
main_results("no_fee","consumer_surplus_USDm") = consumer_surplus_base;
main_results("no_fee","exporter_surplus_USDm") = exporter_surplus_base;
main_results("no_fee","dsi_revenue_USDm") = 0;
main_results("no_fee","total_surplus_USDm") = total_surplus_base;
main_results("no_fee","DWL_USDm") = 0;
main_results("no_fee","buyer_incidence_pct") = NA;
main_results("no_fee","exporter_incidence_pct") = NA;

main_results("with_fee","fee_USD_t") = fee;
main_results("with_fee","exports_Mt") = exports_fee;
main_results("with_fee","buyer_price_USD_t") = price_fee;
main_results("with_fee","net_price_USD_t") = net_price_fee;
main_results("with_fee","consumer_surplus_USDm") = consumer_surplus_fee;
main_results("with_fee","exporter_surplus_USDm") = exporter_surplus_fee;
main_results("with_fee","dsi_revenue_USDm") = dsi_revenue_fee;
main_results("with_fee","total_surplus_USDm") = total_surplus_fee;
main_results("with_fee","DWL_USDm") = deadweight_loss;
main_results("with_fee","buyer_incidence_pct") = buyer_incidence;
main_results("with_fee","exporter_incidence_pct") = exporter_incidence;

display main_results;

* Phase 1: verify the main policy scenario against analytical solutions.
* Checks should be close to zero. Triangle DWL is valid for this linear,
* interior equilibrium. No rounding is applied to stored results.
scalar
   exports_analytical
   dwl_analytical
   check_base_quantity
   check_base_price
   check_base_eq
   check_quantity
   check_welfare
   check_dwl
   check_incidence;

exports_analytical = (a - c - fee)/(d - b);
dwl_analytical = 0.5*fee*(exports_base - exports_fee);

check_base_quantity = exports_base - xbar;
check_base_price = price_base - pbar;
check_base_eq = price_base - (c + d*exports_base);
check_quantity = exports_fee - exports_analytical;
check_welfare = change_cs + change_ps + dsi_revenue_fee - change_ts;
check_dwl = deadweight_loss - dwl_analytical;
check_incidence = buyer_incidence + exporter_incidence - 100;

display exports_analytical, dwl_analytical,
        check_base_quantity, check_base_price, check_base_eq,
        check_quantity, check_eq, check_welfare, check_dwl,
        check_incidence;

* ----------------------------------------
** 5. Fee Sensitivity Analysis
* ----------------------------------------

* Test different DSI fees using the same demand and supply curves

set s "fee scenarios" /f0, f0p5, f1, f3, f5, f7, f9/;

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

   solve with_dsi_fee using qcp maximizing equilibrium_potential;

   abort$(with_dsi_fee.solvestat ne 1 or
         (with_dsi_fee.modelstat ne 1 and with_dsi_fee.modelstat ne 2))
      "Fee sensitivity solve did not terminate at an optimum", s;

   price_fee = a + b*X.l;
   net_price_fee = price_fee - fee;

   exporter_surplus_fee = net_price_fee*X.l
                        - (c*X.l + 0.5*d*sqr(X.l));

   dsi_revenue_fee = fee*X.l;

*  Phase 1: calculate welfare for each fee scenario
   consumer_surplus_fee = -0.5*b*sqr(X.l);
   total_surplus_fee = consumer_surplus_fee
                     + exporter_surplus_fee + dsi_revenue_fee;

   change_cs = consumer_surplus_fee - consumer_surplus_base;
   change_ps = exporter_surplus_fee - exporter_surplus_base;
   change_ts = total_surplus_fee - total_surplus_base;
   deadweight_loss = total_surplus_base - total_surplus_fee;

   fee_results(s,"fee") = fee;
   fee_results(s,"exports_Mt") = X.l;
   fee_results(s,"price_USD_t") = price_fee;
   fee_results(s,"net_price_USD_t") = net_price_fee;
   fee_results(s,"exporter_surplus_USDm") = exporter_surplus_fee;
   fee_results(s,"dsi_revenue_USDm") = dsi_revenue_fee;
   fee_results(s,"consumer_surplus_USDm") = consumer_surplus_fee;
   fee_results(s,"total_surplus_USDm") = total_surplus_fee;
   fee_results(s,"DWL_USDm") = deadweight_loss;

*  Changes relative to the no-fee baseline
   fee_results(s,"export_change_pct") = 100*(X.l/exports_base - 1);
   fee_results(s,"buyer_price_change") = price_fee - price_base;
   fee_results(s,"exporter_net_price_change") = net_price_fee - price_base;
   fee_results(s,"change_CS_USDm") = change_cs;
   fee_results(s,"change_PS_USDm") = change_ps;
   fee_results(s,"change_TS_USDm") = change_ts;

*  Fee incidence is not defined when fee = 0
   fee_results(s,"buyer_incidence_pct") = NA;
   fee_results(s,"exporter_incidence_pct") = NA;

   if(fee > 0,
      fee_results(s,"buyer_incidence_pct") =
         100*(price_fee - price_base)/fee;
      fee_results(s,"exporter_incidence_pct") =
         100*(price_base - net_price_fee)/fee;
   );

);

display fee_results;

* ----------------------------------------
** 6. Demand Elasticity Sensitivity Analysis
* ----------------------------------------

* Keep DSI fee at USD 5/ton
* Test different foreign demand elasticities
* Each elasticity must have its own no-fee welfare benchmark.

fee = 5;

set t "elasticity scenarios" /e1, e2, e4/;

parameter elastic_value(t) "residual demand elasticity"
   /e1 -1
    e2 -2
    e4 -4/;

parameter elastic_results(t,*) "elasticity sensitivity results";
parameter elastic_baseline(t,*) "no-fee welfare benchmark for each elasticity";

scalar
   exports_base_elastic
   price_base_elastic
   consumer_surplus_base_elastic
   exporter_surplus_base_elastic
   total_surplus_base_elastic;

loop(t,

   e_r = elastic_value(t);

*  Recalibrate demand for each elasticity
   b = pbar / (e_r * xbar);
   a = pbar - b*xbar;

*  Phase 1: analytical no-fee benchmark for this elasticity.
*  All current curves are calibrated to the same xbar and pbar.
*  The closed-form interior solution avoids an extra solve here.
   exports_base_elastic = (a - c)/(d - b);
   price_base_elastic = a + b*exports_base_elastic;

   consumer_surplus_base_elastic = -0.5*b*sqr(exports_base_elastic);
   exporter_surplus_base_elastic = price_base_elastic*exports_base_elastic
                  - (c*exports_base_elastic + 0.5*d*sqr(exports_base_elastic));
   total_surplus_base_elastic = consumer_surplus_base_elastic
                              + exporter_surplus_base_elastic;

   elastic_baseline(t,"elasticity") = e_r;
   elastic_baseline(t,"exports_Mt") = exports_base_elastic;
   elastic_baseline(t,"price_USD_t") = price_base_elastic;
   elastic_baseline(t,"consumer_surplus_USDm") = consumer_surplus_base_elastic;
   elastic_baseline(t,"exporter_surplus_USDm") = exporter_surplus_base_elastic;
   elastic_baseline(t,"total_surplus_USDm") = total_surplus_base_elastic;

   X.l = xbar;

   solve with_dsi_fee using qcp maximizing equilibrium_potential;

   abort$(with_dsi_fee.solvestat ne 1 or
         (with_dsi_fee.modelstat ne 1 and with_dsi_fee.modelstat ne 2))
      "Elasticity sensitivity solve did not terminate at an optimum", t;

   price_fee = a + b*X.l;
   net_price_fee = price_fee - fee;

   exporter_surplus_fee = net_price_fee*X.l
                        - (c*X.l + 0.5*d*sqr(X.l));

   dsi_revenue_fee = fee*X.l;

*  Phase 1: welfare relative to the matching no-fee benchmark
   consumer_surplus_fee = -0.5*b*sqr(X.l);
   total_surplus_fee = consumer_surplus_fee
                     + exporter_surplus_fee + dsi_revenue_fee;

   change_cs = consumer_surplus_fee - consumer_surplus_base_elastic;
   change_ps = exporter_surplus_fee - exporter_surplus_base_elastic;
   change_ts = total_surplus_fee - total_surplus_base_elastic;
   deadweight_loss = total_surplus_base_elastic - total_surplus_fee;

   elastic_results(t,"elasticity") = e_r;
   elastic_results(t,"exports_Mt") = X.l;
   elastic_results(t,"buyer_price_USD_t") = price_fee;
   elastic_results(t,"net_exporter_USD_t") = net_price_fee;
   elastic_results(t,"exporter_surplus_USDm") = exporter_surplus_fee;
   elastic_results(t,"dsi_revenue_USDm") = dsi_revenue_fee;
   elastic_results(t,"consumer_surplus_USDm") = consumer_surplus_fee;
   elastic_results(t,"total_surplus_USDm") = total_surplus_fee;
   elastic_results(t,"DWL_USDm") = deadweight_loss;
   elastic_results(t,"export_change_pct") = 100*(X.l/exports_base_elastic - 1);
   elastic_results(t,"buyer_price_change") = price_fee - price_base_elastic;
   elastic_results(t,"exporter_net_price_change") = net_price_fee - price_base_elastic;
   elastic_results(t,"change_CS_USDm") = change_cs;
   elastic_results(t,"change_PS_USDm") = change_ps;
   elastic_results(t,"change_TS_USDm") = change_ts;

   elastic_results(t,"buyer_incidence_pct") = NA;
   elastic_results(t,"exporter_incidence_pct") = NA;

   if(fee > 0,
      elastic_results(t,"buyer_incidence_pct") =
         100*(price_fee - price_base_elastic)/fee;
      elastic_results(t,"exporter_incidence_pct") =
         100*(price_base_elastic - net_price_fee)/fee;
   );

);

display elastic_baseline, elastic_results;

* Restore the main elasticity assumption.
* The last X.l is still the last elasticity scenario, not the main case.
* Use main_results or fee_results("f5",...) for the main case.
e_r = -2;
b = pbar / (e_r * xbar);
a = pbar - b*xbar;

* ----------------------------------------
** 7. DSI Operating Margin Sensitivity
* ----------------------------------------

* Assume DSI operating margins of 25%, 50%, and 75%
* Use the DSI revenue from the USD 5/ton fee scenario
* Retained from M3; cost-adjusted welfare and break-even are Phase 2.

set m "DSI margin scenarios" /m25, m50, m75/;

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