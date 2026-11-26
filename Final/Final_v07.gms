** Final Project - DSI export fee on Indonesian Ferronickel
** DSI (Danantara Sumberdaya Indonesia), a state-owned commodity export intermediary
** Prepared by Faiz Al Harkan

** One commodity, one period, competitive exporters
** X in million metric tons, prices in USD/t, surplus and revenue in million USD
** Consumer Surplus (CS) refers to surplus under foreign residual demand since assuming consumer is foreign only (importers)

option decimals = 6;





* ----------------------------------------
** 1. Benchmark Data and Assumptions
* ----------------------------------------

* Observed export value and quantity from WITS 2025 to calculate the benchmark price
scalar
   vbar "2025 export value [million USD]" /16385.06673/
   xbar "2025 export quantity [Mt]" /11.5556/
   pbar "benchmark export price [USD/t]"
   e_r "residual demand elasticity" /-0.1/
   e_s "export supply elasticity" /0.4/
   fee "DSI fee [USD/t] baseline" /0/
   grade "common product nickel grade on FerroNickel product" /0.12/;

* Elasticities are literature-informed assumptions which assumed similar between nickel and refined nickel 
* Demand: Shojaeddini et al (2024); supply: USGS (2025)
* f denotes fee scenarios, ed denotes demand elasticity, es denotes supply elasticity, marg denotes DSI operating margin, and g denotes representative producer groups (low and high cash cost)
set f /f0, f1, f3, f5, f7, f9/;
set ed /ed0p1, ed0p3, ed0p5, ed1, ed2/;
set es /es0p3, es0p4, es0p5, es1/;
set main_ed(ed) /ed0p1, ed0p3, ed0p5/;
set main_es(es) /es0p3, es0p4, es0p5/;
set positive_fee(f) /f1, f3, f5, f7, f9/;
set marg /m25, m50, m75/;
set g "representative producer groups" /low, high/;

parameter
   fee_value(f) /f0 0, f1 1, f3 3, f5 5, f7 7, f9 9/
   demand_value(ed) /ed0p1 -0.1, ed0p3 -0.3, ed0p5 -0.5, ed1 -1, ed2 -2/
   supply_value(es) /es0p3 0.3, es0p4 0.4, es0p5 0.5, es1 1/
   margin_value(marg) /m25 0.25, m50 0.50, m75 0.75/
   cash_cost_ni(g) "2025 weighted cash cost [USD/t paid Ni]" /low 9591.459567, high 11115.376566/
   cash_cost(g) "cash cost proxy [USD/t product]";

* S&P Mine Economics 2025, production-weighted cash cost of six NPI smelters
* Low cost smelters: Bukit, Cahaya, Oracle and Angel; High cost smelters: Hengjaya and Ranger
* Common grade and full payability where costs are not marginal costs
* Convert cost per ton of paid nickel into cost per ton of product
cash_cost(g) = grade*cash_cost_ni(g);
pbar = vbar/xbar;

display vbar, xbar, pbar, e_r, e_s, cash_cost;





* ----------------------------------------
** 2. Demand and Supply Calibration
* ----------------------------------------

* P(X) = a + bX and MC(X) = c + dX
* Local linear approximation around the observed price and quantity
* A supply elasticity below one implies a negative Marginal Cost (MC) intercept
scalar a, b, c, d;

* Calibrate linear demand and supply following simplemarket.gms
* Calculate slopes using the assumed elasticities
b = pbar/(e_r*xbar);
d = pbar/(e_s*xbar);

* Calculate intercepts so both curves pass through the benchmark
a = pbar - b*xbar;
c = pbar - d*xbar;

display a, b, c, d;





* ----------------------------------------
** 3. Benchmark Equilibrium - No DSI Fee
* ----------------------------------------

positive variable X "exports [Mt]";
variable equilibrium_potential "equilibrium potential, not national welfare";
equation objfn;

* QCP objective adapted from simplemarket.gms and mrmonops.gms
* The same market model is used with and without a fee
* Maximize the area between demand and MC minus the fee to obtain market equilibrium
objfn.. equilibrium_potential =e=
   a*X + b*X*X/2 - c*X - d*X*X/2 - fee*X;

model market /objfn/;

