# Tax Manipulation Scam Pattern Analysis

Analysis of a tax manipulation rugpull pattern in ERC20 tokens — including 
the "tax sandwich" front-running attack and unrestricted owner privileges 
over fees, wallets, and pair addresses.

## Contents
- `yieldfarm-scam.sol` — Reconstructed scam contract
- `analysis.md` — Pattern breakdown, attack sequence, mitigations

## Key Takeaway
The scam isn't in having adjustable taxes — many legitimate tokens have 
that. The scam is in the **absence of bounds, timelocks, and transparency** 
that would prevent the owner from weaponizing those controls.
