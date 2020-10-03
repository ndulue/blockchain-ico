pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "openzeppelin-solidity/contracts/token/ERC20/PausableToken.sol";
//import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";

contract DappToken is PausableToken, MintableToken, DetailedERC20 {
    constructor (string memory _name, string memory _symbol, uint8 _decimals)
        DetailedERC20(_name, _symbol, _decimals)
        public 
    {
        
    }
}