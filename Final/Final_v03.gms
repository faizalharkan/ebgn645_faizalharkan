** Final Project - DSI export fee on Indonesian Ferronickel
** Phase 3 - Phase 2 market model plus sovereign wealth accumulation
** Retains the verified Phase 1 equilibrium and welfare formulation
** Market assumption: 1 commodity, 1 period, competitive exporters
** Using 2025 export data; elasticities and fees are assumed
** X = exports (million metric tons); P = USD per ton of product
** Revenue, cost, surplus, and profit are in million USD
** CS refers to surplus under foreign residual demand.
** Gross total surplus excludes real DSI operating costs and governance benefits.
** Operating margins are illustrative assumptions, not actual DSI margins.

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
** 5. Full Fee and Demand Elasticity Scenario Matrix
* ----------------------------------------

* Solve all seven fee levels for each of three demand elasticities.
* Each elasticity has its own no-fee welfare benchmark.
* The supply elasticity remains unchanged.

set s "fee scenarios" /f0, f0p5, f1, f3, f5, f7, f9/;
set t "elasticity scenarios" /e1, e2, e4/;
set positive_fee(s) "positive fee scenarios";

parameter fee_value(s) "DSI fee [USD/ton]"
   /f0 0, f0p5 0.5, f1 1, f3 3, f5 5, f7 7, f9 9/;

parameter elastic_value(t) "residual demand elasticity"
   /e1 -1, e2 -2, e4 -4/;

positive_fee(s) = yes$(fee_value(s) > 0);

set metric "market and welfare results"
   /fee_USD_t, elasticity, exports_Mt, buyer_price_USD_t,
    net_price_USD_t, consumer_surplus_USDm, exporter_surplus_USDm,
    dsi_revenue_USDm, total_surplus_USDm, DWL_USDm,
    export_change_pct, buyer_price_change, exporter_net_price_change,
    change_CS_USDm, change_PS_USDm, change_TS_USDm,
    buyer_incidence_pct, exporter_incidence_pct/;

parameter
   scenario_results(t,s,metric) "all 21 market equilibrium combinations"
   elastic_baseline(t,*) "analytical no-fee benchmark by elasticity"
   scenario_checks(t,s,*) "basic numerical consistency checks";

scalar
   exports_base_elastic
   price_base_elastic
   consumer_surplus_base_elastic
   exporter_surplus_base_elastic
   total_surplus_base_elastic
   tol_quantity /0.000001/
   tol_money /0.0001/
   tol_price /0.0001/
   tol_pct /0.001/;

