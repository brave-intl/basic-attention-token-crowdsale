pragma solidity ^0.4.10;
import "./StandardToken.sol";
import "./SafeMath.sol";

contract BAToken is StandardToken, SafeMath {

    // metadata
    string public constant name = "Basic Attention Token";
    string public constant symbol = "BAT";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    // contracts
    address public ethFundDeposit;      // deposit address for ETH for Brave International
    address public batFundDeposit;      // deposit address for Brave International use and BAT User Fund

    // crowdsale parameters
    bool public isFinalized;              // switched to true in operational state
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public constant batFund = 500 * (10**6) * 10**decimals;   // 500m BAT reserved for Brave Intl use
    uint256 public constant tokenExchangeRate = 6400; // 6400 BAT tokens per 1 ETH
    uint256 public constant tokenCreationCap =  1500 * (10**6) * 10**decimals;
    uint256 public constant tokenCreationMin =  675 * (10**6) * 10**decimals;

    // Hunting Whales in Furtherance of Egalitarian ICOs and a More Fair World
    // https://medium.com/@shitoshi/hunting-whales-in-furtherance-of-egalitarian-icos-and-a-more-fair-world-cd5f7ef41555
    // Borrowed from Bancor https://github.com/bancorprotocol/contracts/blob/master/solidity/contracts/CrowdsaleController.sol#L18
    uint256 public constant MAX_GAS_PRICE = 50000000000 wei;    // maximum gas price for contribution transactions
    uint256 public constant MAX_ETHER = 10 ether;              // maximum Ether per transaction

    // events
    event LogRefund(address indexed _to, uint256 _value);
    event CreateBAT(address indexed _to, uint256 _value);

    // constructor
    function BAToken(
        address _ethFundDeposit,
        address _batFundDeposit,
        uint256 _fundingStartBlock,
        uint256 _fundingEndBlock)
    {
      isFinalized = false;                   //controls pre through crowdsale state
      ethFundDeposit = _ethFundDeposit;
      batFundDeposit = _batFundDeposit;
      fundingStartBlock = _fundingStartBlock;
      fundingEndBlock = _fundingEndBlock;
      totalSupply = batFund;
      balances[batFundDeposit] = batFund;    // Deposit Brave Intl share
      CreateBAT(batFundDeposit, batFund);  // logs Brave Intl fund
    }

    // Borrowed from Bancor https://github.com/bancorprotocol/contracts/blob/master/solidity/contracts/CrowdsaleController.sol#L61
    // verifies that the gas price is lower than MAX_GAS_PRICE
    modifier validGasPrice() {
        assert(tx.gasprice <= MAX_GAS_PRICE);
        _;
    }

    // verifies that the gas price is lower than MAX_ETHER
    modifier validEther() {
        assert(msg.value <= MAX_ETHER);
        _;
    }

    /// @dev Accepts ether and creates new BAT tokens.
    function createTokens() payable external
      validGasPrice // Ensure a whale is not cutting in front of everyone else by spending lots of gas!!
      validEther // Ensure a whale is not buying up all the tokens!!!
    {
      if (isFinalized) throw;
      if (block.number < fundingStartBlock) throw;
      if (block.number > fundingEndBlock) throw;
      if (msg.value == 0) throw;

      uint256 tokens = safeMult(msg.value, tokenExchangeRate); // check that we're not over totals
      uint256 checkedSupply = safeAdd(totalSupply, tokens);

      // return money if something goes wrong
      if (tokenCreationCap < checkedSupply) throw;  // odd fractions won't be found

      totalSupply = checkedSupply;
      balances[msg.sender] += tokens;  // safeAdd not needed; bad semantics to use here
      CreateBAT(msg.sender, tokens);  // logs token creation
    }

    /// @dev Ends the funding period and sends the ETH home
    function finalize() external {
      if (isFinalized) throw;
      if (msg.sender != ethFundDeposit) throw; // locks finalize to the ultimate ETH owner
      if(totalSupply < tokenCreationMin) throw;      // have to sell minimum to move to operational
      if(block.number <= fundingEndBlock && totalSupply != tokenCreationCap) throw;
      // move to operational
      isFinalized = true;
      if(!ethFundDeposit.send(this.balance)) throw;  // send the eth to Brave International
    }

    /// @dev Allows contributors to recover their ether in the case of a failed funding campaign.
    function refund() external {
      if(isFinalized) throw;                       // prevents refund if operational
      if (block.number <= fundingEndBlock) throw; // prevents refund until sale period is over
      if(totalSupply >= tokenCreationMin) throw;  // no refunds if we sold enough
      if(msg.sender == batFundDeposit) throw;    // Brave Intl not entitled to a refund
      uint256 batVal = balances[msg.sender];
      if (batVal == 0) throw;
      balances[msg.sender] = 0;
      totalSupply = safeSubtract(totalSupply, batVal); // extra safe
      uint256 ethVal = batVal / tokenExchangeRate;     // should be safe; previous throws covers edges
      LogRefund(msg.sender, ethVal);               // log it 
      if (!msg.sender.send(ethVal)) throw;       // if you're using a contract; make sure it works with .send gas limits
    }

}
