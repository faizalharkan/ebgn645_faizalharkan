** Final Project - DSI export fee on Indonesian Ferronickel
** DSI (Danantara Sumberdaya Indonesia), a state-owned commodity export intermediary
** Prepared by Faiz Al Harkan

** Market assumption: 1 commodity, 1 period, competitive exporters
** Using 2025 export data with literature-informed elasticity assumptions
** X = exports (million metric tons); P = USD per ton of product
** Revenue, cost, surplus, and profit are in million USD
** Consumer Surplus (CS) refers to surplus under foreign residual demand
** Welfare changes before DSI operating costs exclude governance benefits
** Operating margins are illustrative because actual DSI margins are unavailable
** Linear demand and marginal cost are local approximations based on 2025 data
** Only surplus changes are reported because linear MC ended up negative 

option decimals = 6;





* ----------------------------------------
** 1. Input Values and Elasticities
* ----------------------------------------

scalar
   vbar "2025 export value [million USD]" /16385.06673/
   xbar "2025 export quantity [million tons]" /11.5556/
   pbar "average export price [USD/ton]"
   e_r  "residual demand elasticity [unitless]" /-0.1/
   e_s  "supply elasticity [unitless]" /0.4/;

* Demand: Shojaeddini et al. (2024), global nickel (-0.09, rounded)
* Supply: USGS (2025), primary refined nickel (0.43, rounded)
* Neither estimate is specific to Indonesian ferronickel exports

* Average price from 2025 export data
pbar = vbar / xbar;

display vbar, xbar, pbar, e_r, e_s;





* ----------------------------------------
** 2. Determine Inverse Residual Demand and Marginal Cost
* ----------------------------------------

* P(X) = a + bX
* MC(X) = c + dX
* With e_s < 1, the linear MC intercept c is negative
* Use the marginal cost curve only near the benchmark

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

* Set the initial export quantity at the benchmark
X.l = xbar;

* Solve for the competitive equilibrium without DSI fee
solve direct_selling using qcp maximizing equilibrium_potential;

* Calculate baseline quantity and price
scalar
   exports_base "baseline export quantity [Mt]"
   price_base "baseline buyer and exporter price [USD/ton]";

exports_base = X.l;
price_base = a + b*exports_base;

display exports_base, price_base;





* ----------------------------------------
** 4. Direct Selling - With DSI Fee
* ----------------------------------------

* Exporters pay a hypothetical single-digit fee to DSI for monitoring and verification
* The fee is illustrative because confirmed fee data are unavailable
* DSI revenue is not the same as DSI profit
* The fee is deducted in the equilibrium potential to obtain P - fee = MC
* Fee revenue is added to the change in market surplus before DSI operating costs
* Main policy scenario: fee = $5/ton

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

scalar
   exports_fee "export quantity with fee [Mt]"
   price_fee "foreign buyer price [USD/ton]"
   net_price_fee "net exporter price [USD/ton]"
   dsi_revenue_fee "DSI gross revenue [million USD]"
   change_cs "change in consumer surplus [million USD]"
   change_ps "change in producer surplus [million USD]"
   change_ts "change in total surplus [million USD]"
   deadweight_loss "loss in total surplus before DSI costs [million USD]"
   buyer_incidence "buyer share of per-ton fee [percent]"
   exporter_incidence "exporter share of per-ton fee [percent]";

exports_fee = X.l;
price_fee = a + b*exports_fee;
net_price_fee = price_fee - fee;
dsi_revenue_fee = fee*exports_fee;

* Supply elasticity below 1 gives a negative linear MC intercept
* Absolute surplus may be misleading when MC is extrapolated to zero output
* Calculate surplus changes directly using trapezoid areas
change_cs = (price_base - price_fee)*(exports_base + exports_fee)/2;
change_ps = (net_price_fee - price_base)*(exports_base + exports_fee)/2;
change_ts = change_cs + change_ps + dsi_revenue_fee;
deadweight_loss = -change_ts;

* Fee incidence (undefined at zero fee)
buyer_incidence = NA;
exporter_incidence = NA;

if(fee > 0,
   buyer_incidence = 100*(price_fee - price_base)/fee;
   exporter_incidence = 100*(price_base - net_price_fee)/fee;
);

display exports_fee, price_fee, net_price_fee, dsi_revenue_fee,
       change_cs, change_ps, change_ts, deadweight_loss,
       buyer_incidence, exporter_incidence;