loop(t,

   e_r = elastic_value(t);

*  Recalibrate inverse residual demand to the same observed benchmark.
   b = pbar / (e_r*xbar);
   a = pbar - b*xbar;

*  Analytical no-fee benchmark for this elasticity.
*  The numerical no-fee case is also solved in the inner loop.
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

   loop(s,

      fee = fee_value(s);
      X.l = xbar;

      solve with_dsi_fee using qcp maximizing equilibrium_potential;

      abort$(with_dsi_fee.solvestat ne 1 or
            (with_dsi_fee.modelstat ne 1 and with_dsi_fee.modelstat ne 2))
         "Scenario solve did not terminate at an optimum", t, s;

*     All fee and elasticity assumptions here imply an interior solution.
      abort$(X.l <= 0) "Interior solution required for welfare formulas", t, s;

*     Market outcomes
      price_fee = a + b*X.l;
      net_price_fee = price_fee - fee;
      exporter_surplus_fee = net_price_fee*X.l
                           - (c*X.l + 0.5*d*sqr(X.l));
      dsi_revenue_fee = fee*X.l;

*     Welfare before DSI operating costs
      consumer_surplus_fee = -0.5*b*sqr(X.l);
      total_surplus_fee = consumer_surplus_fee
                        + exporter_surplus_fee + dsi_revenue_fee;

      change_cs = consumer_surplus_fee - consumer_surplus_base_elastic;
      change_ps = exporter_surplus_fee - exporter_surplus_base_elastic;
      change_ts = total_surplus_fee - total_surplus_base_elastic;
      deadweight_loss = -change_ts;

      scenario_results(t,s,"fee_USD_t") = fee;
      scenario_results(t,s,"elasticity") = e_r;
      scenario_results(t,s,"exports_Mt") = X.l;
      scenario_results(t,s,"buyer_price_USD_t") = price_fee;
      scenario_results(t,s,"net_price_USD_t") = net_price_fee;
      scenario_results(t,s,"consumer_surplus_USDm") = consumer_surplus_fee;
      scenario_results(t,s,"exporter_surplus_USDm") = exporter_surplus_fee;
      scenario_results(t,s,"dsi_revenue_USDm") = dsi_revenue_fee;
      scenario_results(t,s,"total_surplus_USDm") = total_surplus_fee;
      scenario_results(t,s,"DWL_USDm") = deadweight_loss;
      scenario_results(t,s,"export_change_pct") = 100*(X.l/exports_base_elastic - 1);
      scenario_results(t,s,"buyer_price_change") = price_fee - price_base_elastic;
      scenario_results(t,s,"exporter_net_price_change") = net_price_fee - price_base_elastic;
      scenario_results(t,s,"change_CS_USDm") = change_cs;
      scenario_results(t,s,"change_PS_USDm") = change_ps;
      scenario_results(t,s,"change_TS_USDm") = change_ts;

*     Fee incidence is undefined when fee = 0.
      scenario_results(t,s,"buyer_incidence_pct") = NA;
      scenario_results(t,s,"exporter_incidence_pct") = NA;

      if(fee > 0,
         scenario_results(t,s,"buyer_incidence_pct") =
            100*(price_fee - price_base_elastic)/fee;
         scenario_results(t,s,"exporter_incidence_pct") =
            100*(price_base_elastic - net_price_fee)/fee;
      );

*     Basic checks for every equilibrium in the matrix.
      scenario_checks(t,s,"solver_status") = with_dsi_fee.solvestat;
      scenario_checks(t,s,"model_status") = with_dsi_fee.modelstat;
      scenario_checks(t,s,"quantity_residual") = X.l - (a-c-fee)/(d-b);
      scenario_checks(t,s,"equilibrium_residual") = net_price_fee - (c+d*X.l);
      scenario_checks(t,s,"welfare_residual") = change_cs + change_ps
                                             + dsi_revenue_fee - change_ts;
      scenario_checks(t,s,"DWL_residual") = deadweight_loss
                                         - 0.5*fee*(exports_base_elastic-X.l);
      scenario_checks(t,s,"incidence_residual") = NA;

      if(fee > 0,
         scenario_checks(t,s,"incidence_residual") =
              scenario_results(t,s,"buyer_incidence_pct")
            + scenario_results(t,s,"exporter_incidence_pct") - 100;
         abort$(abs(scenario_checks(t,s,"incidence_residual")) > tol_pct)
            "Fee incidence check failed", t, s;
      );

      abort$(abs(scenario_checks(t,s,"quantity_residual")) > tol_quantity or
             abs(scenario_checks(t,s,"equilibrium_residual")) > tol_price or
             abs(scenario_checks(t,s,"welfare_residual")) > tol_money or
             abs(scenario_checks(t,s,"DWL_residual")) > tol_money or
             deadweight_loss < -tol_money)
         "Scenario consistency check failed", t, s;

      if(fee = 0,
         abort$(abs(X.l-xbar) > tol_quantity or abs(price_fee-pbar) > tol_price)
            "No-fee calibration check failed", t;
      );

   );
);

* Restore benchmark inputs. X.l and other mutable result scalars
* still belong to the last solve; use stored parameters below.
e_r = elastic_value("e2");
b = pbar/(e_r*xbar);
a = pbar - b*xbar;
fee = fee_value("f5");

* Check the replicated main case against Sections 3 and 4.
abort$(abs(scenario_results("e2","f5","exports_Mt")
        - main_results("with_fee","exports_Mt")) > tol_quantity or
       abs(scenario_results("e2","f5","DWL_USDm")
        - main_results("with_fee","DWL_USDm")) > tol_money)
   "Main case replication failed";

