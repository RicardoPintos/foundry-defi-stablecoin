// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FailedERC20MockTransfer is ERC20 {
    constructor(string memory name, string memory symbol, address initialAccount, uint256 initialBalance)
        payable
        ERC20(name, symbol)
    {
        _mint(initialAccount, initialBalance);
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return false;
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}