* Preserve the main comparison before subsequent loops
parameter main_results(*,*) "baseline and main policy scenario";

main_results("no_fee","fee_USD_t") = 0;
main_results("no_fee","exports_Mt") = exports_base;
main_results("no_fee","buyer_price_USD_t") = price_base;
main_results("no_fee","net_price_USD_t") = price_base;
main_results("no_fee","dsi_revenue_USDm") = 0;
main_results("no_fee","change_CS_USDm") = 0;
main_results("no_fee","change_PS_USDm") = 0;
main_results("no_fee","change_TS_USDm") = 0;
main_results("no_fee","DWL_USDm") = 0;
main_results("no_fee","buyer_incidence_pct") = NA;
main_results("no_fee","exporter_incidence_pct") = NA;

main_results("with_fee","fee_USD_t") = fee;
main_results("with_fee","exports_Mt") = exports_fee;
main_results("with_fee","buyer_price_USD_t") = price_fee;
main_results("with_fee","net_price_USD_t") = net_price_fee;
main_results("with_fee","dsi_revenue_USDm") = dsi_revenue_fee;
main_results("with_fee","change_CS_USDm") = change_cs;
main_results("with_fee","change_PS_USDm") = change_ps;
main_results("with_fee","change_TS_USDm") = change_ts;
main_results("with_fee","DWL_USDm") = deadweight_loss;
main_results("with_fee","buyer_incidence_pct") = buyer_incidence;
main_results("with_fee","exporter_incidence_pct") = exporter_incidence;

display main_results;





* ----------------------------------------
** 5. Full Fee and Elasticity Scenario Matrix
* ----------------------------------------

* Seven fee levels, three demand elasticities, and three supply elasticities
* Each pair of elasticities is calibrated to the same observed P and X

set f "fee scenarios" /f0, f0p5, f1, f3, f5, f7, f9/;
set ed "residual demand elasticity scenarios" /ed0p1, ed0p3, ed0p5/;
set es "export supply elasticity scenarios" /es0p3, es0p4, es0p5/;
set positive_fee(f) "positive fee scenarios";

parameter fee_value(f) "DSI fee [USD/ton]"
   /f0 0, f0p5 0.5, f1 1, f3 3, f5 5, f7 7, f9 9/;

parameter demand_value(ed) "residual demand elasticity"
   /ed0p1 -0.1, ed0p3 -0.3, ed0p5 -0.5/;

parameter supply_value(es) "export supply elasticity"
   /es0p3 0.3, es0p4 0.4, es0p5 0.5/;

positive_fee(f) = yes$(fee_value(f) > 0);

set metric "market and welfare results"
   /fee_USD_t, demand_elasticity, supply_elasticity, exports_Mt,
    buyer_price_USD_t, net_price_USD_t, dsi_revenue_USDm, DWL_USDm,
    export_change_pct, buyer_price_change, exporter_net_price_change,
    change_CS_USDm, change_PS_USDm, change_TS_USDm,
    buyer_incidence_pct, exporter_incidence_pct/;

parameter
   scenario_results(ed,es,f,metric) "63 market equilibrium combinations"
   elastic_baseline(ed,es,*) "no-fee benchmark by elasticity pair";