display elastic_baseline, scenario_results, scenario_checks;

* ----------------------------------------
** 6. Fee and Demand Elasticity Sensitivity Results
* ----------------------------------------

* Extract the same two sensitivity tables as in Phase 1.
* Both tables use the common field names from scenario_results.
* No additional optimization is required.

parameter
   fee_results(s,metric) "fee sensitivity at elasticity -2"
   elastic_results(t,metric) "elasticity sensitivity at USD 5/ton"
   export_change_matrix(s,t) "export change [percent]"
   ps_loss_matrix(s,t) "producer surplus loss [million USD]"
   dwl_matrix(s,t) "deadweight loss [thousand USD]";

fee_results(s,metric) = scenario_results("e2",s,metric);
elastic_results(t,metric) = scenario_results(t,"f5",metric);

export_change_matrix(s,t) = scenario_results(t,s,"export_change_pct");
ps_loss_matrix(s,t) = -scenario_results(t,s,"change_PS_USDm");
dwl_matrix(s,t) = 1000*scenario_results(t,s,"DWL_USDm");

display fee_results, elastic_results,
        export_change_matrix, ps_loss_matrix, dwl_matrix;

* ----------------------------------------
** 7. DSI Operating Margin Sensitivity
* ----------------------------------------

* Operating margins of 25%, 50%, and 75% are assumed, not estimated.
* Operating cost = (1-margin)*gross revenue.
* Operating profit = margin*gross revenue.
* Costs are assumed incremental real resource costs for net welfare.
* Assume full domestic attribution of producer surplus and DSI profit.
* Conditional domestic surplus is not Indonesian national welfare.
* Governance benefits, corporate taxes, capex and financing are excluded.
* The no-DSI / zero-fee benchmark has no incremental DSI costs.
* Only the 18 positive-fee scenarios receive margin sensitivity analysis.

set m "DSI margin scenarios" /m25, m50, m75/;
parameter margin_value(m) "assumed DSI operating margin"
   /m25 0.25, m50 0.50, m75 0.75/;

set fin_metric "financial and net welfare results"
   /margin_pct, revenue_USDm, operating_cost_USDm, operating_profit_USDm,
    change_PS_USDm, DWL_USDm, domestic_surplus_change_USDm,
    net_total_surplus_USDm, net_total_surplus_change_USDm,
    required_governance_benefit_USDm/;

parameter
   margin_matrix(t,s,m,fin_metric) "54 positive fee and operating margin cases"
   margin_results(m,fin_metric) "main case operating margin sensitivity"
   domestic_matrix(t,s,m) "conditional domestic surplus change [million USD]";

scalar
   revenue_case
   cost_case
   profit_case
   ps_change_case
   dwl_case
   domestic_change_case
   net_ts_change_case;

loop((t,s,m)$positive_fee(s),

   revenue_case = scenario_results(t,s,"dsi_revenue_USDm");
   ps_change_case = scenario_results(t,s,"change_PS_USDm");
   dwl_case = scenario_results(t,s,"DWL_USDm");

   cost_case = (1-margin_value(m))*revenue_case;
   profit_case = margin_value(m)*revenue_case;

*  Conditional domestic surplus: producer surplus change plus DSI profit.
   domestic_change_case = ps_change_case + profit_case;

*  Total modeled market surplus including foreign buyers, after costs.
   net_ts_change_case = -dwl_case - cost_case;

   margin_matrix(t,s,m,"margin_pct") = 100*margin_value(m);
   margin_matrix(t,s,m,"revenue_USDm") = revenue_case;
   margin_matrix(t,s,m,"operating_cost_USDm") = cost_case;
   margin_matrix(t,s,m,"operating_profit_USDm") = profit_case;
   margin_matrix(t,s,m,"change_PS_USDm") = ps_change_case;
   margin_matrix(t,s,m,"DWL_USDm") = dwl_case;
   margin_matrix(t,s,m,"domestic_surplus_change_USDm") = domestic_change_case;
   margin_matrix(t,s,m,"net_total_surplus_USDm") =
      scenario_results(t,s,"total_surplus_USDm") - cost_case;
   margin_matrix(t,s,m,"net_total_surplus_change_USDm") = net_ts_change_case;

*  Minimum incremental real governance benefit needed for market welfare
*  break-even; not an estimate of actual governance benefits.
   margin_matrix(t,s,m,"required_governance_benefit_USDm") =
      max(0,dwl_case + cost_case);

   domestic_matrix(t,s,m) = domestic_change_case;

   abort$(abs(revenue_case-cost_case-profit_case) > tol_money or
          abs(net_ts_change_case - (scenario_results(t,s,"change_CS_USDm")
              + domestic_change_case)) > tol_money)
      "Operating margin accounting check failed", t, s, m;
);

