#!/usr/bin/env python3
"""
SMC & Institutional Structure Sensor (Hermes Quant Toolkit)
Combines LuxAlgo's precision Order Block & Breaker Block Engine
with 3-candle Fair Value Gap (FVG) detection and Unicorn Confluence Overlaps.

Engineered for Hermes Agent & EF Terminal.
"""

import sys
import os
import json
import argparse
import urllib.request
from datetime import datetime


def fetch_binance_klines(symbol: str, interval: str, limit: int = 350):
    url = f"https://api.binance.com/api/v3/klines?symbol={symbol}&interval={interval}&limit={limit}"
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) EF-Terminal-SMC/2.0"},
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


# ==========================================
# 1. FAIR VALUE GAP (FVG) EXTRACTOR
# ==========================================

def get_decimals(p: float) -> int:
    if p < 0.00001: return 8
    if p < 0.001: return 7
    if p < 0.1: return 6
    if p < 10: return 4
    return 2


def extract_fvgs(candles: list[dict], min_gap_pct: float = 0.04):
    """
    Extract 3-candle Fair Value Gaps and track mitigation state.
    """
    total = len(candles)
    if total < 5:
        return []

    curr_price = candles[-1]["close"]
    dec = get_decimals(curr_price)
    fvgs = []

    for i in range(2, total):
        c0 = candles[i - 2]
        c1 = candles[i - 1] # Displacement candle
        c2 = candles[i]

        # 1. Bullish FVG: Low of candle 2 is higher than High of candle 0
        if c2["low"] > c0["high"]:
            gap_bottom = c0["high"]
            gap_top = c2["low"]
            gap_size = gap_top - gap_bottom
            gap_pct = (gap_size / curr_price) * 100

            if gap_pct >= min_gap_pct:
                mitigated = False
                partial = False
                deepest_retrace = gap_top

                for k in range(i + 1, total):
                    sub_low = candles[k]["low"]
                    if sub_low <= gap_bottom:
                        mitigated = True
                        deepest_retrace = gap_bottom
                        break
                    elif sub_low < gap_top:
                        partial = True
                        if sub_low < deepest_retrace:
                            deepest_retrace = sub_low

                status = "MITIGATED" if mitigated else ("PARTIALLY_MITIGATED" if partial else "UNMITIGATED")

                fvgs.append({
                    "time": c1["time"],
                    "type": "BULLISH",
                    "top": round(gap_top, dec),
                    "bottom": round(gap_bottom, dec),
                    "mid": round((gap_top + gap_bottom) / 2, dec),
                    "gap_size_pts": round(gap_size, dec),
                    "gap_pct": round(gap_pct, 2),
                    "status": status,
                    "deepest_touch": round(deepest_retrace, dec) if partial else None,
                    "dist_pts": round(curr_price - gap_top, dec),
                    "dist_pct": round(((curr_price - gap_top) / curr_price) * 100, 2),
                })

        # 2. Bearish FVG: High of candle 2 is lower than Low of candle 0
        elif c2["high"] < c0["low"]:
            gap_top = c0["low"]
            gap_bottom = c2["high"]
            gap_size = gap_top - gap_bottom
            gap_pct = (gap_size / curr_price) * 100

            if gap_pct >= min_gap_pct:
                mitigated = False
                partial = False
                highest_retrace = gap_bottom

                for k in range(i + 1, total):
                    sub_high = candles[k]["high"]
                    if sub_high >= gap_top:
                        mitigated = True
                        highest_retrace = gap_top
                        break
                    elif sub_high > gap_bottom:
                        partial = True
                        if sub_high > highest_retrace:
                            highest_retrace = sub_high

                status = "MITIGATED" if mitigated else ("PARTIALLY_MITIGATED" if partial else "UNMITIGATED")

                fvgs.append({
                    "time": c1["time"],
                    "type": "BEARISH",
                    "top": round(gap_top, dec),
                    "bottom": round(gap_bottom, dec),
                    "mid": round((gap_top + gap_bottom) / 2, dec),
                    "gap_size_pts": round(gap_size, dec),
                    "gap_pct": round(gap_pct, 2),
                    "status": status,
                    "highest_touch": round(highest_retrace, dec) if partial else None,
                    "dist_pts": round(gap_bottom - curr_price, dec),
                    "dist_pct": round(((gap_bottom - curr_price) / curr_price) * 100, 2),
                })

    return fvgs