loop((ed,es),

   e_r = demand_value(ed);
   e_s = supply_value(es);

*  Recalibrate demand and supply to the same observed benchmark
   b = pbar / (e_r*xbar);
   a = pbar - b*xbar;
   d = pbar / (e_s*xbar);
   c = pbar - d*xbar;

   elastic_baseline(ed,es,"demand_elasticity") = e_r;
   elastic_baseline(ed,es,"supply_elasticity") = e_s;
   elastic_baseline(ed,es,"exports_Mt") = xbar;
   elastic_baseline(ed,es,"price_USD_t") = pbar;

   loop(f,

      fee = fee_value(f);
      X.l = xbar;

      solve with_dsi_fee using qcp maximizing equilibrium_potential;

*     Market outcomes
      exports_fee = X.l;
      price_fee = a + b*exports_fee;
      net_price_fee = price_fee - fee;
      dsi_revenue_fee = fee*exports_fee;

*     Surplus changes relative to the common no-fee benchmark
      change_cs = (pbar - price_fee)*(xbar + exports_fee)/2;
      change_ps = (net_price_fee - pbar)*(xbar + exports_fee)/2;
      change_ts = change_cs + change_ps + dsi_revenue_fee;
      deadweight_loss = -change_ts;

      scenario_results(ed,es,f,"fee_USD_t") = fee;
      scenario_results(ed,es,f,"demand_elasticity") = e_r;
      scenario_results(ed,es,f,"supply_elasticity") = e_s;
      scenario_results(ed,es,f,"exports_Mt") = exports_fee;
      scenario_results(ed,es,f,"buyer_price_USD_t") = price_fee;
      scenario_results(ed,es,f,"net_price_USD_t") = net_price_fee;
      scenario_results(ed,es,f,"dsi_revenue_USDm") = dsi_revenue_fee;
      scenario_results(ed,es,f,"DWL_USDm") = deadweight_loss;
      scenario_results(ed,es,f,"export_change_pct") = 100*(exports_fee/xbar - 1);
      scenario_results(ed,es,f,"buyer_price_change") = price_fee - pbar;
      scenario_results(ed,es,f,"exporter_net_price_change") = net_price_fee - pbar;
      scenario_results(ed,es,f,"change_CS_USDm") = change_cs;
      scenario_results(ed,es,f,"change_PS_USDm") = change_ps;
      scenario_results(ed,es,f,"change_TS_USDm") = change_ts;

*     Fee incidence is undefined when fee = 0
      scenario_results(ed,es,f,"buyer_incidence_pct") = NA;
      scenario_results(ed,es,f,"exporter_incidence_pct") = NA;

      if(fee > 0,
         scenario_results(ed,es,f,"buyer_incidence_pct") =
            100*(price_fee - pbar)/fee;
         scenario_results(ed,es,f,"exporter_incidence_pct") =
            100*(pbar - net_price_fee)/fee;
      );

   );
);

* Restore the benchmark assumptions after the scenario loop
e_r = demand_value("ed0p1");
e_s = supply_value("es0p4");
fee = fee_value("f5");
b = pbar / (e_r*xbar);
a = pbar - b*xbar;
d = pbar / (e_s*xbar);
c = pbar - d*xbar;

display elastic_baseline, scenario_results;





* ----------------------------------------
** 6. Fee and Elasticity Sensitivity Results
* ----------------------------------------

* Extract sensitivity tables from the market results

parameter
   fee_results(f,metric) "fee sensitivity at benchmark elasticities"
   elastic_results(ed,es,metric) "elasticity sensitivity at USD 5/ton"
   export_change_matrix(f,ed,es) "export change [percent]"
   ps_loss_matrix(f,ed,es) "producer surplus loss [million USD]"
   dwl_matrix(f,ed,es) "deadweight loss [thousand USD]";

fee_results(f,metric) = scenario_results("ed0p1","es0p4",f,metric);
elastic_results(ed,es,metric) = scenario_results(ed,es,"f5",metric);

export_change_matrix(f,ed,es) = scenario_results(ed,es,f,"export_change_pct");
ps_loss_matrix(f,ed,es) = -scenario_results(ed,es,f,"change_PS_USDm");
dwl_matrix(f,ed,es) = 1000*scenario_results(ed,es,f,"DWL_USDm");

display fee_results, elastic_results,
       export_change_matrix, ps_loss_matrix, dwl_matrix;





* ----------------------------------------
** 7. DSI Operating Margin Sensitivity
* ----------------------------------------

* Operating margins of 25%, 50%, and 75% are assumed, not estimated
* Operating cost = (1-margin)*gross revenue
* Operating profit = margin*gross revenue
* Costs are assumed incremental real resource costs for net welfare
* Assume full domestic attribution of producer surplus and DSI profit
* Conditional domestic surplus is not Indonesian national welfare
* Governance benefits, corporate taxes, capex and financing are excluded
* The no-DSI / zero-fee benchmark has no incremental DSI costs
* Only the 54 positive-fee scenarios receive margin sensitivity analysis

set m "DSI margin scenarios" /m25, m50, m75/;
parameter margin_value(m) "assumed DSI operating margin"
   /m25 0.25, m50 0.50, m75 0.75/;

set fin_metric "financial and net welfare results"
   /margin_pct, revenue_USDm, operating_cost_USDm, operating_profit_USDm,
    change_PS_USDm, DWL_USDm, domestic_surplus_change_USDm,
    net_total_surplus_change_USDm,
    required_governance_benefit_USDm/;

