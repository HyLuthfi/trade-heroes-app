#!/usr/bin/env python3
"""
Support Resistance Channels (SNR Toolkit)
Ported faithfully from TradingView Pine Script ("Support Resistance Channels" by LonesomeTheBlue)
Engineered for Hermes Agent & EF Terminal.
"""

import argparse
import datetime
import json
import os
import sys
import urllib.request


def fetch_binance_klines(symbol: str, interval: str = "15m", limit: int = 450):
    pair = symbol.upper().replace("/", "").strip()
    if not pair.endswith("USDT") and not pair.endswith("BUSD") and not pair.endswith("USDC"):
        pair = f"{pair}USDT"

    url = f"https://api.binance.com/api/v3/klines?symbol={pair}&interval={interval}&limit={limit}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})

    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode())
            candles = []
            for row in data:
                candles.append({
                    "time": int(row[0]),
                    "open": float(row[1]),
                    "high": float(row[2]),
                    "low": float(row[3]),
                    "close": float(row[4]),
                    "volume": float(row[5]),
                })
            return candles
    except Exception as e:
        sys.stderr.write(f"Binance fetch error: {e}\n")
        return []


def fetch_yahoo_klines(symbol: str, interval: str = "15m", limit: int = 350):
    # Mapping for Yahoo
    sym = symbol.upper()
    if "XAU" in sym or "GOLD" in sym:
        yahoo_sym = "GC=F"
    elif "BTC" in sym:
        yahoo_sym = "BTC-USD"
    else:
        yahoo_sym = sym

    y_interval = "15m" if interval in ["15m", "15"] else ("1h" if interval in ["1h", "60m"] else ("1d" if interval in ["1d", "D"] else "15m"))
    y_range = "5d" if y_interval == "15m" else ("1mo" if y_interval == "1h" else "6mo")

    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{yahoo_sym}?range={y_range}&interval={y_interval}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})

    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode())
            res = data["chart"]["result"][0]
            timestamps = res["timestamp"]
            quote = res["indicators"]["quote"][0]
            candles = []
            for i in range(len(timestamps)):
                o = quote["open"][i]
                h = quote["high"][i]
                l = quote["low"][i]
                c = quote["close"][i]
                v = quote["volume"][i] or 0.0
                if o is not None and h is not None and l is not None and c is not None:
                    candles.append({
                        "time": timestamps[i] * 1000,
                        "open": float(o),
                        "high": float(h),
                        "low": float(l),
                        "close": float(c),
                        "volume": float(v),
                    })
            return candles[-limit:]
    except Exception as e:
        sys.stderr.write(f"Yahoo fetch error: {e}\n")
        return []