# ==========================================
# 2. LUXALGO ORDER BLOCKS & BREAKER BLOCKS
# ==========================================

def extract_luxalgo_blocks(candles: list[dict], length: int = 10, use_body: bool = False):
    """
    Exact implementation of LuxAlgo's 'Order Blocks & Breaker Blocks' Pine Script.
    Tracks swing points, scans backward to find origin candles of institutional legs,
    and manages active Order Blocks and Breaker Block polarity flips.
    """
    total = len(candles)
    if total < length * 2:
        return {"bullish_obs": [], "bearish_obs": [], "bullish_breakers": [], "bearish_breakers": []}

    curr_price = candles[-1]["close"]
    dec = get_decimals(curr_price)
    os_state = 0
    prev_os = 0
    top_swing = None
    btm_swing = None

    bullish_obs = []
    bearish_obs = []

    for idx in range(length, total):
        c = candles[idx]
        h_len = candles[idx - length]["high"]
        l_len = candles[idx - length]["low"]

        # ta.highest(len) and ta.lowest(len) over the past len bars
        upper = max(candles[j]["high"] for j in range(idx - length + 1, idx + 1))
        lower = min(candles[j]["low"] for j in range(idx - length + 1, idx + 1))

        if h_len > upper:
            os_state = 0
        elif l_len < lower:
            os_state = 1

        if os_state == 0 and prev_os != 0:
            top_swing = {
                "y": candles[idx - length]["high"],
                "x": idx - length,
                "time": candles[idx - length]["time"],
                "crossed": False,
            }
        if os_state == 1 and prev_os != 1:
            btm_swing = {
                "y": candles[idx - length]["low"],
                "x": idx - length,
                "time": candles[idx - length]["time"],
                "crossed": False,
            }
        prev_os = os_state

        # 1. Bullish OB Formation (Clean break above swing high)
        if top_swing and not top_swing["crossed"] and c["close"] > top_swing["y"]:
            top_swing["crossed"] = True

            c_prev = candles[idx - 1]
            minima = min(c_prev["open"], c_prev["close"]) if use_body else c_prev["low"]
            maxima = max(c_prev["open"], c_prev["close"]) if use_body else c_prev["high"]
            loc_time = c_prev["time"]

            # Backward scan to find the exact origin base of the run
            for k in range(idx - 1, top_swing["x"], -1):
                cand = candles[k]
                cand_min = min(cand["open"], cand["close"]) if use_body else cand["low"]
                cand_max = max(cand["open"], cand["close"]) if use_body else cand["high"]
                if cand_min < minima:
                    minima = cand_min
                    maxima = cand_max
                    loc_time = cand["time"]

            bullish_obs.insert(0, {
                "top": round(maxima, dec),
                "bottom": round(minima, dec),
                "mid": round((maxima + minima) / 2, dec),
                "time": loc_time,
                "created_time": c["time"],
                "breaker": False,
                "break_time": None,
                "type": "BULLISH_OB",
                "role": "DEMAND_SUPPORT",
            })

        # 2. Bearish OB Formation (Clean break below swing low)
        if btm_swing and not btm_swing["crossed"] and c["close"] < btm_swing["y"]:
            btm_swing["crossed"] = True

            c_prev = candles[idx - 1]
            minima = min(c_prev["open"], c_prev["close"]) if use_body else c_prev["low"]
            maxima = max(c_prev["open"], c_prev["close"]) if use_body else c_prev["high"]
            loc_time = c_prev["time"]

            # Backward scan to find the exact peak of the run
            for k in range(idx - 1, btm_swing["x"], -1):
                cand = candles[k]
                cand_min = min(cand["open"], cand["close"]) if use_body else cand["low"]
                cand_max = max(cand["open"], cand["close"]) if use_body else cand["high"]
                if cand_max > maxima:
                    maxima = cand_max
                    minima = cand_min
                    loc_time = cand["time"]

            bearish_obs.insert(0, {
                "top": round(maxima, dec),
                "bottom": round(minima, dec),
                "mid": round((maxima + minima) / 2, dec),
                "time": loc_time,
                "created_time": c["time"],
                "breaker": False,
                "break_time": None,
                "type": "BEARISH_OB",
                "role": "SUPPLY_RESISTANCE",
            })

        # 3. Status changes & Breaker flips
        # In bullish_obs:
        i = len(bullish_obs) - 1
        while i >= 0:
            ob = bullish_obs[i]
            if not ob["breaker"]:
                # When broken down, flips into a Bearish Breaker (now acts as resistance)
                if min(c["close"], c["open"]) < ob["bottom"]:
                    ob["breaker"] = True
                    ob["break_time"] = c["time"]
                    ob["type"] = "BEARISH_BREAKER"
                    ob["role"] = "FLIPPED_RESISTANCE"
            else:
                # If price invalidates the breaker by breaking above its top, purge it
                if c["close"] > ob["top"]:
                    bullish_obs.pop(i)
            i -= 1

        # In bearish_obs:
        i = len(bearish_obs) - 1
        while i >= 0:
            ob = bearish_obs[i]
            if not ob["breaker"]:
                # When broken up, flips into a Bullish Breaker (now acts as support)
                if max(c["close"], c["open"]) > ob["top"]:
                    ob["breaker"] = True
                    ob["break_time"] = c["time"]
                    ob["type"] = "BULLISH_BREAKER"
                    ob["role"] = "FLIPPED_SUPPORT"
            else:
                # If price invalidates the breaker by breaking below its bottom, purge it
                if c["close"] < ob["bottom"]:
                    bearish_obs.pop(i)
            i -= 1

    # Enrich with distance metrics
    active_bull_obs = [ob for ob in bullish_obs if not ob["breaker"]]
    active_bear_breakers = [ob for ob in bullish_obs if ob["breaker"]]
    active_bear_obs = [ob for ob in bearish_obs if not ob["breaker"]]
    active_bull_breakers = [ob for ob in bearish_obs if ob["breaker"]]

    for ob in active_bull_obs + active_bear_breakers + active_bear_obs + active_bull_breakers:
        dist_pts = round(curr_price - ob["mid"], dec)
        dist_pct = round((dist_pts / curr_price) * 100, 2)
        ob["dist_pts"] = dist_pts
        ob["dist_pct"] = dist_pct

    return {
        "bullish_order_blocks": active_bull_obs[:5],
        "bearish_order_blocks": active_bear_obs[:5],
        "bullish_breaker_blocks": active_bull_breakers[:5],
        "bearish_breaker_blocks": active_bear_breakers[:5],
    }


