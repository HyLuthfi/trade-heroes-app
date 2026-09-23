"""
Trade Heroes Quantitative Knowledge Engine (Quant Hub)
Integrates:
1. Support & Resistance Channels (Pine Script SNR)
2. Smart Money Concepts (SMC: Fair Value Gaps / Order Blocks)
3. Zero-Lag ATR Momentum & Volatility Envelope

Exclusively designed for educational & analytical insight in Trade Heroes AI Chatbot.
"""

import os
import sys
import json
import time
import urllib.request
from typing import Dict, Any, Optional

# Ensure local engine directory is in path
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
if CURRENT_DIR not in sys.path:
    sys.path.insert(0, CURRENT_DIR)

import snr_channel
import smc_structure
import zerolag_momentum

# Simple in-memory cache to prevent redundant HTTP requests (60s TTL)
_CANDLE_CACHE: Dict[str, Dict[str, Any]] = {}
CACHE_TTL = 60


def fetch_idx_candles(ticker: str) -> list:
    """Fetch 1 year of daily OHLCV candles from Yahoo Finance for BEI stocks."""
    clean_ticker = ticker.upper().replace('.JK', '').strip()
    cache_key = f"{clean_ticker}_1d"
    now = time.time()

    if cache_key in _CANDLE_CACHE:
        cached = _CANDLE_CACHE[cache_key]
        if now - cached['timestamp'] < CACHE_TTL:
            return cached['candles']

    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{clean_ticker}.JK?range=1y&interval=1d"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"})

    try:
        with urllib.request.urlopen(req, timeout=6) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            result = data.get("chart", {}).get("result")
            if not result:
                return []
            res0 = result[0]
            timestamps = res0.get("timestamp", [])
            quotes = res0.get("indicators", {}).get("quote", [{}])[0]
            opens = quotes.get("open", [])
            highs = quotes.get("high", [])
            lows = quotes.get("low", [])
            closes = quotes.get("close", [])
            volumes = quotes.get("volume", [])

            candles = []
            for i in range(len(timestamps)):
                o, h, l, c = opens[i], highs[i], lows[i], closes[i]
                v = volumes[i] if i < len(volumes) else 0
                if None in (o, h, l, c):
                    continue
                candles.append({
                    "time": timestamps[i],
                    "open": float(o),
                    "high": float(h),
                    "low": float(l),
                    "close": float(c),
                    "volume": float(v or 0),
                })

            if candles:
                _CANDLE_CACHE[cache_key] = {"candles": candles, "timestamp": now}
            return candles
    except Exception as e:
        sys.stderr.write(f"QuantHub fetch error for {clean_ticker}: {e}\n")
        return []


