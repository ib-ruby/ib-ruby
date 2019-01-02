=begin
taken from the python-client code

Copyright (C) 2016 Interactive Brokers LLC. All rights reserved.  This code is
subject to the terms and conditions of the IB API Non-Commercial License or the
 IB API Commercial License, as applicable.



The known server versions.
=end

known_servers = {
#min_server_ver_real_time_bars       => 34,
#min_server_ver_scale_orders         => 35,
#min_server_ver_snapshot_mkt_data    => 35,
#min_server_ver_sshort_combo_legs    => 35,
#min_server_ver_what_if_orders       => 36,
#min_server_ver_contract_conid       => 37,
:min_server_ver_pta_orders             => 39,
:min_server_ver_fundamental_data       => 40,
:min_server_ver_under_comp             => 40,
:min_server_ver_contract_data_chain    => 40,
:min_server_ver_scale_orders2          => 40,
:min_server_ver_algo_orders            => 41,
:min_server_ver_execution_data_chain   => 42,
:min_server_ver_not_held               => 44,
:min_server_ver_sec_id_type            => 45,
:min_server_ver_place_order_conid      => 46,
:min_server_ver_req_mkt_data_conid     => 47,
:min_server_ver_req_calc_implied_volat => 49,
:min_server_ver_req_calc_option_price  => 50,
:min_server_ver_sshortx_old            => 51,
:min_server_ver_sshortx                => 52,
:min_server_ver_req_global_cancel      => 53,
:min_server_ver_hedge_orders           => 54,
:min_server_ver_req_market_data_type   => 55,
:min_server_ver_opt_out_smart_routing  => 56,
:min_server_ver_smart_combo_routing_params => 57,
:min_server_ver_delta_neutral_conid    => 58,
:min_server_ver_scale_orders3          => 60,
:min_server_ver_order_combo_legs_price => 61,
:min_server_ver_trailing_percent       => 62,
:min_server_ver_delta_neutral_open_close => 66,
:min_server_ver_positions              => 67,
:min_server_ver_account_summary        => 67,
:min_server_ver_trading_class          => 68,
:min_server_ver_scale_table            => 69,
:min_server_ver_linking                => 70,
:min_server_ver_algo_id                => 71,
:min_server_ver_optional_capabilities  => 72,
:min_server_ver_order_solicited        => 73,
:min_server_ver_linking_auth           => 74,
:min_server_ver_primaryexch            => 75,
:min_server_ver_randomize_size_and_price => 76,
:min_server_ver_fractional_positions   => 101,
:min_server_ver_pegged_to_benchmark    => 102,
:min_server_ver_models_support         => 103,
:min_server_ver_sec_def_opt_params_req => 104,
:min_server_ver_ext_operator           => 105,
:min_server_ver_soft_dollar_tier       => 106,
:min_server_ver_req_family_codes       => 107,
:min_server_ver_req_matching_symbols   => 108,
:min_server_ver_past_limit             => 109,
:min_server_ver_md_size_multiplier     => 110,
:min_server_ver_cash_qty               => 111,
:min_server_ver_req_mkt_depth_exchanges => 112,
:min_server_ver_tick_news              => 113,
:min_server_ver_req_smart_components   => 114,
:min_server_ver_req_news_providers     => 115,
:min_server_ver_req_news_article       => 116,
:min_server_ver_req_historical_news    => 117,
:min_server_ver_req_head_timestamp     => 118,
:min_server_ver_req_histogram          => 119,
:min_server_ver_service_data_type      => 120,
:min_server_ver_agg_group              => 121,
:min_server_ver_underlying_info        => 122,
:min_server_ver_cancel_headtimestamp   => 123,
:min_server_ver_synt_realtime_bars     => 124,
:min_server_ver_cfd_reroute            => 125,
:min_server_ver_market_rules           => 126,
:min_server_ver_pnl                    => 127,
:min_server_ver_news_query_origins     => 128,
:min_server_ver_unrealized_pnl         => 129,
:min_server_ver_historical_ticks       => 130,
:min_server_ver_market_cap_price       => 131,
:min_server_ver_pre_open_bid_ask       => 132,
:min_server_ver_real_expiration_date   => 134,
:min_server_ver_realized_pnl           => 135,
:min_server_ver_last_liquidity         => 136,
:min_server_ver_tick_by_tick           => 137,
:min_server_ver_decision_maker         => 138,
:min_server_ver_mifid_execution        => 139,
:min_server_ver_tick_by_tick_ignore_size => 140,
:min_server_ver_auto_price_for_hedge     => 141,
:min_server_ver_what_if_ext_fields       => 142,
:min_server_ver_scanner_generic_opts     => 143,
:min_server_ver_api_bind_order           => 144,
:min_server_ver_order_container          => 145, ### > Version Field in Order dropped
:min_server_ver_smart_depth              => 146,
:min_server_ver_remove_null_all_casting  => 147,
:min_server_ver_d_peg_orders             => 148




}
# 100+ messaging */
# 100 = enhanced handshake, msg length prefixes

MIN_CLIENT_VER = 100
MAX_CLIENT_VER = 137 #known_servers[:min_server_ver_d_peg_orders]

# imessages/outgoing/request_tick_Data is prepared for change to ver. 140 , its commented for now
