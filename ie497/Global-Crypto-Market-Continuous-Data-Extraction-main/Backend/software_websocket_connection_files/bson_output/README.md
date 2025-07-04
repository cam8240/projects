# BSON Output Files

This directory contains the output files generated by the crypto data collection system. These include both **ticker** and **trade** data stored in BSON format for each exchange, organized by date.

## File Structure

- `*_ticker_YYYYMMDD.bson` – BSON files containing ticker data
- `*_trade_YYYYMMDD.bson` – BSON files containing trade data
- `*_ticker_YYYYMMDD.json` – Optional JSON files generated from BSON (if converted)
- `convert_bson_json.sh` – Bash script to convert all `.bson` files in this directory to `.json` using `bsondump`

## Converting BSON to JSON

To convert all `.bson` files in this folder to `.json`, run the provided script:

```bash
./convert_bson_json.sh
```