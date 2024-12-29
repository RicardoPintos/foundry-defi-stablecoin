// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FailedDscBurn is ERC20Burnable, Ownable {
    error FailedDscBurn__MustBeMoreThanZero();
    error FailedDscBurn__BurnAmountExceedsBalance();
    error FailedDscBurn__NotZeroAddress();

    address private s_dscOwner = msg.sender;

    constructor() ERC20("DecentralizedStableCoin", "DSC") Ownable(s_dscOwner) {}

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        _transfer(from, to, value);
        return false;
    }

    function burn(uint256 _amount) public view override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert FailedDscBurn__MustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert FailedDscBurn__BurnAmountExceedsBalance();
        }
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert FailedDscBurn__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert FailedDscBurn__MustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}
