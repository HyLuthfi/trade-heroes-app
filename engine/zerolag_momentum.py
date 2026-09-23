#!/usr/bin/env python3
"""
Zero-Lag ATR Momentum & Volatility Expansion Sensor (Hermes Quant Toolkit)
Faithfully ported from Ken's "Hyfhi Logic" Pine Script engine.

Computes:
1. Zero-Lag EMA Basis (Lag-free trend tracking)
2. ATR Volatility Expansion Envelope (Max ATR over 3x period * multiplier)
3. 70-Bar Cumulative Momentum Scoring (-70 to +70)
4. Breakout Expansion State vs Band Compression

Engineered for Hermes Agent & EF Terminal. Zero hardcoded trading signals.
"""

import sys
import os
import json
import math
import argparse
import urllib.request
from datetime import datetime


def fetch_binance_klines(symbol: str, interval: str, limit: int = 300):
    url = f"https://api.binance.com/api/v3/klines?symbol={symbol}&interval={interval}&limit={limit}"
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) EF-Terminal-ZeroLag/2.0"},
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            candles = []
            for item in data:
                candles.append({
                    "time": int(item[0]) // 1000,
                    "open": float(item[1]),
                    "high": float(item[2]),
                    "low": float(item[3]),
                    "close": float(item[4]),
                    "volume": float(item[5]),
                })
            return candles
    except Exception:
        return None


def fetch_yahoo_klines(symbol: str, interval: str, limit: int = 250):
    tf_map = {"1m": "1m", "5m": "5m", "15m": "15m", "1h": "60m", "4h": "1d", "1d": "1d"}
    y_interval = tf_map.get(interval, "15m")
    y_range = "5d" if y_interval in ["1m", "5m", "15m"] else "1mo"
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}?interval={y_interval}&range={y_range}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            raw = json.loads(resp.read().decode("utf-8"))
            result = raw.get("chart", {}).get("result")
            if not result:
                return None
            res0 = result[0]
            timestamps = res0.get("timestamp", [])
            quote = res0.get("indicators", {}).get("quote", [{}])[0]
            opens = quote.get("open", [])
            highs = quote.get("high", [])
            lows = quote.get("low", [])
            closes = quote.get("close", [])
            volumes = quote.get("volume", [])

            candles = []
            for i in range(len(timestamps)):
                o, h, l, c = opens[i], highs[i], lows[i], closes[i]
                v = volumes[i] if i < len(volumes) else 0
                if None in (o, h, l, c):
                    continue
                candles.append({
                    "time": int(timestamps[i]),
                    "open": float(o),
                    "high": float(h),
                    "low": float(l),
                    "close": float(c),
                    "volume": float(v or 0),
                })
            return candles[-limit:]
    except Exception:
        return None


def calc_ema_series(values: list[float], period: int) -> list[float]:
    if len(values) < period:
        return [values[-1]] * len(values)
    k = 2.0 / (period + 1)
    ema = [sum(values[:period]) / period]
    for val in values[period:]:
        ema.append(val * k + ema[-1] * (1 - k))
    padding = [ema[0]] * (period - 1)
    return padding + ema


def calc_atr_series(candles: list[dict], period: int = 50) -> list[float]:
    """Calculate RMA True Range series matching Pine Script ta.atr()."""
    total = len(candles)
    if total < 2:
        return [0.0] * total

    tr_list = [candles[0]["high"] - candles[0]["low"]]
    for i in range(1, total):
        c = candles[i]
        prev_close = candles[i - 1]["close"]
        tr = max(
            c["high"] - c["low"],
            abs(c["high"] - prev_close),
            abs(c["low"] - prev_close),
        )
        tr_list.append(tr)

    # Pine script ta.atr uses RMA (alpha = 1 / period)
    alpha = 1.0 / period
    atr_series = [sum(tr_list[:period]) / period]
    for i in range(period, total):
        atr_series.append(alpha * tr_list[i] + (1 - alpha) * atr_series[-1])

    padding = [atr_series[0]] * (period - 1)
    return padding + atr_series