def calculate_snr_channels(
    candles,
    symbol: str = "BTCUSDT",
    pivot_period: int = 8,
    source_type: str = "Close/Open",
    channel_width_pct: float = 3.0,
    min_strength: int = 2,
    max_sr: int = 10,
    loopback: int = 300,
    interval: str = "15m",
):
    """
    Direct port of Pine Script logic:
    1. Pivot detection on Open/Close or High/Low
    2. Dynamic Channel Width = (Highest(300) - Lowest(300)) * ChannelWidth% / 100
    3. Density / Cluster accumulation (+20 score per pivot cluster)
    4. Bar touch validation (+1 score per bar touch in 300 bars)
    5. Non-Maximum Suppression (Anti-overlap greedy selection)
    """
    if not candles or len(candles) < pivot_period * 2 + 10:
        return {"error": "Candles insufficient for pivot calculation"}

    n = len(candles)
    scan_len = min(n, loopback)
    recent_candles = candles[-scan_len:]

    # 1. Sources
    src_upper = []
    src_lower = []
    for c in recent_candles:
        if source_type == "High/Low":
            src_upper.append(c["high"])
            src_lower.append(c["low"])
        else:
            src_upper.append(max(c["open"], c["close"]))
            src_lower.append(min(c["open"], c["close"]))

    # 2. Pivots (left = pivot_period, right = pivot_period)
    pivots = []
    for i in range(pivot_period, len(recent_candles) - pivot_period):
        val_up = src_upper[i]
        is_high = True
        for left_i in range(i - pivot_period, i):
            if src_upper[left_i] >= val_up:
                is_high = False
                break
        if is_high:
            for right_i in range(i + 1, i + pivot_period + 1):
                if src_upper[right_i] > val_up:
                    is_high = False
                    break
        if is_high:
            pivots.append({"val": val_up, "idx": i, "type": "H"})

        val_low = src_lower[i]
        is_low = True
        for left_i in range(i - pivot_period, i):
            if src_lower[left_i] <= val_low:
                is_low = False
                break
        if is_low:
            for right_i in range(i + 1, i + pivot_period + 1):
                if src_lower[right_i] < val_low:
                    is_low = False
                    break
        if is_low:
            pivots.append({"val": val_low, "idx": i, "type": "L"})

    if not pivots:
        return {"error": "No pivots found in the lookback range"}

    # 3. Channel Width calculation
    highest_p = max(c["high"] for c in recent_candles)
    lowest_p = min(c["low"] for c in recent_candles)
    channel_width = (highest_p - lowest_p) * (channel_width_pct / 100.0)

    # 4. Clustering: SNR_dapatkan_sr(indeks)
    data_sr = []  # list of [score, top, bottom, touches]
    for idx, p in enumerate(pivots):
        base_val = p["val"]
        bottom = base_val
        top = base_val
        cluster_score = 0

        for other in pivots:
            val = other["val"]
            lebar = (top - val) if val <= top else (val - bottom)
            if lebar <= channel_width:
                if val <= top:
                    bottom = min(bottom, val)
                else:
                    top = max(top, val)
                cluster_score += 20

        # 5. Touch Count in recent 300 bars
        touches = 0
        for c in recent_candles:
            h = c["high"]
            l = c["low"]
            if (h <= top and h >= bottom) or (l <= top and l >= bottom) or (l <= bottom and h >= top):
                touches += 1

        total_score = cluster_score + touches
        data_sr.append({
            "score": total_score,
            "cluster_score": cluster_score,
            "touches": touches,
            "top": top,
            "bottom": bottom,
            "mid": (top + bottom) / 2.0,
        })

    # 6. Non-Maximum Suppression (Greedy Selection & Anti-Overlap)
    min_required_score = min_strength * 20
    selected_zones = []

    for _ in range(max_sr):
        highest_score = -1
        best_loc = -1

        for i, item in enumerate(data_sr):
            if item["score"] > highest_score and item["score"] >= min_required_score:
                highest_score = item["score"]
                best_loc = i

        if best_loc < 0:
            break

        winner = dict(data_sr[best_loc])
        selected_zones.append(winner)

        win_top = winner["top"]
        win_bottom = winner["bottom"]

        # Suppress all candidates that overlap with winner
        for i, item in enumerate(data_sr):
            if item["score"] > 0:
                # Check overlap
                if (item["top"] <= win_top and item["top"] >= win_bottom) or \
                   (item["bottom"] <= win_top and item["bottom"] >= win_bottom) or \
                   (item["bottom"] <= win_bottom and item["top"] >= win_top):
                    item["score"] = -1

    # 7. Tier & Grade Mapping
    def get_color_grade(score):
        if score >= 120:
            return {"grade": "PURPLE", "tier": "Institutional Extreme", "hex": "#a855f7"}
        elif score >= 100:
            return {"grade": "INDIGO", "tier": "Very Strong", "hex": "#4f46e5"}
        elif score >= 80:
            return {"grade": "BLUE", "tier": "Major Strong", "hex": "#2563eb"}
        elif score >= 60:
            return {"grade": "GREEN", "tier": "Strong", "hex": "#16a34a"}
        elif score >= 40:
            return {"grade": "GOLD", "tier": "Moderate", "hex": "#d97706"}
        else:
            return {"grade": "RED", "tier": "Weak", "hex": "#dc2626"}

    current_price = recent_candles[-1]["close"]
    prev_close = recent_candles[-2]["close"] if len(recent_candles) > 1 else current_price

    # Precision based on price magnitude
    dec = 8 if current_price < 0.00001 else (7 if current_price < 0.001 else (6 if current_price < 0.1 else (4 if current_price < 10 else 2)))

    enriched_zones = []
    for z in selected_zones:
        info = get_color_grade(z["score"])
        is_res = z["bottom"] > current_price
        is_sup = z["top"] < current_price
        is_inside = z["bottom"] <= current_price <= z["top"]

        status = "RESISTANCE" if is_res else ("SUPPORT" if is_sup else "INSIDE_ZONE")
        dist_pts = round(abs(z["mid"] - current_price), dec)
        dist_pct = round((dist_pts / current_price) * 100, 2)

        # Broken detection
        broken_up = prev_close <= z["top"] and current_price > z["top"]
        broken_down = prev_close >= z["bottom"] and current_price < z["bottom"]

        enriched_zones.append({
            "top": round(z["top"], dec),
            "bottom": round(z["bottom"], dec),
            "mid": round(z["mid"], dec),
            "width_points": round(z["top"] - z["bottom"], dec),
            "score": z["score"],
            "touches": z["touches"],
            "grade": info["grade"],
            "tier": info["tier"],
            "color_hex": info["hex"],
            "status": status,
            "dist_points": dist_pts,
            "dist_percent": dist_pct,
            "is_broken_up": broken_up,
            "is_broken_down": broken_down,
        })

    # Sort zones from highest price to lowest price
    enriched_zones.sort(key=lambda x: x["mid"], reverse=True)

    # Identify nearest support and resistance
    resistances = [z for z in enriched_zones if z["status"] == "RESISTANCE"]
    supports = [z for z in enriched_zones if z["status"] == "SUPPORT"]

    nearest_res = min(resistances, key=lambda x: x["dist_points"]) if resistances else None
    nearest_sup = min(supports, key=lambda x: x["dist_points"]) if supports else None

    return {
        "symbol": symbol.upper(),
        "timeframe": interval,
        "current_price": round(current_price, dec),
        "channel_width_reference": round(channel_width, dec),
        "total_zones_found": len(enriched_zones),
        "nearest_resistance": nearest_res,
        "nearest_support": nearest_sup,
        "zones": enriched_zones,
    }