parameter
   margin_matrix(ed,es,f,m,fin_metric) "162 positive fee and operating margin cases"
   margin_results(m,fin_metric) "main case operating margin sensitivity"
   domestic_matrix(ed,es,f,m) "conditional domestic surplus change [million USD]";

scalar
   revenue_case
   cost_case
   profit_case
   ps_change_case
   dwl_case
   domestic_change_case
   net_ts_change_case;

loop((ed,es,f,m)$positive_fee(f),

   revenue_case = scenario_results(ed,es,f,"dsi_revenue_USDm");
   ps_change_case = scenario_results(ed,es,f,"change_PS_USDm");
   dwl_case = scenario_results(ed,es,f,"DWL_USDm");

   cost_case = (1-margin_value(m))*revenue_case;
   profit_case = margin_value(m)*revenue_case;

*  Conditional domestic surplus: producer surplus change plus DSI profit
   domestic_change_case = ps_change_case + profit_case;

*  Total modeled market surplus including foreign buyers, after costs
   net_ts_change_case = -dwl_case - cost_case;

   margin_matrix(ed,es,f,m,"margin_pct") = 100*margin_value(m);
   margin_matrix(ed,es,f,m,"revenue_USDm") = revenue_case;
   margin_matrix(ed,es,f,m,"operating_cost_USDm") = cost_case;
   margin_matrix(ed,es,f,m,"operating_profit_USDm") = profit_case;
   margin_matrix(ed,es,f,m,"change_PS_USDm") = ps_change_case;
   margin_matrix(ed,es,f,m,"DWL_USDm") = dwl_case;
   margin_matrix(ed,es,f,m,"domestic_surplus_change_USDm") = domestic_change_case;
   margin_matrix(ed,es,f,m,"net_total_surplus_change_USDm") = net_ts_change_case;

*  Minimum incremental real governance benefit needed for market welfare
*  break-even; not an estimate of actual governance benefits
   margin_matrix(ed,es,f,m,"required_governance_benefit_USDm") =
      max(0,dwl_case + cost_case);

   domestic_matrix(ed,es,f,m) = domestic_change_case;

);

* Main case: fee = 5, demand elasticity = -0.1, supply elasticity = 0.4
margin_results(m,fin_metric) = margin_matrix("ed0p1","es0p4","f5",m,fin_metric);

display margin_results, margin_matrix, domestic_matrix;





* ----------------------------------------
** 8. Conditional Domestic Surplus and Break-even Analysis
* ----------------------------------------

* To find the minimum DSI margin and maximum operating cost for domestic break-even
* DSI profit must be sufficient to offset producer surplus loss
* Positive domestic surplus does not imply actual compensation to producers
* This is not corporate break-even or an increase in total market welfare

set be_metric "domestic surplus break-even results"
   /fee_USD_t, demand_elasticity, supply_elasticity, revenue_USDm, PS_loss_USDm,
    min_margin_pct, max_opex_USDm, max_opex_pct_revenue,
    max_opex_USD_t, domestic_change_at_break_even_USDm/;

parameter
   break_even_results(ed,es,f,be_metric) "positive-fee break-even thresholds"
   break_even_main(ed,es,be_metric) "break-even at USD 5/ton"
   min_margin_matrix(f,ed,es) "minimum operating margin [percent]"
   max_opex_matrix(f,ed,es) "maximum tolerable operating cost [million USD]";

scalar
   ps_loss_case
   min_margin_case
   max_opex_case
   domestic_at_break_even;

* At zero fee, ratio thresholds are undefined; the no-DSI cost limit is zero
min_margin_matrix("f0",ed,es) = NA;
max_opex_matrix("f0",ed,es) = 0;

