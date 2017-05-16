pragma solidity ^0.4.10;
import "./StandardToken.sol";
import "./SafeMath.sol";

contract BAToken is StandardToken, SafeMath {

    // metadata
    string public constant name = "Basic Attention Token";
    string public constant symbol = "BAT";
    uint8 public constant decimals = 18;
    string public version = "0.9";

    // contracts
    address public ethFundDeposit;      // deposit address for ETH for Brave International
    address public batFundDeposit;      // deposit address for Brave internal use and Brave User Fund 

    // crowdsale parameters
    bool public isFunding;              // State no longer important, but still useful for observation
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public batFund = 300 * 10**24;   // 300m BAT reserved for Brave
    uint256 public constant tokenExchangeRate = 4000; // 4000 BAT tokens per 1 ETH
    uint256 public constant tokenCreationCap =  1000 * 10**24; 
    uint256 public constant tokenCreationMin =  490 * 10**24; 


    // events
    event LogRefund(address indexed to, uint256 value);


    // constructor
    function BAToken(
        address _ethFundDeposit,
        address _batFundDeposit,
        uint256 _fundingStartBlock,
        uint256 _fundingEndBlock)
    {
      isFunding = true;                      //controls crowdsale state
      ethFundDeposit = _ethFundDeposit;
      batFundDeposit = _batFundDeposit;
      fundingStartBlock = _fundingStartBlock;
      fundingEndBlock = _fundingEndBlock;
      totalSupply = batFund;
      balances[batFundDeposit] = batFund;    //Deposit optimistic Brave share
    }

    /// @dev Accepts ether and creates new BAT tokens.
    function createTokens() payable external {
      if (!isFunding) throw;
      if (block.number < fundingStartBlock) throw;
      if (block.number > fundingEndBlock) throw;
      if (msg.value == 0) throw;
      uint256 tokens = safeMult(msg.value, tokenExchangeRate); // check that we're not over totals
      uint256 tmpSupply = safeAdd(totalSupply, tokens);
      if(tokenCreationCap >= tmpSupply) {    // odd fractions won't be found
        totalSupply += tokens;
        balances[msg.sender] += tokens;
        Transfer(0, msg.sender, tokens); // logs transfer
      } else {
        throw;                           // they need to get their money back if something goes wrong
      }
    }

    /// @dev Ends the funding period and issues new BAT tokens to the User Growth Fund.
    function finalize() external {
      if (!isFunding) throw;
      if (msg.sender != ethFundDeposit) throw; // this locks finalize to the ultimate ETH owner
      if ((block.number <= fundingEndBlock ||
           totalSupply < tokenCreationMin) &&
          totalSupply < tokenCreationCap) throw;
      // move to operational
      isFunding = false;
      if(!ethFundDeposit.send(this.balance)) throw;  // send the eth to Brave International
    }

    /// @dev Allows contributors to recover their ether in the case of a failed funding campaign.
    function refund() external {
      if(!isFunding) throw;                       // prevents refund if operational
      if (block.number <= fundingEndBlock) throw; // prevents refund until sale period is over
      if(totalSupply >= tokenCreationMin) throw;  // no refunds if we sold enough
      var batVal = balances[msg.sender];
      if (batVal == 0) throw;
      balances[msg.sender] = 0;
      totalSupply -= batVal;
      var ethVal = batVal / tokenExchangeRate;
      LogRefund(msg.sender, ethVal);
      if (!msg.sender.send(ethVal)) throw;       // if you're using a contract; make sure it works with .send gas limits
    }

}
