// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FailedDscMint is ERC20Burnable, Ownable {
    error FailedDscMint__MustBeMoreThanZero();
    error FailedDscMint__NotZeroAddress();

    address private s_dscOwner = msg.sender;

    constructor() ERC20("DecentralizedStableCoin", "DSC") Ownable(s_dscOwner) {}

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert FailedDscMint__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert FailedDscMint__MustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return false;
    }
}