loop((ed,es,f)$positive_fee(f),

   revenue_case = scenario_results(ed,es,f,"dsi_revenue_USDm");
   ps_loss_case = -scenario_results(ed,es,f,"change_PS_USDm");

   min_margin_case = ps_loss_case/revenue_case;
   max_opex_case = revenue_case - ps_loss_case;
   domestic_at_break_even = min_margin_case*revenue_case - ps_loss_case;

*  Do not truncate the threshold: if margin > 100 percent or cost < 0,
*  domestic break-even is not possible with nonnegative operating costs
   break_even_results(ed,es,f,"fee_USD_t") = fee_value(f);
   break_even_results(ed,es,f,"demand_elasticity") = demand_value(ed);
   break_even_results(ed,es,f,"supply_elasticity") = supply_value(es);
   break_even_results(ed,es,f,"revenue_USDm") = revenue_case;
   break_even_results(ed,es,f,"PS_loss_USDm") = ps_loss_case;
   break_even_results(ed,es,f,"min_margin_pct") = 100*min_margin_case;
   break_even_results(ed,es,f,"max_opex_USDm") = max_opex_case;
   break_even_results(ed,es,f,"max_opex_pct_revenue") = 100*(1-min_margin_case);
   break_even_results(ed,es,f,"max_opex_USD_t") =
      max_opex_case/scenario_results(ed,es,f,"exports_Mt");
   break_even_results(ed,es,f,"domestic_change_at_break_even_USDm") = domestic_at_break_even;

   min_margin_matrix(f,ed,es) = 100*min_margin_case;
   max_opex_matrix(f,ed,es) = max_opex_case;

);

break_even_main(ed,es,be_metric) = break_even_results(ed,es,"f5",be_metric);

* Scenario counts
scalar n_market_cases, n_positive_fee_cases, n_margin_cases;
n_market_cases = card(ed)*card(es)*card(f);
n_positive_fee_cases = card(ed)*card(es)*card(positive_fee);
n_margin_cases = n_positive_fee_cases*card(m);

display break_even_main, break_even_results,
        min_margin_matrix, max_opex_matrix,
        n_market_cases, n_positive_fee_cases, n_margin_cases;





* ----------------------------------------
** 9. Sovereign Wealth Accumulation
* ----------------------------------------

* Illustrative investment of DSI operating profit into Danantara
* Use the main case with fee = 5, demand elasticity = -0.1, and supply elasticity = 0.4
* Assume all operating profit is invested at the end of each year
* Annual contributions and investment returns are constant
* Assume no initial investment, withdrawals, taxes, capex or financing
* Annual returns are informed by historical SWF performance
* SWF benchmarks: INA, Temasek, GIC, NBIM and ADIA
* Investment returns are assumptions, not Danantara forecasts

set ret "annual investment return scenarios" /ret4, ret6, ret8/;
set yr "investment horizons" /y5, y10, y20/;

parameter return_value(ret) "assumed annual investment return"
   /ret4 0.04, ret6 0.06, ret8 0.08/;

parameter horizon_years(yr) "investment horizon [years]"
   /y5 5, y10 10, y20 20/;

scalar swf_discount_rate "assumed annual discount rate" /0.08/;
scalar distribution_share "share of operating profit invested" /1/;

set swf_metric "sovereign wealth simulation results"
   /margin_pct, return_pct, years, annual_contribution_USDm,
    cumulative_contribution_USDm, investment_gain_USDm,
    future_value_USDm, present_value_USDm/;

parameter
   swf_results(m,ret,yr,swf_metric) "27 sovereign wealth scenarios"
   swf_base_return(m,yr) "future value at 6 percent return [million USD]"
   swf_high_margin(ret,yr) "future value at 75 percent margin [million USD]"
   swf_high_margin_pv(ret,yr) "present value at 75 percent margin [million USD]";

scalar annual_contribution, cumulative_contribution, future_wealth,
       investment_gain, present_wealth, n_swf_cases;

loop((m,ret,yr),

*  Annual contribution from DSI operating profit
   annual_contribution = distribution_share
                       * margin_results(m,"operating_profit_USDm");

   cumulative_contribution = annual_contribution*horizon_years(yr);

*  Future value using the ordinary annuity formula
   future_wealth = annual_contribution
                 * ((1+return_value(ret))**horizon_years(yr)-1)/return_value(ret);

   investment_gain = future_wealth - cumulative_contribution;

   present_wealth = future_wealth/(1+swf_discount_rate)**horizon_years(yr);

   swf_results(m,ret,yr,"margin_pct") = 100*margin_value(m);
   swf_results(m,ret,yr,"return_pct") = 100*return_value(ret);
   swf_results(m,ret,yr,"years") = horizon_years(yr);
   swf_results(m,ret,yr,"annual_contribution_USDm") = annual_contribution;
   swf_results(m,ret,yr,"cumulative_contribution_USDm") = cumulative_contribution;
   swf_results(m,ret,yr,"investment_gain_USDm") = investment_gain;
   swf_results(m,ret,yr,"future_value_USDm") = future_wealth;
   swf_results(m,ret,yr,"present_value_USDm") = present_wealth;

);