def get_decimals(p: float) -> int:
    if p < 0.00001: return 8
    if p < 0.001: return 7
    if p < 0.1: return 6
    if p < 10: return 4
    return 2


def compute_zerolag_momentum(
    candles: list[dict],
    length: int = 50,
    volatility_mult: float = 1.5,
    loop_start: int = 1,
    loop_end: int = 70,
    threshold_up: int = 5,
    threshold_down: int = -5,
) -> dict:
    total = len(candles)
    min_required = max(length * 3 + 10, loop_end + 10)
    if total < min_required:
        return {"error": f"Insufficient bars ({total} available, {min_required} required)"}

    closes = [c["close"] for c in candles]
    raw_close = closes[-1]
    dec = get_decimals(raw_close)
    curr_price = round(raw_close, dec)

    # 1. Zero-Lag EMA Calculation
    # lag = math.floor((length - 1) / 2)
    # zl_basis = ta.ema(close + (close - close[lag]), length)
    lag = (length - 1) // 2
    zl_data = []
    for i in range(total):
        if i < lag:
            zl_data.append(closes[i])
        else:
            zl_data.append(closes[i] + (closes[i] - closes[i - lag]))

    zl_basis_series = calc_ema_series(zl_data, length)
    curr_zl = round(zl_basis_series[-1], dec)

    # 2. Volatility Envelope Calculation
    # volatility = ta.highest(ta.atr(length), length * 3) * volatility_mult
    atr_series = calc_atr_series(candles, length)
    lookback_atr = length * 3
    recent_atr_slice = atr_series[-lookback_atr:] if len(atr_series) >= lookback_atr else atr_series
    max_recent_atr = max(recent_atr_slice)
    volatility = round(max_recent_atr * volatility_mult, dec)

    upper_band = round(curr_zl + volatility, dec)
    lower_band = round(curr_zl - volatility, dec)

    # 3. For-Loop Cumulative Momentum Scoring
    # for i = loop_start to loop_end by 1: sum += (basis_price > basis_price[i] ? 1 : -1)
    score = 0
    curr_basis = zl_basis_series[-1]
    for i in range(loop_start, loop_end + 1):
        idx = len(zl_basis_series) - 1 - i
        if idx >= 0:
            past_basis = zl_basis_series[idx]
            if curr_basis > past_basis:
                score += 1
            else:
                score -= 1

    # 4. State & Expansion Classification
    is_bull_expansion = score > threshold_up and curr_price > upper_band
    is_bear_expansion = score < threshold_down and curr_price < lower_band

    if is_bull_expansion:
        expansion_state = "BULLISH_VOLATILITY_EXPANSION"
        bias = "EXPANSIVE_BULLISH"
    elif is_bear_expansion:
        expansion_state = "BEARISH_VOLATILITY_EXPANSION"
        bias = "EXPANSIVE_BEARISH"
    elif curr_price > upper_band:
        expansion_state = "ABOVE_UPPER_BAND_LOW_MOMENTUM"
        bias = "MOMENTUM_DIVERGENCE_BULL"
    elif curr_price < lower_band:
        expansion_state = "BELOW_LOWER_BAND_LOW_MOMENTUM"
        bias = "MOMENTUM_DIVERGENCE_BEAR"
    else:
        expansion_state = "COMPRESSED_INSIDE_BANDS"
        bias = "CONSOLIDATION_RANGING"

    # Distances
    dist_to_upper_pts = round(upper_band - curr_price, dec)
    dist_to_upper_pct = round((dist_to_upper_pts / curr_price) * 100, 2) if curr_price > 0 else 0.0
    dist_to_lower_pts = round(curr_price - lower_band, dec)
    dist_to_lower_pct = round((dist_to_lower_pts / curr_price) * 100, 2) if curr_price > 0 else 0.0
    dist_to_basis_pts = round(curr_price - curr_zl, dec)
    dist_to_basis_pct = round((dist_to_basis_pts / curr_price) * 100, 2) if curr_price > 0 else 0.0

    return {
        "current_price": curr_price,
        "zerolag_basis": curr_zl,
        "volatility_envelope": {
            "volatility_span_pts": volatility,
            "upper_band": upper_band,
            "lower_band": lower_band,
            "max_recent_atr": round(max_recent_atr, 2),
            "volatility_multiplier": volatility_mult,
        },
        "momentum_engine": {
            "cumulative_score": score,
            "max_score_possible": loop_end - loop_start + 1,
            "threshold_up": threshold_up,
            "threshold_down": threshold_down,
            "is_score_bullish": score > threshold_up,
            "is_score_bearish": score < threshold_down,
        },
        "state": {
            "expansion_state": expansion_state,
            "bias_interpretation": bias,
            "is_bullish_expansion": is_bull_expansion,
            "is_bearish_expansion": is_bear_expansion,
        },
        "distance_metrics": {
            "dist_to_upper_band_pts": dist_to_upper_pts,
            "dist_to_upper_band_pct": dist_to_upper_pct,
            "dist_to_lower_band_pts": dist_to_lower_pts,
            "dist_to_lower_band_pct": dist_to_lower_pct,
            "dist_to_basis_pts": dist_to_basis_pts,
            "dist_to_basis_pct": dist_to_basis_pct,
        },
    }


