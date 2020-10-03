pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/TokenTimelock.sol";
import "openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "openzeppelin-solidity/contracts/token/ERC20/PausableToken.sol";
import "openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/validation/WhitelistedCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/distribution/RefundableCrowdsale.sol";

contract DappTokenCrowdsale is Crowdsale, MintedCrowdsale, CappedCrowdsale, TimedCrowdsale, WhitelistedCrowdsale, RefundableCrowdsale{

    //Minimum investor contribution - 0.002 Ether
    //Minimum investor contribution - 50Ether

    uint256 public investorMinCap = 2000000000000000;
    uint256 public investorMaxCap = 50000000000000000000;

    mapping(address => uint256) public contributions;

    //crowdsale stages

    enum CrowdsaleStage { PreICO, ICO }
    //Default to presale stage

    CrowdsaleStage public stage =  CrowdsaleStage.PreICO;

    //Token Distribution
    uint256 public tokenSalePercentage = 70;
    uint256 public foundersPercentage = 10;
    uint256 public foundationPercentage = 10;
    uint256 public partnersPercentage = 10;
    
    
    //Token reserve funds
    address public foundersFund;
    address public foundationFund;
    address public partnersFund;

    //Token time lock
    uint256 public releaseTime;
    address public foundersTimelock;
    address public foundationTimelock;
    address public partnersTimelock;
    //address foundersAddress;
    //address foundationAddress;
    //address partnersAddress;

    constructor(
        uint256 _rate, 
        address _wallet, 
        ERC20 _token,
        uint256 _cap,
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _goal,
        address _foundersFund,
        address _foundationFund,
        address _partnersFund,
        uint256 _releaseTime
        )  
        
        Crowdsale(_rate, _wallet, _token) 
        CappedCrowdsale(_cap)
        TimedCrowdsale(_openingTime, _closingTime)
        RefundableCrowdsale(_goal)
        public {
            require(_goal <= _cap);
            foundersFund   = _foundersFund;
            foundationFund = _foundationFund;
            partnersFund   = _partnersFund;
            releaseTime    = _releaseTime;
        }

        //@dev returns the amount contributed so far by a specific user
        //@param _beneficiary address of contributor
        //@return user contributions so far

        function getUserContribution(address _beneficiary) public view returns (uint256) {
            return contributions[_beneficiary];
        }

        //dev Allows admin to update the crowdsale stage
        //param _stage Crowdsale stage
        function setCrowdsaleStage(uint _stage) public onlyOwner {
            if(uint(CrowdsaleStage.PreICO) == _stage){
                stage =  CrowdsaleStage.PreICO;
            } else if(uint(CrowdsaleStage.ICO) == _stage){
                stage = CrowdsaleStage.ICO;
            }

            if(stage == CrowdsaleStage.PreICO) {
                rate = 500;

            }else if (stage == CrowdsaleStage.ICO) {
                rate = 250;
            }
        }

        // forwards funds to the wallet during the preICO stage, then the refund vault during ICO stage
        function _forwardFunds() internal {
            if(stage == CrowdsaleStage.PreICO){
                wallet.transfer(msg.value);
            }else if (stage == CrowdsaleStage.ICO) {
                super._forwardFunds();
            }
            
        }
    
        function _preValidatePurchase(address _beneficiary, uint256 _weiAmount ) internal {
            super._preValidatePurchase(_beneficiary, _weiAmount);
            uint256 _existingContribution = contributions[_beneficiary];
            uint256 _newContribution = _existingContribution.add(_weiAmount);
            require(_newContribution >= investorMinCap && _newContribution <= investorMaxCap);
            contributions[_beneficiary] = _newContribution;
        }

        //dev enables token transfers, called when owner calls finalize()

        function finalization() internal {
            if(goalReached()){
                MintableToken _mintableToken = MintableToken(token);
                uint256 _alreadyMinted = _mintableToken.totalSupply();


                uint256 _finalTotalSupply = _alreadyMinted.div(tokenSalePercentage).mul(100);

                foundersTimelock   = new TokenTimelock(token, foundersFund, releaseTime);
                partnersTimelock   = new TokenTimelock(token, partnersFund, releaseTime);
                foundationTimelock = new TokenTimelock(token, foundationFund, releaseTime);

                _mintableToken.mint(foundersTimelock,   _finalTotalSupply.div(foundersPercentage));
                _mintableToken.mint(foundationTimelock, _finalTotalSupply.div(foundationPercentage));
                _mintableToken.mint(partnersTimelock,   _finalTotalSupply.div(partnersPercentage));

                // Do more stuff...
                _mintableToken.finishMinting();
                //Unpause the token
                PausableToken _pausableToken =  PausableToken(token);
                _pausableToken.unpause();
                _pausableToken.transferOwnership(wallet);
            } 
            super.finalization();
        }
}