scalar exports_base, price_base;
* Start from observed exports and solve the no-fee equilibrium
fee = 0;
X.l = xbar;
solve market using qcp maximizing equilibrium_potential;

* X.l is the equilibrium quantity and should reproduce xbar in this case
exports_base = X.l;
price_base = a + b*exports_base;
display exports_base, price_base;





* ----------------------------------------
** 4. DSI Fee Equilibrium
* ----------------------------------------

* The fee creates a difference between buyer price and net exporter price
* Main illustrative fee is 5 USD/t
scalar exports_fee, price_fee, net_price_fee, dsi_revenue_fee,
       change_cs, change_ps, change_ts, deadweight_loss,
       buyer_incidence, exporter_incidence;

* Reuse the model with a changed parameter following simplemarket.gms (shock example)
fee = fee_value("f5");
X.l = xbar;
solve market using qcp maximizing equilibrium_potential;

exports_fee = X.l;
price_fee = a + b*exports_fee;
* Buyers pay the gross price and exporters receive the price net of the fee
net_price_fee = price_fee - fee;
* Fee times export volume gives gross DSI revenue in million USD
dsi_revenue_fee = fee*exports_fee;

* Use trapezoid areas to avoid extrapolating MC to zero output (since MC < 0 so I figured out to find the TS, CS, PS and DWL by using this formula)
change_cs = (price_base-price_fee)*(exports_base+exports_fee)/2;
change_ps = (net_price_fee-price_base)*(exports_base+exports_fee)/2;
* Include fee revenue as a transfer before accounting for operating costs
change_ts = change_cs + change_ps + dsi_revenue_fee;
deadweight_loss = -change_ts;
* Calculate the share of the fee paid by buyers and exporters
buyer_incidence = 100*(price_fee-price_base)/fee;
exporter_incidence = 100*(price_base-net_price_fee)/fee;

display exports_fee, price_fee, net_price_fee, dsi_revenue_fee,
        change_cs, change_ps, change_ts, deadweight_loss,
        buyer_incidence, exporter_incidence;





* ----------------------------------------
** 5. Fee and Elasticity Sensitivity
* ----------------------------------------

* 54 main cases including 9 no-fee cases, plus 3 stress tests
* Stress tests use the main fee and more responsive buyers or suppliers
* These are static comparisons or short run models, not estimated long-run elasticities
* Select only the intended combinations of fee and elasticities
set market_case(ed,es,f);
market_case(ed,es,f) = yes$(main_ed(ed) and main_es(es));
market_case("ed1","es0p4","f5") = yes;
market_case("ed2","es0p4","f5") = yes;
market_case("ed1","es1","f5") = yes;

* Define the indicators to be calculated for each scenario
set metric /fee_USD_t, demand_elasticity, supply_elasticity, exports_Mt,
            buyer_price_USD_t, net_price_USD_t, dsi_revenue_USDm,
            export_change_pct, buyer_price_change, exporter_net_price_change,
            change_CS_USDm, change_PS_USDm, change_TS_USDm, DWL_USDm,
            buyer_incidence_pct, exporter_incidence_pct/;

* Store scenario results following the rep parameter in mrmonops.gms
parameter scenario_results(ed,es,f,metric), fee_results(f,metric),
          elastic_results(ed,es,metric);