* Main case: fee = 5, residual demand elasticity = -2.
margin_results(m,fin_metric) = margin_matrix("e2","f5",m,fin_metric);

display margin_results, margin_matrix, domestic_matrix;

* ----------------------------------------
** 8. Conditional Domestic Surplus and Break-even Analysis
* ----------------------------------------

* Find the minimum operating margin and maximum tolerable operating cost
* such that the loss in producer surplus is offset by DSI operating profit.
* These are domestic surplus thresholds, NOT corporate break-even margins.
* Neither threshold implies total market welfare increases.
* No fee optimization or actual operating cost calibration is performed.

set be_metric "domestic surplus break-even results"
   /fee_USD_t, elasticity, revenue_USDm, PS_loss_USDm,
    min_margin_pct, max_opex_USDm, max_opex_pct_revenue,
    max_opex_USD_t, domestic_change_at_break_even_USDm/;

parameter
   break_even_results(t,s,be_metric) "positive-fee break-even thresholds"
   break_even_main(t,be_metric) "break-even at USD 5/ton"
   min_margin_matrix(s,t) "minimum operating margin [percent]"
   max_opex_matrix(s,t) "maximum tolerable operating cost [million USD]";

scalar
   ps_loss_case
   min_margin_case
   max_opex_case
   break_even_check;

* At zero fee, ratio thresholds are undefined; the no-DSI cost limit is zero.
min_margin_matrix("f0",t) = NA;
max_opex_matrix("f0",t) = 0;

loop((t,s)$positive_fee(s),

   revenue_case = scenario_results(t,s,"dsi_revenue_USDm");
   ps_loss_case = -scenario_results(t,s,"change_PS_USDm");

   abort$(revenue_case <= 0) "Positive revenue required for break-even", t, s;

   min_margin_case = ps_loss_case/revenue_case;
   max_opex_case = revenue_case - ps_loss_case;
   break_even_check = min_margin_case*revenue_case - ps_loss_case;

*  Do not truncate the threshold: if margin > 100 percent or cost < 0,
*  domestic break-even is not possible with nonnegative operating costs.
   break_even_results(t,s,"fee_USD_t") = fee_value(s);
   break_even_results(t,s,"elasticity") = elastic_value(t);
   break_even_results(t,s,"revenue_USDm") = revenue_case;
   break_even_results(t,s,"PS_loss_USDm") = ps_loss_case;
   break_even_results(t,s,"min_margin_pct") = 100*min_margin_case;
   break_even_results(t,s,"max_opex_USDm") = max_opex_case;
   break_even_results(t,s,"max_opex_pct_revenue") = 100*(1-min_margin_case);
   break_even_results(t,s,"max_opex_USD_t") =
      max_opex_case/scenario_results(t,s,"exports_Mt");
   break_even_results(t,s,"domestic_change_at_break_even_USDm") = break_even_check;

   min_margin_matrix(s,t) = 100*min_margin_case;
   max_opex_matrix(s,t) = max_opex_case;

   abort$(abs(break_even_check) > tol_money)
      "Domestic surplus break-even check failed", t, s;
);

break_even_main(t,be_metric) = break_even_results(t,"f5",be_metric);

* Compact output counts for Phase 2.
scalar n_market_cases, n_positive_fee_cases, n_margin_cases;
n_market_cases = card(t)*card(s);
n_positive_fee_cases = card(t)*card(positive_fee);
n_margin_cases = n_positive_fee_cases*card(m);

