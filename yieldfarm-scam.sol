// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract YieldFarmToken {
    string public name = "YieldFarm";
    string public symbol = "YFM";
    uint256 public totalSupply = 1000000 * 10**18;
    address public owner;
    address public taxWallet;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    uint256 public buyTax = 3;  // 3%
    uint256 public sellTax = 5; // 5%
    
    address public uniswapPair;
    bool public swapEnabled = true;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TaxesUpdated(uint256 newBuyTax, uint256 newSellTax);
    
    constructor() {
        owner = msg.sender;
        taxWallet = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    function setTaxes(uint256 _buyTax, uint256 _sellTax) external {
        require(msg.sender == owner, "Not owner");
        buyTax = _buyTax;
        sellTax = _sellTax;
        emit TaxesUpdated(_buyTax, _sellTax);
    }
    
    function setTaxWallet(address _wallet) external {
        require(msg.sender == owner, "Not owner");
        taxWallet = _wallet;
    }
    
    function setUniswapPair(address _pair) external {
        require(msg.sender == owner, "Not owner");
        uniswapPair = _pair;
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(allowance[from][msg.sender] >= amount, "Not approved");
        allowance[from][msg.sender] -= amount;
        return _transfer(from, to, amount);
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient");
        
        uint256 taxAmount = 0;
        
        if (from == uniswapPair) {
            // Buy
            taxAmount = (amount * buyTax) / 100;
        } else if (to == uniswapPair) {
            // Sell
            taxAmount = (amount * sellTax) / 100;
        }
        
        balanceOf[from] -= amount;
        
        if (taxAmount > 0) {
            balanceOf[taxWallet] += taxAmount;
            balanceOf[to] += (amount - taxAmount);
            emit Transfer(from, taxWallet, taxAmount);
            emit Transfer(from, to, amount - taxAmount);
        } else {
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
        }
        
        return true;
    }
}