# ==========================================
# 3. UNICORN CONFLUENCE FINDER
# ==========================================

def find_unicorn_zones(fvgs: list[dict], lux_blocks: dict, curr_price: float):
    """
    Computes geometric overlap between unmitigated/partial FVGs and Breaker Blocks.
    """
    unicorn_zones = []
    active_fvgs = [f for f in fvgs if f["status"] in ["UNMITIGATED", "PARTIALLY_MITIGATED"]]
    dec = get_decimals(curr_price)

    # 1. Bearish Unicorn: Bearish Breaker + Bearish FVG
    for bb in lux_blocks.get("bearish_breaker_blocks", []):
        for fvg in active_fvgs:
            if fvg["type"] != "BEARISH":
                continue

            overlap_top = min(bb["top"], fvg["top"])
            overlap_bottom = max(bb["bottom"], fvg["bottom"])

            if overlap_top > overlap_bottom:
                overlap_pts = overlap_top - overlap_bottom
                zone_mid = (overlap_top + overlap_bottom) / 2
                dist_pts = round(zone_mid - curr_price, dec)
                dist_pct = round((dist_pts / curr_price) * 100, 2)

                unicorn_zones.append({
                    "type": "BEARISH_UNICORN_ZONE",
                    "role": "HIGH_PROBABILITY_RESISTANCE",
                    "overlap_top": round(overlap_top, dec),
                    "overlap_bottom": round(overlap_bottom, dec),
                    "confluence_mid": round(zone_mid, dec),
                    "overlap_width_pts": round(overlap_pts, dec),
                    "dist_from_price_pts": dist_pts,
                    "dist_from_price_pct": dist_pct,
                    "fvg_span": [fvg["bottom"], fvg["top"]],
                    "fvg_status": fvg["status"],
                    "breaker_span": [bb["bottom"], bb["top"]],
                })

    # 2. Bullish Unicorn: Bullish Breaker + Bullish FVG
    for bb in lux_blocks.get("bullish_breaker_blocks", []):
        for fvg in active_fvgs:
            if fvg["type"] != "BULLISH":
                continue

            overlap_top = min(bb["top"], fvg["top"])
            overlap_bottom = max(bb["bottom"], fvg["bottom"])

            if overlap_top > overlap_bottom:
                overlap_pts = overlap_top - overlap_bottom
                zone_mid = (overlap_top + overlap_bottom) / 2
                dist_pts = round(zone_mid - curr_price, dec)
                dist_pct = round((dist_pts / curr_price) * 100, 2)

                unicorn_zones.append({
                    "type": "BULLISH_UNICORN_ZONE",
                    "role": "HIGH_PROBABILITY_SUPPORT",
                    "overlap_top": round(overlap_top, dec),
                    "overlap_bottom": round(overlap_bottom, dec),
                    "confluence_mid": round(zone_mid, dec),
                    "overlap_width_pts": round(overlap_pts, dec),
                    "dist_from_price_pts": dist_pts,
                    "dist_from_price_pct": dist_pct,
                    "fvg_span": [fvg["bottom"], fvg["top"]],
                    "fvg_status": fvg["status"],
                    "breaker_span": [bb["bottom"], bb["top"]],
                })
                dist_pct = round((dist_pts / curr_price) * 100, 2)

                unicorn_zones.append({
                    "type": "BULLISH_UNICORN_ZONE",
                    "role": "HIGH_PROBABILITY_SUPPORT",
                    "overlap_top": round(overlap_top, 2),
                    "overlap_bottom": round(overlap_bottom, 2),
                    "confluence_mid": round(zone_mid, 2),
                    "overlap_width_pts": round(overlap_pts, 2),
                    "dist_from_price_pts": dist_pts,
                    "dist_from_price_pct": dist_pct,
                    "fvg_span": [fvg["bottom"], fvg["top"]],
                    "fvg_status": fvg["status"],
                    "breaker_span": [bb["bottom"], bb["top"]],
                })

    return unicorn_zones


