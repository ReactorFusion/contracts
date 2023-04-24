// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/math/Math.sol";

struct Ledger {
    uint256 total;
    mapping(bytes32 => uint256) balances;
    mapping(bytes32 => Emission) emissions;
}

struct Emission {
    uint256 current;
    uint256 balance;
    mapping(bytes32 => uint256) snapshots;
}

library LedgerLib {
    using LedgerLib for Ledger;

    function deposit(
        Ledger storage self,
        bytes32 account,
        uint256 amount
    ) internal {
        self.total += amount;
        self.balances[account] += amount;
    }

    function shareOf(
        Ledger storage self,
        bytes32 account
    ) internal view returns (uint256) {
        if (self.total == 0) return 0;
        return (self.balances[account] * 1e18) / self.total;
    }

    function withdraw(
        Ledger storage self,
        bytes32 account,
        uint256 amount
    ) internal {
        self.total -= amount;
        self.balances[account] -= amount;
    }

    function withdrawAll(
        Ledger storage self,
        bytes32 account
    ) internal returns (uint256) {
        uint256 amount = self.balances[account];
        self.withdraw(account, amount);
        return amount;
    }

    function reward(
        Ledger storage self,
        bytes32 emissionToken,
        uint256 amount
    ) internal {
        Emission storage emission = self.emissions[emissionToken];
        if (self.total != 0) {
            emission.current += (amount * 1e18) / self.total;
        }
        emission.balance += amount;
    }

    function harvest(
        Ledger storage self,
        bytes32 account,
        bytes32 emissionToken
    ) internal returns (uint256) {
        Emission storage emission = self.emissions[emissionToken];
        uint256 harvested = (self.balances[account] *
            (emission.current - emission.snapshots[account])) / 1e18;
        emission.snapshots[account] = emission.current;
        emission.balance -= harvested;
        return harvested;
    }

    function rewardsLeft(
        Ledger storage self,
        bytes32 emissionToken
    ) internal view returns (uint256) {
        Emission storage emission = self.emissions[emissionToken];

        return emission.balance;
    }
}