def main():
    parser = argparse.ArgumentParser(description="Zero-Lag ATR Momentum & Expansion Sensor (Hyfhi Logic)")
    parser.add_argument("--symbol", "-s", default="BTCUSDT", help="Symbol, e.g. BTCUSDT, ETHUSDT")
    parser.add_argument("--timeframe", "-tf", default="15m", help="Timeframe (e.g. 5m, 15m, 1h, 4h)")
    parser.add_argument("--length", type=int, default=50, help="Zero-Lag EMA Length (default: 50)")
    parser.add_argument("--mult", type=float, default=1.5, help="Volatility Multiplier (default: 1.5)")
    parser.add_argument("--raw", action="store_true", help="Print raw JSON output only")

    args = parser.parse_args()
    sym = args.symbol.upper().strip()
    tf = args.timeframe.lower().strip()

    if "XAU" in sym or "GOLD" in sym:
        candles = fetch_binance_klines("PAXGUSDT", tf, 320)
        if not candles:
            candles = fetch_yahoo_klines(sym, tf, 250)
    else:
        candles = fetch_binance_klines(sym, tf, 320)
        if not candles:
            candles = fetch_yahoo_klines(sym, tf, 250)

    if not candles:
        print(json.dumps({"error": f"Failed to fetch market data for {sym}"}, indent=2))
        return

    result = compute_zerolag_momentum(
        candles,
        length=args.length,
        volatility_mult=args.mult,
        loop_start=1,
        loop_end=70,
        threshold_up=5,
        threshold_down=-5,
    )

    output = {
        "symbol": sym,
        "timeframe": tf,
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S WIB"),
        **result,
    }

    if args.raw or not sys.stdout.isatty():
        print(json.dumps(output, indent=2, ensure_ascii=False))
    else:
        env = result["volatility_envelope"]
        mom = result["momentum_engine"]
        st = result["state"]
        dm = result["distance_metrics"]

        print(f"\n========================================================")
        print(f"  ZERO-LAG ATR MOMENTUM ENGINE: {sym} ({tf.upper()})")
        print(f"  Waktu: {output['timestamp']}")
        print(f"========================================================")
        print(f"Current Price: ${result['current_price']:,.2f}")
        print(f"Zero-Lag Basis: ${result['zerolag_basis']:,.2f} (Delta: {dm['dist_to_basis_pct']:+}%)")
        print(f"Upper Envelope (+Vol): ${env['upper_band']:,.2f} (Dist: {dm['dist_to_upper_band_pct']}%)")
        print(f"Lower Envelope (-Vol): ${env['lower_band']:,.2f} (Dist: {dm['dist_to_lower_band_pct']}%)")
        print(f"--------------------------------------------------------")
        print(f"MOMENTUM SCORE: {mom['cumulative_score']:+d} / {mom['max_score_possible']} (Threshold: ±5)")
        print(f"EXPANSION STATE: [{st['expansion_state']}]")
        print(f"INTERPRETASI: {st['bias_interpretation']}")
        print(f"========================================================\n")


if __name__ == "__main__":
    main()