* Summary tables for investment sensitivity
swf_base_return(m,yr) = swf_results(m,"ret6",yr,"future_value_USDm");
swf_high_margin(ret,yr) = swf_results("m75",ret,yr,"future_value_USDm");
swf_high_margin_pv(ret,yr) = swf_results("m75",ret,yr,"present_value_USDm");

n_swf_cases = card(m)*card(ret)*card(yr);

display return_value, horizon_years, swf_discount_rate, distribution_share,
        swf_results, swf_base_return, swf_high_margin, swf_high_margin_pv,
        n_swf_cases;

* Sovereign wealth accumulation is not additional economic welfare
* Present value refers to the discounted terminal portfolio value





* ----------------------------------------
** Additional Elasticity Comparisons
* ----------------------------------------

* Higher demand responsiveness represents more alternatives for foreign buyers
* These are static comparisons, not estimates of long-term elasticities
* Keep supply elasticity at 0.4 for the two demand comparisons
* The last case uses unit elastic demand and supply for comparison
* All three cases use the main fee of 5 USD/ton

set k "additional elasticity cases" /ed1_es0p4, ed2_es0p4, ed1_es1/;

parameter comparison_demand(k) /ed1_es0p4 -1, ed2_es0p4 -2, ed1_es1 -1/;
parameter comparison_supply(k) /ed1_es0p4 0.4, ed2_es0p4 0.4, ed1_es1 1/;
parameter comparison_results(k,metric) "additional market results";

fee = fee_value("f5");

loop(k,

   e_r = comparison_demand(k);
   e_s = comparison_supply(k);

   b = pbar / (e_r*xbar);
   a = pbar - b*xbar;
   d = pbar / (e_s*xbar);
   c = pbar - d*xbar;

   X.l = xbar;
   solve with_dsi_fee using qcp maximizing equilibrium_potential;

   exports_fee = X.l;
   price_fee = a + b*exports_fee;
   net_price_fee = price_fee - fee;
   dsi_revenue_fee = fee*exports_fee;

   change_cs = (pbar - price_fee)*(xbar + exports_fee)/2;
   change_ps = (net_price_fee - pbar)*(xbar + exports_fee)/2;
   change_ts = change_cs + change_ps + dsi_revenue_fee;
   deadweight_loss = -change_ts;

   comparison_results(k,"fee_USD_t") = fee;
   comparison_results(k,"demand_elasticity") = e_r;
   comparison_results(k,"supply_elasticity") = e_s;
   comparison_results(k,"exports_Mt") = exports_fee;
   comparison_results(k,"buyer_price_USD_t") = price_fee;
   comparison_results(k,"net_price_USD_t") = net_price_fee;
   comparison_results(k,"dsi_revenue_USDm") = dsi_revenue_fee;
   comparison_results(k,"DWL_USDm") = deadweight_loss;
   comparison_results(k,"export_change_pct") = 100*(exports_fee/xbar - 1);
   comparison_results(k,"buyer_price_change") = price_fee - pbar;
   comparison_results(k,"exporter_net_price_change") = net_price_fee - pbar;
   comparison_results(k,"change_CS_USDm") = change_cs;
   comparison_results(k,"change_PS_USDm") = change_ps;
   comparison_results(k,"change_TS_USDm") = change_ts;
   comparison_results(k,"buyer_incidence_pct") = 100*(price_fee - pbar)/fee;
   comparison_results(k,"exporter_incidence_pct") = 100*(pbar - net_price_fee)/fee;

);

* Restore the benchmark assumptions before exporting results
e_r = demand_value("ed0p1");
e_s = supply_value("es0p4");
fee = fee_value("f5");
b = pbar / (e_r*xbar);
a = pbar - b*xbar;
d = pbar / (e_s*xbar);
c = pbar - d*xbar;

scalar n_comparison_cases, n_total_market_cases;
n_comparison_cases = card(k);
n_total_market_cases = n_market_cases + n_comparison_cases;

display comparison_results, n_comparison_cases, n_total_market_cases;





* ----------------------------------------
** 10. Export Results
* ----------------------------------------

