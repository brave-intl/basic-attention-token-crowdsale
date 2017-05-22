pragma solidity ^0.4.10;
import './StandardToken.sol';

contract BATSafe {
  mapping (address => uint256) allocations;
  uint256 public unlockDate;
  address public BAT;
  uint256 public constant exponent = 10**18;

  function BATSafe(address _BAT) {                // sample allocations
    BAT = _BAT;
    unlockDate = now + 15 minutes;
    allocations[0xB9bc094AC55d5696E888B942Ee879E55A2B2a586] = 100;
    allocations[0x1ff55E3F22585A61401396E8D5248e977E305BDf] = 10;
    allocations[0x990F1870e96ffa1427A6a72FA82040429B333812] = 15;
    allocations[0xeA0c9227d6B5B16F07FDc7807434AD21bBC40Fc5] = 75;
  }

  function unlock() external {
    if(now < unlockDate) throw;
    uint256 entitled = allocations[msg.sender];
    allocations[msg.sender] = 0;
    if(!StandardToken(BAT).transfer(msg.sender, entitled * exponent)) throw;
  }

}




