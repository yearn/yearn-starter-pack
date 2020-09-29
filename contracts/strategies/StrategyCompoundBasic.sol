// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

import "@openzeppelinV2/contracts/token/ERC20/IERC20.sol";
import "@openzeppelinV2/contracts/math/SafeMath.sol";
import "@openzeppelinV2/contracts/utils/Address.sol";
import "@openzeppelinV2/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelinV2/contracts/token/ERC20/ERC20.sol";
import "@openzeppelinV2/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelinV2/contracts/ownership/Ownable.sol";

import "../../interfaces/compound/cToken.sol";
import "../../interfaces/compound/Comptroller.sol";

/*

 Very low risk COMP farming strategy

*/

contract StrategyCompoundBasic {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IERC20 public constant comp = IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888);
    Comptroller public constant compound = Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B); // Comptroller address for compound.finance

    cToken public c;
    IERC20 public underlying;

    address public governance;
    address public controller;

    constructor(cToken _cToken) public {
        governance = msg.sender;
        controller = msg.sender;
        c = _cToken;
        underlying = IERC20(_cToken.underlying());
    }

    function claim() public {
        compound.claimComp(address(this));
    }

    function deposit() external {
        underlying.safeApprove(address(c), 0);
        underlying.safeApprove(address(c), underlying.balanceOf(address(this)));
        require(c.mint(underlying.balanceOf(address(this))) == 0, "COMPOUND: supply failed");
    }

    function withdraw(IERC20 asset) external {
        require(msg.sender == controller, "!controller");
        asset.safeTransfer(controller, asset.balanceOf(address(this)));
    }

    function _withdrawAll() external {
        require(msg.sender == controller, "!controller");
        uint256 amount = balanceCompound();
        if (amount > 0) {
            _withdrawSomeCompound(balanceCompoundInToken().sub(1));
        }
    }

    function _withdrawSomeCompound(uint256 _amount) public {
        require(msg.sender == controller, "!controller");
        uint256 b = balanceCompound();
        uint256 bT = balanceCompoundInToken();
        require(bT >= _amount, "insufficient funds");
        // can have unintentional rounding errors
        uint256 amount = (b.mul(_amount)).div(bT).add(1);
        _withdrawCompound(amount);
    }

    function _withdrawCompound(uint256 amount) public {
        require(msg.sender == controller, "!controller");
        require(c.redeem(amount) == 0, "COMPOUND: withdraw failed");
    }

    function balanceCompoundInToken() public view returns (uint256) {
        // Mantisa 1e18 to decimals
        uint256 b = balanceCompound();
        if (b > 0) {
            b = b.mul(c.exchangeRateStored()).div(1e18);
        }
        return b;
    }

    function balanceCompound() public view returns (uint256) {
        return c.balanceOf(address(this));
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }
}
