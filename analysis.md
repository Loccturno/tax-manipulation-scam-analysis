# Tax Manipulation Scam Pattern Analysis

## Overview
Analysis of a tax manipulation rugpull pattern, where the owner retains 
unrestricted control over buy/sell taxes and uses this power to extract 
funds from holders through coordinated, time-sensitive attacks.

This pattern is particularly insidious because the contract appears to 
implement standard "fee on transfer" mechanics used by many legitimate 
tokens — the maliciousness lies in what the owner can do later.

---

## Attack Sequence: The Tax Sandwich

1. Token launches with reasonable taxes (e.g., 3% buy / 5% sell)
2. Holders accumulate, treating it as a normal fee-on-transfer token
3. Owner monitors the mempool for large pending sell transactions
4. Owner front-runs the sell with: `setTaxes(0, 99)`
5. Victim's sell executes with the new 99% tax — owner receives 99% of tokens
6. Owner immediately resets: `setTaxes(3, 5)` — covering tracks
7. The malicious config existed only for one block

Result: Targeted extraction of large holders without alerting the broader 
community, since taxes appear normal before and after the attack.

---

## Malicious Functions

### setTaxes — Unrestricted Tax Control
```solidity
function setTaxes(uint256 _buyTax, uint256 _sellTax) external {
    require(msg.sender == owner, "Not owner");
    buyTax = _buyTax;
    sellTax = _sellTax;
    emit TaxesUpdated(_buyTax, _sellTax);
}
```

**Why malicious:** The owner can at any time, with no restriction
at all,set any price he wants. One well timed change of taxes the likes of (0, 99)
would give his wallet almost the whole amount (99) of the transaction. 
And then change it back like nothing happened.

**Mitigation:** Add an upper bound check, e.g., 
`require(_buyTax <= 10 && _sellTax <= 10, "Tax too high");`. 
Combine with a timelock mechanism so any tax change takes effect only 
after a delay (e.g., 24-48 hours) — implemented by storing the proposed 
taxes with a `pendingTaxChangeTimestamp`, and applying them only after 
the delay has passed. This gives holders time to detect and exit before 
a malicious change activates.

### setTaxWallet — Profit Exfiltration
```solidity
function setTaxWallet(address _wallet) external {
    require(msg.sender == owner, "Not owner");
    taxWallet = _wallet;
}
```

**Why malicious:**Tax wallet is by default owners wallet

**Mitigation:** Restrict tax wallet to a multi-sig or treasury contract 
set at deployment. Either remove this setter entirely after launch (via 
renounceOwnership), or require the new wallet to be whitelisted in advance 
and apply a timelock before activation.

### setUniswapPair — Silent Pair Manipulation
```solidity
function setUniswapPair(address _pair) external {
    require(msg.sender == owner, "Not owner");
    uniswapPair = _pair;
}
```

**Why malicious:** No emits, or returns of the function.

**Mitigation:** Emit an event when the pair changes (e.g., 
`event PairUpdated(address oldPair, address newPair)`) for transparency. 
Better yet, set the pair only once at deployment and remove the setter 
afterward — there is rarely a legitimate reason to change a pair address 
after launch.

---

## Why This Pattern Is Hard to Detect

Many legitimate tokens have:
- Adjustable taxes (for liquidity events, marketing rounds)
- Tax wallet changes (for treasury rotation)
- Pair updates (for migration to new DEX versions)

The scam isn't in the existence of these functions — it's in:
- Absence of upper bounds on tax values
- Absence of timelocks before changes take effect
- Owner's ability to act on mempool information

---

## Red Flags for Auditors

- `setTaxes` with no maximum bound (e.g., should require taxes ≤ 10-15%)
- No timelock on tax/wallet/pair changes
- No event emitted on `setUniswapPair` (silent state change)
- Owner is the initial taxWallet (centralization risk)
- Tax wallet can be changed to any arbitrary address with no delay
- There should be some notable constraints on how you interact in the transaction. If there are none,
somethings wrong.
---

## Real-World Examples

This pattern has been observed in numerous BSC and Ethereum memecoin rugs, 
where projects launched with low taxes, accumulated holders, then executed 
tax sandwich attacks before being abandoned.