* Reuse the model with different parameters as in simplemarket.gms
* Run only the selected scenarios
loop((ed,es,f)$market_case(ed,es,f),
   e_r = demand_value(ed);
   e_s = supply_value(es);
   fee = fee_value(f);

*  Each elasticity pair is calibrated to the same observed benchmark
   b = pbar/(e_r*xbar);
   a = pbar - b*xbar;
   d = pbar/(e_s*xbar);
   c = pbar - d*xbar;

   X.l = xbar;
   solve market using qcp maximizing equilibrium_potential;

   exports_fee = X.l;
   price_fee = a + b*exports_fee;
   net_price_fee = price_fee - fee;
   dsi_revenue_fee = fee*exports_fee;
   change_cs = (pbar-price_fee)*(xbar+exports_fee)/2;
   change_ps = (net_price_fee-pbar)*(xbar+exports_fee)/2;
   change_ts = change_cs + change_ps + dsi_revenue_fee;
   deadweight_loss = -change_ts;

*  Result storage follows the rep parameter in mrmonops.gms
*  Save the outcomes and changes relative to the common no-fee benchmark
   scenario_results(ed,es,f,"fee_USD_t") = fee;
   scenario_results(ed,es,f,"demand_elasticity") = e_r;
   scenario_results(ed,es,f,"supply_elasticity") = e_s;
   scenario_results(ed,es,f,"exports_Mt") = exports_fee;
   scenario_results(ed,es,f,"buyer_price_USD_t") = price_fee;
   scenario_results(ed,es,f,"net_price_USD_t") = net_price_fee;
   scenario_results(ed,es,f,"dsi_revenue_USDm") = dsi_revenue_fee;
   scenario_results(ed,es,f,"export_change_pct") = 100*(exports_fee/xbar-1);
   scenario_results(ed,es,f,"buyer_price_change") = price_fee-pbar;
   scenario_results(ed,es,f,"exporter_net_price_change") = net_price_fee-pbar;
   scenario_results(ed,es,f,"change_CS_USDm") = change_cs;
   scenario_results(ed,es,f,"change_PS_USDm") = change_ps;
   scenario_results(ed,es,f,"change_TS_USDm") = change_ts;
   scenario_results(ed,es,f,"DWL_USDm") = deadweight_loss;

*  Fee incidence is undefined at zero fee
   scenario_results(ed,es,f,"buyer_incidence_pct") = NA;
   scenario_results(ed,es,f,"exporter_incidence_pct") = NA;
   if(fee > 0,
      scenario_results(ed,es,f,"buyer_incidence_pct") = 100*(price_fee-pbar)/fee;
      scenario_results(ed,es,f,"exporter_incidence_pct") = 100*(pbar-net_price_fee)/fee;
   );
);

* Compare different fees while keeping elasticities constant
fee_results(f,metric) = scenario_results("ed0p1","es0p4",f,metric);
* Compare different elasticities while keeping the fee at 5 USD/t
elastic_results(ed,es,metric)$market_case(ed,es,"f5") = scenario_results(ed,es,"f5",metric);

display fee_results, elastic_results;





* ----------------------------------------
** 6. DSI Operating Margin Analysis
* ----------------------------------------

* Operating margins are illustrative since since DSI was established in mid-2026 which unknown yet published data such as cost, revenue, and profit
* Assume DSI operations create additional costs to the whole economy
* Assume all producer surplus and DSI profit remain in Indonesia (domestically)
* Exclude governance benefits, taxes, financing and capital expenditure
* Domestic surplus is a proxy, not a complete measure of national welfare
* DSI profit may contribute to Danantara's investment funds as a national SWF

set fin_metric /margin_pct, revenue_USDm, operating_cost_USDm,
                operating_profit_USDm, domestic_surplus_change_USDm,
                net_total_surplus_change_USDm/;
parameter margin_matrix(ed,es,f,marg,fin_metric), margin_results(marg,fin_metric);
scalar revenue_case, cost_case, profit_case;

loop((ed,es,f,marg)$(market_case(ed,es,f) and positive_fee(f)),
   revenue_case = scenario_results(ed,es,f,"dsi_revenue_USDm");
*  Split gross revenue into operating costs and operating profit
   cost_case = (1-margin_value(marg))*revenue_case;
   profit_case = margin_value(marg)*revenue_case;

   margin_matrix(ed,es,f,marg,"margin_pct") = 100*margin_value(marg);
   margin_matrix(ed,es,f,marg,"revenue_USDm") = revenue_case;
   margin_matrix(ed,es,f,marg,"operating_cost_USDm") = cost_case;
   margin_matrix(ed,es,f,marg,"operating_profit_USDm") = profit_case;
*  Compare DSI profit with the loss in exporter surplus
   margin_matrix(ed,es,f,marg,"domestic_surplus_change_USDm") =
      scenario_results(ed,es,f,"change_PS_USDm") + profit_case;
*  Subtract operating costs from total market surplus change
   margin_matrix(ed,es,f,marg,"net_total_surplus_change_USDm") =
      scenario_results(ed,es,f,"change_TS_USDm") - cost_case;
);

margin_results(marg,fin_metric) = margin_matrix("ed0p1","es0p4","f5",marg,fin_metric);
display margin_results;





