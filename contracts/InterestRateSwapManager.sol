// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IInterestRateCollector.sol";
import "node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InterestRateSwapManager is Ownable {
  using SafeMath for uint256;

  struct LendOffer {
    address creator;
    address arbitrator;
    uint256 arbitratorFee;
    IERC20 token;
    uint256 amount;
    uint256 weeklyInterestDivisor;
    bytes4 useID;
  }

  struct BorrowOffer {
    address creator;
    uint256 lendID;
    uint256 amount;
    uint256 lengthInWeeks;
    IInterestRateCollector collector;
    bool open;
  }

  struct SwapInfo {
    uint256 started;
    uint256 lendID;
    uint256 borrowID;
  }

  mapping(bytes4 => bool) public registeredIDs;
  mapping(bytes4 => bytes32) public verifiedContracts;

  mapping(address => uint256) public registeredArbitrators;

  uint256 nextID = 0;
  mapping(uint256 => LendOffer) public lends;
  mapping(uint256 => BorrowOffer) public borrows;
  mapping(uint256 => SwapInfo) public swaps;

  IERC20 private _VYBE;

  event ArbitratorUpdate(address indexed arbitrator, uint256 fee);
  event NewLendOffer(uint256 indexed id, address indexed creator, bytes4 indexed useID, address arbitrator);
  event LendOfferWithdrawn(uint256 indexed id);
  event NewBorrowOffer(uint256 indexed id, uint256 indexed lendID, address indexed creator, uint256 amount);
  event BorrowOfferWithdrawn(uint256 indexed id);
  event SwapAccepted(uint256 indexed id, uint256 indexed lendID, uint256 indexed borrowID);
  event SwapCompleted(uint256 indexed id, uint256 profit);

  constructor(address vybe) Ownable(msg.sender) {
    _VYBE = IERC20(vybe);
  }

  function register(bytes4 id, bytes32 hash) external onlyOwner {
    registeredIDs[id] = true;
    verifiedContracts[id] = hash;
  }

  function offerArbitration(uint256 fee) external {
    // if fee is zero, this arbitrator will appear as having not offered their services
    require(fee != 0);
    registeredArbitrators[msg.sender] = fee;
    emit ArbitratorUpdate(msg.sender, fee);
  }

  function removeArbitration() external {
    registeredArbitrators[msg.sender] = 0;
    emit ArbitratorUpdate(msg.sender, 0);
  }

  // offer a loan with the expectation of fixed interest
  function offerLend(address token, uint256 amount, uint256 weeklyInterestDivisor,
                    address arbitrator, uint256 expectedArbitrationFee,
                    bytes4 expectedUseID) external returns (uint256) {
    uint256 arbitrationFee = 0;
    if (arbitrator != msg.sender) {
      arbitrationFee = registeredArbitrators[arbitrator];
      // make sure this is a valid arbitrator
      require(arbitrationFee != 0);
    }
    // stop arbitrators from frontrunning this TX to charge a higher fee
    require(arbitrationFee == expectedArbitrationFee);

    // lock in the loanable tokens
    require(IERC20(token).transferFrom(msg.sender, address(this), amount));

    nextID = nextID.add(1);
    lends[nextID] = LendOffer(
      msg.sender, arbitrator, arbitrationFee, IERC20(token), amount,
      weeklyInterestDivisor, expectedUseID);
    emit NewLendOffer(nextID, msg.sender, expectedUseID, arbitrator);
    return nextID;
  }

  function cancelLend(uint256 id) external {
    LendOffer storage offer = lends[id];
    require(msg.sender == offer.creator);
    require(offer.amount != 0);

    uint256 amount = offer.amount;
    offer.amount = 0;

    require(offer.token.transfer(msg.sender, amount));
    emit LendOfferWithdrawn(id);
  }

  function calculateBorrowFee(BorrowOffer memory borrow) internal view returns (uint256) {
    return borrow.amount.mul(borrow.lengthInWeeks).div(lends[borrow.lendID].weeklyInterestDivisor);
  }

  function _initiateSwap(uint256 borrowID) private returns (uint256) {
    // make sure the borrow is open and mark it as closed
    BorrowOffer storage borrow = borrows[borrowID];
    require(borrow.open);
    borrow.open = false;

    // mark that the loan amount is lower
    LendOffer storage lend = lends[borrow.lendID];
    lend.amount = lend.amount.sub(borrow.amount);

    // start the collector
    require(lend.token.transfer(address(borrow.collector), borrow.amount));
    borrow.collector.start();

    // burn the swap fee
    _VYBE.transferFrom(borrow.creator, address(this), 10 ** 18);
    _VYBE.burn(10 ** 18);

    // transfer the fixed interest
    require(lend.token.transfer(lend.creator, calculateBorrowFee(borrow)));

    // create the swap object
    nextID = nextID.add(1);
    swaps[nextID] = SwapInfo(block.timestamp, borrow.lendID, borrowID);
    emit SwapAccepted(nextID, borrow.lendID, borrowID);
    return nextID;
  }

  function offerBorrow(uint256 id, uint256 amount, uint256 lengthInWeeks,
                       address collector) external returns (uint256, uint256) {
    LendOffer memory lend = lends[id];

    // make sure this lend can support a borrow of this size
    require(lend.amount >= amount);

    // create the borrow
    nextID = nextID.add(1);
    borrows[nextID] = BorrowOffer(msg.sender, id, amount, lengthInWeeks,
      IInterestRateCollector(collector), true);

    // collect the fixed interest now
    require(lend.token.transferFrom(msg.sender, address(this),
            calculateBorrowFee(borrows[nextID])));
    emit NewBorrowOffer(nextID, id, msg.sender, amount);

    if (registeredIDs[lend.useID]) {
      bytes32 hash;
      assembly { hash := extcodehash(collector) }
      require(hash == verifiedContracts[lend.useID]);
      require(IInterestRateCollector(collector).token() == address(lend.token));
      require(IInterestRateCollector(collector).manager() == address(this));
      return (nextID, _initiateSwap(nextID));
    }
    return (nextID, 0);
  }

  function cancelBorrow(uint256 id) external {
    BorrowOffer storage borrow = borrows[id];
    require(borrow.open);
    require(msg.sender == borrow.creator);
    borrow.open = false;
    emit BorrowOfferWithdrawn(id);

    require(lends[borrow.lendID].token.transfer(msg.sender, calculateBorrowFee(borrow)));
  }

  function accept(uint256 borrowID) external returns (uint256 res) {
    // this ensures the borrow is open
    // if this is to a verified contract, this will error right now
    res = _initiateSwap(borrowID);

    // since contract execution has continued, check this person is authorized to accept this borrow
    BorrowOffer storage borrow = borrows[borrowID];
    LendOffer storage lend = lends[borrow.lendID];
    require((msg.sender == lend.creator) || (msg.sender == lend.arbitrator));
    // collect the arbitration fee
    if (lend.arbitratorFee != 0) {
      // if this was done by the arbitrator, pay them for this TX
      if (msg.sender == lend.arbitrator) {
        require(_VYBE.transferFrom(lend.creator, lend.arbitrator, lend.arbitratorFee));
      }
      // collect the fee for if the arbitrator calls complete
      require(_VYBE.transferFrom(lend.creator, address(this), lend.arbitratorFee));
    }
  }

  function complete(uint256 id) external {
    SwapInfo storage swap = swaps[id];
    BorrowOffer storage borrow = borrows[swap.borrowID];
    require(swap.started + (borrow.lengthInWeeks.mul(1 weeks)) <= block.timestamp);

    LendOffer storage lend = lends[borrow.lendID];
    // it's fully secure to let anyone claim this
    // that said, latency is a problem, and this prevents multiple people trying to claim the arbitration fee
    require((msg.sender == lend.creator) || (msg.sender == lend.arbitrator));
    require(_VYBE.transfer(msg.sender, lends[borrow.lendID].arbitratorFee));

    // finish the swap
    borrow.collector.end();

    // payout
    uint256 balance = lend.token.balanceOf(address(borrow.collector));
    if (balance <= borrow.amount) {
      require(lend.token.transferFrom(address(borrow.collector), lend.creator, balance));
      balance = 0;
    } else {
      require(lend.token.transferFrom(address(borrow.collector), lend.creator, borrow.amount));
      balance = lend.token.balanceOf(address(borrow.collector));
      require(lend.token.transferFrom(address(borrow.collector), borrow.creator,
                                             balance));
    }
    emit SwapCompleted(id, balance);
  }
 }