def main():
    parser = argparse.ArgumentParser(description="Support Resistance Channels Toolkit (Hermes Quant)")
    parser.add_argument("--symbol", default="BTCUSDT", help="Ticker, e.g. BTCUSDT, ETHUSDT, XAUUSD")
    parser.add_argument("--timeframe", "-tf", default="15m", help="Timeframe: 5m, 15m, 1h, 4h, 1d")
    parser.add_argument("--pivot-period", type=int, default=8, help="Pivot Period (default 8)")
    parser.add_argument("--source", default="Close/Open", choices=["Close/Open", "High/Low"])
    parser.add_argument("--width-pct", type=float, default=3.0, help="Channel Width % (default 3.0)")
    parser.add_argument("--min-strength", type=int, default=2, help="Minimum Strength (default 2)")
    parser.add_argument("--max-sr", type=int, default=10, help="Max Number of S/R (default 10)")
    parser.add_argument("--raw", action="store_true", help="Print raw JSON output only")

    args = parser.parse_args()
    sym = args.symbol.upper()

    # Load per-pair saved settings from EF Terminal if available
    SETTINGS_FILE = "C:/Users/luthf/AppData/Local/hermes/data/snr_settings.json"
    saved_cfg = {}
    if os.path.exists(SETTINGS_FILE):
        try:
            with open(SETTINGS_FILE, "r", encoding="utf-8") as f:
                all_settings = json.load(f)
                saved_cfg = all_settings.get(sym, {})
        except Exception:
            saved_cfg = {}

    # Prefer explicit CLI flag if user passed it, otherwise fall back to pair's saved settings, otherwise default
    pivot_period = args.pivot_period if "--pivot-period" in sys.argv else int(saved_cfg.get("pivotPeriod", args.pivot_period))
    source_type = args.source if "--source" in sys.argv else saved_cfg.get("source", args.source)
    width_pct = args.width_pct if "--width-pct" in sys.argv else float(saved_cfg.get("widthPct", args.width_pct))
    min_strength = args.min_strength if "--min-strength" in sys.argv else int(saved_cfg.get("minStrength", args.min_strength))
    max_sr = args.max_sr if "--max-sr" in sys.argv else int(saved_cfg.get("maxSr", args.max_sr))

    # Determine provider
    if "XAU" in sym or "GOLD" in sym:
        candles = fetch_binance_klines("PAXGUSDT", args.timeframe, 450)
        if not candles:
            candles = fetch_yahoo_klines(sym, args.timeframe, 350)
    else:
        candles = fetch_binance_klines(sym, args.timeframe, 450)
        if not candles:
            candles = fetch_yahoo_klines(sym, args.timeframe, 350)

    if not candles:
        print(json.dumps({"error": f"Failed to fetch market data for {sym}"}, indent=2))
        return

    result = calculate_snr_channels(
        candles,
        symbol=sym,
        pivot_period=pivot_period,
        source_type=source_type,
        channel_width_pct=width_pct,
        min_strength=min_strength,
        max_sr=max_sr,
        loopback=300,
        interval=args.timeframe,
    )
    result["applied_settings"] = {
        "pivot_period": pivot_period,
        "source": source_type,
        "width_pct": width_pct,
        "min_strength": min_strength,
        "max_sr": max_sr,
        "pair_customized": bool(saved_cfg),
    }

    if args.raw or not sys.stdout.isatty():
        print(json.dumps(result, indent=2))
        return

    # Pretty Human Output for CLI
    print(f"\n=======================================================")
    print(f"  SNR CHANNELS RADAR: {result['symbol']} ({result['timeframe'].upper()})")
    print(f"  Harga Saat Ini: ${result['current_price']:,.2f}")
    print(f"  Lebar Saluran Dinamis: ±${result['channel_width_reference']:,.2f}")
    print(f"=======================================================\n")

    if result["nearest_resistance"]:
        nr = result["nearest_resistance"]
        print(f"▲ RESISTANCE TERDEKAT: ${nr['bottom']:,.2f} - ${nr['top']:,.2f} (+{nr['dist_points']:,.1f} pts / +{nr['dist_percent']}%)")
        print(f"  Grade: [{nr['grade']}] {nr['tier']} · Skor: {nr['score']} · Sentuhan: {nr['touches']}x\n")

    if result["nearest_support"]:
        ns = result["nearest_support"]
        print(f"▼ SUPPORT TERDEKAT:    ${ns['bottom']:,.2f} - ${ns['top']:,.2f} (-{ns['dist_points']:,.1f} pts / -{ns['dist_percent']}%)")
        print(f"  Grade: [{ns['grade']}] {ns['tier']} · Skor: {ns['score']} · Sentuhan: {ns['touches']}x\n")

    print(f"--- SEMUA ZONA TERVALIDASI ({result['total_zones_found']} Level) ---")
    for z in result["zones"]:
        arrow = "▲ RES" if z["status"] == "RESISTANCE" else ("▼ SUP" if z["status"] == "SUPPORT" else "◆ MID")
        print(f"  {arrow:<6} ${z['bottom']:>9,.2f} - ${z['top']:<9,.2f} | Skor: {z['score']:<3} | [{z['grade']:<6}] ({z['tier']}) | {z['touches']} touches")
    print("")


if __name__ == "__main__":
    main()