display break_even_main, break_even_results,
        min_margin_matrix, max_opex_matrix,
        n_market_cases, n_positive_fee_cases, n_margin_cases;

* ----------------------------------------
** 9. Sovereign Wealth Accumulation
* ----------------------------------------

* Illustrative financial extension, not additional economic welfare.
* Use the main Phase 2 case: fee = 5 USD/t, demand elasticity = -2.
* Assume 100 percent of operating profit is available for distribution
* to Danantara and invested at the end of each year.
* Annual contribution and nominal USD investment return are constant.
* Initial portfolio = 0; no withdrawals, taxes, capex or financing.
* Discount rate and investment returns are illustrative, not forecasts.
* No additional market equilibrium solves are needed.

set r "annual investment return scenarios" /r4, r6p3, r8/;
set h "investment horizons" /y5, y10, y20/;

parameter return_value(r) "assumed annual investment return"
   /r4 0.04, r6p3 0.063, r8 0.08/;

parameter horizon_years(h) "investment horizon [years]"
   /y5 5, y10 10, y20 20/;

scalar swf_discount_rate "assumed annual nominal USD discount rate" /0.08/;
scalar distribution_share "assumed share of operating profit invested" /1/;

set swf_metric "sovereign wealth simulation results"
   /margin_pct, return_pct, years, annual_contribution_USDm,
    cumulative_contribution_USDm, investment_gain_USDm,
    future_value_USDm, present_value_USDm/;

parameter
   swf_results(m,r,h,swf_metric) "27 sovereign wealth scenarios"
   swf_base_return(m,h) "future value at 6.3 percent return [million USD]"
   swf_high_margin(r,h) "future value at 75 percent margin [million USD]"
   swf_high_margin_pv(r,h) "present value at 75 percent margin [million USD]";

scalar annual_contribution, cumulative_contribution, future_wealth,
       investment_gain, present_wealth, n_swf_cases;

loop((m,r,h),

*  Read stored Phase 2 benchmark profits, not the last scenario's scalars.
   annual_contribution = distribution_share
                       * margin_results(m,"operating_profit_USDm");

   cumulative_contribution = annual_contribution*horizon_years(h);

*  Ordinary annuity: contributions occur at the end of each year.
   future_wealth = annual_contribution
                 * ((1+return_value(r))**horizon_years(h)-1)/return_value(r);

   investment_gain = future_wealth - cumulative_contribution;
   present_wealth = future_wealth/(1+swf_discount_rate)**horizon_years(h);

   swf_results(m,r,h,"margin_pct") = 100*margin_value(m);
   swf_results(m,r,h,"return_pct") = 100*return_value(r);
   swf_results(m,r,h,"years") = horizon_years(h);
   swf_results(m,r,h,"annual_contribution_USDm") = annual_contribution;
   swf_results(m,r,h,"cumulative_contribution_USDm") = cumulative_contribution;
   swf_results(m,r,h,"investment_gain_USDm") = investment_gain;
   swf_results(m,r,h,"future_value_USDm") = future_wealth;
   swf_results(m,r,h,"present_value_USDm") = present_wealth;

*  Basic consistency check: with positive returns, FV >= contributions.
   abort$(future_wealth < cumulative_contribution-tol_money or
          present_wealth > future_wealth+tol_money)
      "Sovereign wealth accounting check failed", m, r, h;
);

* Compact tables for the main presentation.
swf_base_return(m,h) = swf_results(m,"r6p3",h,"future_value_USDm");
swf_high_margin(r,h) = swf_results("m75",r,h,"future_value_USDm");
swf_high_margin_pv(r,h) = swf_results("m75",r,h,"present_value_USDm");

n_swf_cases = card(m)*card(r)*card(h);

display return_value, horizon_years, swf_discount_rate, distribution_share,
        swf_results, swf_base_return, swf_high_margin, swf_high_margin_pv,
        n_swf_cases;

* Do not add sovereign portfolio assets to Phase 2 economic surplus.
* PV is the discounted terminal asset balance, not an incremental social NPV.

$exit