* ----------------------------------------
** 7. Producer Cash Margin Analysis
* ----------------------------------------

* Assume representative exporters face the same net product price
* Hold cash cost per ton constant and use a common 12 percent nickel grade based available data from S&P Mine Economics 2025 and University of Maryland - Indonesia Nickel Smelter Database (2025)
* Compare cash margin exposure, not accounting profit or producer surplus
* Cash costs do not identify individual MC curves or output responses
set cash_metric /cash_cost_USD_t, initial_margin_USD_t, net_price_USD_t,
                 cash_margin_USD_t, margin_loss_USD_t, margin_loss_pct/;
parameter initial_margin(g), cash_results(ed,es,f,g,cash_metric),
          cash_main(g,cash_metric);
scalar net_price_case, margin_loss_case;

* Initial cash margin is selling price minus estimated unit cash cost
initial_margin(g) = pbar - cash_cost(g);

loop((ed,es,f,g)$market_case(ed,es,f),
   net_price_case = scenario_results(ed,es,f,"net_price_USD_t");
*  Both groups face the same price reduction but have different initial margins
   margin_loss_case = pbar-net_price_case;

   cash_results(ed,es,f,g,"cash_cost_USD_t") = cash_cost(g);
   cash_results(ed,es,f,g,"initial_margin_USD_t") = initial_margin(g);
   cash_results(ed,es,f,g,"net_price_USD_t") = net_price_case;
   cash_results(ed,es,f,g,"cash_margin_USD_t") = net_price_case-cash_cost(g);
   cash_results(ed,es,f,g,"margin_loss_USD_t") = margin_loss_case;
   cash_results(ed,es,f,g,"margin_loss_pct") = NA;
*  Calculate relative cash margin loss only when the initial margin is positive
   if(initial_margin(g) > 0,
      cash_results(ed,es,f,g,"margin_loss_pct") = 100*margin_loss_case/initial_margin(g);
   );
);

cash_main(g,cash_metric) = cash_results("ed0p1","es0p4","f5",g,cash_metric);
display cash_main;





* ----------------------------------------
** 8. Results and CSV Export
* ----------------------------------------

* GDX export follows simplemarket.gms
* Export only the three result tables and compact summaries
execute_unload 'Final_v07_results.gdx', vbar, xbar, pbar, grade,
   fee_value, demand_value, supply_value, margin_value, cash_cost_ni, cash_cost,
   market_case, scenario_results, fee_results, elastic_results,
   margin_matrix, margin_results, cash_results, cash_main;

* Write each selected scenario as one CSV row with metrics in columns
file out_market /'Final_v07_market.csv'/;
file out_margin /'Final_v07_margin.csv'/;
file out_cash /'Final_v07_cash.csv'/;
out_market.pw = 4096;
out_margin.pw = 4096;
out_cash.pw = 4096;

put out_market;
put 'demand_case,supply_case,fee_case';
loop(metric, put ',' metric.tl:0;);
put /;
loop((ed,es,f)$market_case(ed,es,f),
   put ed.tl:0 ',' es.tl:0 ',' f.tl:0;
   loop(metric, put ',' scenario_results(ed,es,f,metric):0:8;);
   put /;
);
putclose out_market;

put out_margin;
put 'demand_case,supply_case,fee_case,margin_case';
loop(fin_metric, put ',' fin_metric.tl:0;);
put /;
loop((ed,es,f,marg)$(market_case(ed,es,f) and positive_fee(f)),
   put ed.tl:0 ',' es.tl:0 ',' f.tl:0 ',' marg.tl:0;
   loop(fin_metric, put ',' margin_matrix(ed,es,f,marg,fin_metric):0:8;);
   put /;
);
putclose out_margin;

put out_cash;
put 'demand_case,supply_case,fee_case,producer_group';
loop(cash_metric, put ',' cash_metric.tl:0;);
put /;
loop((ed,es,f,g)$market_case(ed,es,f),
   put ed.tl:0 ',' es.tl:0 ',' f.tl:0 ',' g.tl:0;
   loop(cash_metric, put ',' cash_results(ed,es,f,g,cash_metric):0:8;);
   put /;
);
putclose out_cash;

$exit