def main():
    parser = argparse.ArgumentParser(description="SMC & Institutional Structure Sensor (Hermes Quant)")
    parser.add_argument("--symbol", default="BTCUSDT", help="Symbol, e.g. BTCUSDT, ETHUSDT, XAUUSD")
    parser.add_argument("--timeframe", "-tf", default="15m", help="Timeframe (e.g. 5m, 15m, 1h, 4h)")
    parser.add_argument("--lookback", type=int, default=10, help="LuxAlgo swing lookback (default: 10)")
    parser.add_argument("--use-body", action="store_true", help="Use candle body instead of wicks")
    parser.add_argument("--min-gap-pct", type=float, default=0.04, help="Min FVG size in % (default: 0.04)")
    parser.add_argument("--raw", action="store_true", help="Print raw JSON only")

    args = parser.parse_args()
    sym = args.symbol.upper().strip()
    tf = args.timeframe.lower().strip()

    # Load per-pair saved settings from EF Terminal if available
    SETTINGS_FILE = "C:/Users/luthf/AppData/Local/hermes/data/smc_settings.json"
    saved_cfg = {}
    if os.path.exists(SETTINGS_FILE):
        try:
            with open(SETTINGS_FILE, "r", encoding="utf-8") as f:
                all_settings = json.load(f)
                saved_cfg = all_settings.get(sym, {})
        except Exception:
            saved_cfg = {}

    lookback = args.lookback if "--lookback" in sys.argv else int(saved_cfg.get("lookback", args.lookback))
    use_body = args.use_body if "--use-body" in sys.argv else bool(saved_cfg.get("useBody", False))
    min_gap_pct = args.min_gap_pct if "--min-gap-pct" in sys.argv else float(saved_cfg.get("minGapPct", args.min_gap_pct))

    if "XAU" in sym or "GOLD" in sym:
        candles = fetch_binance_klines("PAXGUSDT", tf, 350)
        if not candles:
            candles = fetch_yahoo_klines(sym, tf, 200)
    else:
        candles = fetch_binance_klines(sym, tf, 350)
        if not candles:
            candles = fetch_yahoo_klines(sym, tf, 200)

    if not candles:
        print(json.dumps({"error": f"Failed to fetch market data for {sym}"}, indent=2))
        return

    raw_close = candles[-1]["close"]
    dec = get_decimals(raw_close)
    curr_price = round(raw_close, dec)

    # 1. Extract FVGs
    all_fvgs = extract_fvgs(candles, min_gap_pct=min_gap_pct)
    unmitigated_fvgs = [f for f in all_fvgs if f["status"] == "UNMITIGATED"]
    partial_fvgs = [f for f in all_fvgs if f["status"] == "PARTIALLY_MITIGATED"]

    bull_unmit = [f for f in unmitigated_fvgs if f["type"] == "BULLISH"]
    bear_unmit = [f for f in unmitigated_fvgs if f["type"] == "BEARISH"]

    nearest_bull_fvg = min(bull_unmit, key=lambda f: abs(curr_price - f["top"])) if bull_unmit else None
    nearest_bear_fvg = min(bear_unmit, key=lambda f: abs(f["bottom"] - curr_price)) if bear_unmit else None

    # 2. Extract LuxAlgo Order Blocks & Breakers
    lux_blocks = extract_luxalgo_blocks(candles, length=lookback, use_body=use_body)

    # 3. Compute Unicorn Confluence Zones
    unicorn_zones = find_unicorn_zones(all_fvgs, lux_blocks, curr_price)

    output = {
        "symbol": sym,
        "timeframe": tf,
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S WIB"),
        "current_price": curr_price,
        "applied_settings": {
            "lookback": lookback,
            "use_body": use_body,
            "min_gap_pct": min_gap_pct,
            "pair_customized": bool(saved_cfg),
        },
        "fvg_summary": {
            "total_unmitigated": len(unmitigated_fvgs),
            "total_partially_mitigated": len(partial_fvgs),
            "nearest_bullish_fvg": nearest_bull_fvg,
            "nearest_bearish_fvg": nearest_bear_fvg,
        },
        "order_blocks": {
            "active_bullish_demand": lux_blocks["bullish_order_blocks"],
            "active_bearish_supply": lux_blocks["bearish_order_blocks"],
        },
        "breaker_blocks": {
            "active_bullish_support_breakers": lux_blocks["bullish_breaker_blocks"],
            "active_bearish_resistance_breakers": lux_blocks["bearish_breaker_blocks"],
        },
        "unicorn_confluence_zones": unicorn_zones[:4],
        "active_unmitigated_fvgs": unmitigated_fvgs[-6:],
    }

    if args.raw or not sys.stdout.isatty():
        print(json.dumps(output, indent=2))
    else:
        print(f"\n========================================================")
        print(f"  SMC & LIQUIDITY STRUCTURE SENSOR: {sym} ({tf.upper()})")
        print(f"  Price: ${curr_price:,.2f}")
        print(f"========================================================")
        print(f"Active Bullish OBs (Demand): {len(lux_blocks['bullish_order_blocks'])} | Active Bearish OBs (Supply): {len(lux_blocks['bearish_order_blocks'])}")
        print(f"Active Breakers: Bullish {len(lux_blocks['bullish_breaker_blocks'])} | Bearish {len(lux_blocks['bearish_breaker_blocks'])}")
        print(f"Unmitigated FVGs: {len(unmitigated_fvgs)} | Unicorn Zones: {len(unicorn_zones)}")
        print(f"--------------------------------------------------------")
        
        if lux_blocks['bullish_order_blocks']:
            ob = lux_blocks['bullish_order_blocks'][0]
            print(f"NEAREST BULLISH OB (Support): ${ob['bottom']} - ${ob['top']} (Dist: {ob['dist_pct']}%)")
        if lux_blocks['bearish_order_blocks']:
            ob = lux_blocks['bearish_order_blocks'][0]
            print(f"NEAREST BEARISH OB (Resistance): ${ob['bottom']} - ${ob['top']} (Dist: +{ob['dist_pct']}%)")
            
        if nearest_bull_fvg:
            print(f"NEAREST BULLISH FVG: ${nearest_bull_fvg['bottom']} - ${nearest_bull_fvg['top']} (Dist: {nearest_bull_fvg['dist_pct']}%)")
        if nearest_bear_fvg:
            print(f"NEAREST BEARISH FVG: ${nearest_bear_fvg['bottom']} - ${nearest_bear_fvg['top']} (Dist: +{nearest_bear_fvg['dist_pct']}%)")

        if unicorn_zones:
            print(f"\n[UNICORN CONFLUENCE OVERLAPS]")
            for u in unicorn_zones:
                print(f"• {u['type']}: ${u['overlap_bottom']} - ${u['overlap_top']} (Mid: ${u['confluence_mid']}) | Dist: {u['dist_from_price_pct']}%")
        print(f"--------------------------------------------------------\n")


if __name__ == "__main__":
    main()