* Save the economic results and scenario tables
execute_unload 'Final_results.gdx',
   vbar, xbar, pbar, e_r, e_s, f, ed, es, m, r, h, positive_fee,
   fee_value, demand_value, supply_value, margin_value, return_value, horizon_years,
   swf_discount_rate, distribution_share,
   metric, fin_metric, be_metric, swf_metric,
   main_results, elastic_baseline, scenario_results,
   fee_results, elastic_results, export_change_matrix, ps_loss_matrix, dwl_matrix,
   margin_results, margin_matrix, domestic_matrix,
   break_even_results, break_even_main, min_margin_matrix, max_opex_matrix,
   swf_results, swf_base_return, swf_high_margin, swf_high_margin_pv,
   n_market_cases, n_positive_fee_cases, n_margin_cases, n_swf_cases,
   k, comparison_demand, comparison_supply, comparison_results,
   n_comparison_cases, n_total_market_cases;

* Export flat CSV tables using native GAMS put statements
* One row per scenario; zero-fee incidence is explicitly marked NA
* All files are written to the GAMS working directory
file out_market /'Final_market_results.csv'/;
file out_margin /'Final_margin_results.csv'/;
file out_break_even /'Final_break_even_results.csv'/;
file out_swf /'Final_swf_results.csv'/;
file out_comparison /'Final_comparison_results.csv'/;

out_market.pw = 4096;
out_margin.pw = 4096;
out_break_even.pw = 4096;
out_swf.pw = 4096;
out_comparison.pw = 4096;

* 63 market cases, including nine no-fee baselines
put out_market;
put 'demand_case,supply_case,fee_case';
loop(metric, put ',' metric.tl:0;);
put /;
loop((ed,es,f),
   put ed.tl:0 ',' es.tl:0 ',' f.tl:0;
   loop(metric,
      put ',';
      if((fee_value(f) = 0) and
         (sameas(metric,'buyer_incidence_pct') or sameas(metric,'exporter_incidence_pct')),
         put 'NA';
      else
         put scenario_results(ed,es,f,metric):0:8;
      );
   );
   put /;
);
putclose out_market;

* 162 operating margin cases
put out_margin;
put 'demand_case,supply_case,fee_case,margin_case,demand_elasticity,supply_elasticity,fee_USD_t';
loop(fin_metric, put ',' fin_metric.tl:0;);
put /;
loop((ed,es,f,m)$positive_fee(f),
   put ed.tl:0 ',' es.tl:0 ',' f.tl:0 ',' m.tl:0 ',' demand_value(ed):0:4 ',' supply_value(es):0:4 ',' fee_value(f):0:4;
   loop(fin_metric, put ',' margin_matrix(ed,es,f,m,fin_metric):0:8;);
   put /;
);
putclose out_margin;

* 54 positive-fee domestic break-even thresholds
put out_break_even;
put 'demand_case,supply_case,fee_case';
loop(be_metric, put ',' be_metric.tl:0;);
put /;
loop((ed,es,f)$positive_fee(f),
   put ed.tl:0 ',' es.tl:0 ',' f.tl:0;
   loop(be_metric, put ',' break_even_results(ed,es,f,be_metric):0:8;);
   put /;
);
putclose out_break_even;

* 27 SWF investment scenarios at the benchmark fee and elasticity
put out_swf;
put 'margin_case,return_case,horizon_case,fee_USD_t,demand_elasticity,supply_elasticity,discount_rate_pct,distribution_share_pct';
loop(swf_metric, put ',' swf_metric.tl:0;);
put /;
loop((m,r,h),
   put m.tl:0 ',' r.tl:0 ',' h.tl:0 ',' fee_value('f5'):0:4 ','
       demand_value('ed0p1'):0:4 ',' supply_value('es0p4'):0:4 ',' (100*swf_discount_rate):0:4 ','
       (100*distribution_share):0:4;
   loop(swf_metric, put ',' swf_results(m,r,h,swf_metric):0:8;);
   put /;
);
putclose out_swf;

* Three additional elasticity comparisons
put out_comparison;
put 'comparison_case';
loop(metric, put ',' metric.tl:0;);
put /;
loop(k,
   put k.tl:0;
   loop(metric, put ',' comparison_results(k,metric):0:8;);
   put /;
);
putclose out_comparison;

$exit