def analyze_stock_quant(ticker: str) -> Dict[str, Any]:
    """
    Run full quantitative pipeline (SNR + SMC + ZeroLag) on a BEI stock.
    Returns structured data and a pre-formatted educational prompt text block.
    """
    clean_ticker = ticker.upper().replace('.JK', '').strip()
    candles = fetch_idx_candles(clean_ticker)

    if not candles or len(candles) < 30:
        return {
            "ticker": clean_ticker,
            "has_data": False,
            "prompt_context": f"Data teknikal historis {clean_ticker} belum mencukupi untuk kalkulasi kuantitatif."
        }

    cur_price = candles[-1]["close"]

    # 1. SNR Engine (Pine Script Channels)
    snr_data = {}
    try:
        snr_calc = snr_channel.calculate_snr_channels(
            candles,
            symbol=f"{clean_ticker}.JK",
            loopback=min(300, len(candles)),
            interval="1d"
        )
        nr = snr_calc.get("nearest_resistance") or {}
        ns = snr_calc.get("nearest_support") or {}
        snr_data = {
            "nearest_res": {
                "level": nr.get("mid"),
                "grade": nr.get("grade", "STANDARD"),
                "touches": nr.get("touches", 0),
                "dist_pct": nr.get("dist_percent", 0.0),
            } if nr else None,
            "nearest_supp": {
                "level": ns.get("mid"),
                "grade": ns.get("grade", "STANDARD"),
                "touches": ns.get("touches", 0),
                "dist_pct": ns.get("dist_percent", 0.0),
            } if ns else None,
            "total_zones": snr_calc.get("total_zones_found", 0),
        }
    except Exception as e:
        snr_data = {"error": str(e)}

    # 2. SMC Engine (FVG & Order Blocks)
    smc_data = {}
    try:
        fvgs = smc_structure.extract_fvgs(candles, min_gap_pct=0.03)
        unmitigated_fvgs = [f for f in fvgs if f.get("status") == "UNMITIGATED"]

        # Find nearest unmitigated bullish (below price) and bearish (above price) FVG
        bullish_fvgs = [f for f in unmitigated_fvgs if f.get("type") == "BULLISH" and f.get("top", 0) <= cur_price]
        bearish_fvgs = [f for f in unmitigated_fvgs if f.get("type") == "BEARISH" and f.get("bottom", 999999) >= cur_price]

        nearest_bullish_fvg = bullish_fvgs[-1] if bullish_fvgs else None
        nearest_bearish_fvg = bearish_fvgs[0] if bearish_fvgs else None

        obs = smc_structure.extract_luxalgo_blocks(candles, length=10, use_body=False)
        smc_data = {
            "unmitigated_fvg_count": len(unmitigated_fvgs),
            "nearest_bullish_fvg": nearest_bullish_fvg,
            "nearest_bearish_fvg": nearest_bearish_fvg,
            "demand_order_blocks": obs.get("demand", [])[-2:] if obs.get("demand") else [],
            "supply_order_blocks": obs.get("supply", [])[-2:] if obs.get("supply") else [],
        }
    except Exception as e:
        smc_data = {"error": str(e)}

    # 3. Zero-Lag Momentum Engine
    zl_data = {}
    try:
        zl_calc = zerolag_momentum.compute_zerolag_momentum(candles)
        mom = zl_calc.get("momentum_engine", {})
        env = zl_calc.get("volatility_envelope", {})
        state = zl_calc.get("state", {})
        zl_data = {
            "zerolag_basis": zl_calc.get("zerolag_basis"),
            "cumulative_score": mom.get("cumulative_score", 0),
            "is_score_bullish": mom.get("is_score_bullish", False),
            "is_score_bearish": mom.get("is_score_bearish", False),
            "upper_band": env.get("upper_band"),
            "lower_band": env.get("lower_band"),
            "expansion_state": state.get("expansion_state", "NORMAL"),
            "bias_interpretation": state.get("bias_interpretation", "NEUTRAL"),
        }
    except Exception as e:
        zl_data = {"error": str(e)}

    # 4. Generate clean educational context prompt for LLM
    prompt_lines = [
        f"KNOWLEDGE DATA KUANTITATIF RESMI DARI ENGINE TRADING ({clean_ticker}):",
        f"- Harga Acuan Terakhir: Rp {cur_price:,.0f}".replace(',', '.'),
    ]

    # SNR section
    if snr_data.get("nearest_res") or snr_data.get("nearest_supp"):
        prompt_lines.append("\n[1] LEVEL SUPPORT & RESISTANCE MATEMATIS (SNR Channels):")
        if snr_data.get("nearest_res"):
            res = snr_data["nearest_res"]
            prompt_lines.append(
                f"  • Resistance Kunci: Rp {res['level']:,.0f} (Grade: {res['grade']}, Telah diuji {res['touches']}x pantulan, Jarak: +{res['dist_pct']}%)".replace(',', '.')
            )
        if snr_data.get("nearest_supp"):
            supp = snr_data["nearest_supp"]
            prompt_lines.append(
                f"  • Support Kunci: Rp {supp['level']:,.0f} (Grade: {supp['grade']}, Telah menahan penurunan {supp['touches']}x, Jarak: -{supp['dist_pct']}%)".replace(',', '.')
            )
        prompt_lines.append(f"  • Total Zona Validasi Terdeteksi: {snr_data.get('total_zones', 0)} level")

    # SMC section
    prompt_lines.append("\n[2] SMART MONEY CONCEPTS (SMC / Jejak Transaksi Institusi):")
    if smc_data.get("nearest_bearish_fvg"):
        fvg = smc_data["nearest_bearish_fvg"]
        prompt_lines.append(
            f"  • Fair Value Gap (Bearish FVG) di Atas: Area Rp {fvg['bottom']:,.0f} - Rp {fvg['top']:,.0f} (Celah harga {fvg['gap_size_pts']:,.0f} poin yang berpotensi menjadi magnet harga)".replace(',', '.')
        )
    if smc_data.get("nearest_bullish_fvg"):
        fvg = smc_data["nearest_bullish_fvg"]
        prompt_lines.append(
            f"  • Fair Value Gap (Bullish FVG) di Bawah: Area Rp {fvg['bottom']:,.0f} - Rp {fvg['top']:,.0f} (Zona ketidakseimbangan beli sebagai area bantalan support)".replace(',', '.')
        )
    if smc_data.get("demand_order_blocks"):
        ob = smc_data["demand_order_blocks"][-1]
        prompt_lines.append(
            f"  • Bullish Order Block (Demand): Rp {ob['bottom']:,.0f} - Rp {ob['top']:,.0f} (Zona akumulasi likuiditas institusi)".replace(',', '.')
        )
    if smc_data.get("supply_order_blocks"):
        ob = smc_data["supply_order_blocks"][-1]
        prompt_lines.append(
            f"  • Bearish Order Block (Supply): Rp {ob['bottom']:,.0f} - Rp {ob['top']:,.0f} (Zona distribusi/jual institusi)".replace(',', '.')
        )
    if not (smc_data.get("nearest_bearish_fvg") or smc_data.get("nearest_bullish_fvg")):
        prompt_lines.append("  • Struktur SMC: Transaksi harga saat ini berada dalam keseimbangan wajar (Fair Value).")

    # Zero-Lag section
    prompt_lines.append("\n[3] ZERO-LAG ATR MOMENTUM & VOLATILITAS:")
    score = zl_data.get("cumulative_score", 0)
    score_status = "Akumulasi Bullish Kuat" if score > 15 else ("Tekanan Bearish" if score < -15 else "Netral / Konsolidasi Sehat")
    prompt_lines.append(f"  • Skor Momentum Kumulatif: {score} dari skala 70 ({score_status})")
    if zl_data.get("zerolag_basis"):
        prompt_lines.append(f"  • Garis Tren Basis Zero-Lag: Rp {zl_data['zerolag_basis']:,.0f}".replace(',', '.'))
    if zl_data.get("lower_band") and zl_data.get("upper_band"):
        prompt_lines.append(
            f"  • Amplop Volatilitas: Pita Bawah Rp {zl_data['lower_band']:,.0f} — Pita Atas Rp {zl_data['upper_band']:,.0f}".replace(',', '.')
        )
    prompt_lines.append(f"  • Status Volatilitas: {zl_data.get('bias_interpretation', 'KONSOLIDASI')}")

    prompt_context = "\n".join(prompt_lines)

    return {
        "ticker": clean_ticker,
        "has_data": True,
        "current_price": cur_price,
        "snr": snr_data,
        "smc": smc_data,
        "zerolag": zl_data,
        "prompt_context": prompt_context,
    }


if __name__ == "__main__":
    test_ticker = sys.argv[1] if len(sys.argv) > 1 else "BBCA"
    res = analyze_stock_quant(test_ticker)
    print("=== QUANT HUB RESULT ===")
    print(res["prompt_context"])
