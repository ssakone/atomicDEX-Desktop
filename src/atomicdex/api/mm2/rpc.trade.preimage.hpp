#pragma once

//! STD
#include <optional>
#include <string>

//! Deps
#include <entt/core/attribute.h>
#include <nlohmann/json_fwd.hpp>

//! Project Headers
#include "atomicdex/api/mm2/fraction.hpp"

namespace mm2::api
{
    struct trade_preimage_request
    {
        std::string         base_coin;
        std::string         rel_coin;
        std::string         swap_method;
        std::string         volume;
        std::optional<bool> max;
    };

    ENTT_API void to_json(nlohmann::json& j, const trade_preimage_request& request);

    struct coin_fee
    {
        std::string coin;
        std::string amount;
        fraction    amount_fraction;
    };

    ENTT_API void from_json(const nlohmann::json& j, coin_fee& fee);

    struct trade_preimage_answer_success
    {
        coin_fee                   base_coin_fee;
        coin_fee                   rel_coin_fee;
        std::optional<coin_fee>    fee_to_send_taker_fee;
        std::optional<std::string> taker_fee;
        std::optional<fraction>    taker_fee_fraction;
        std::optional<std::string> volume;
        std::optional<fraction>    volume_fraction;
    };

    ENTT_API void from_json(const nlohmann::json& j, trade_preimage_answer_success& answer);

    struct trade_preimage_answer
    {
        std::optional<trade_preimage_answer_success> result;
        std::optional<std::string>                   error;
        int                                          rpc_result_code;
        std::string                                  raw_result;
    };

    ENTT_API void from_json(const nlohmann::json& j, trade_preimage_answer& answer);
} // namespace mm2::api

namespace atomic_dex
{
    using t_trade_preimage_request        = ::mm2::api::trade_preimage_request;
    using t_trade_preimage_answer         = ::mm2::api::trade_preimage_answer;
    using t_trade_preimage_answer_success = ::mm2::api::trade_preimage_answer_success;
} // namespace atomic_dex