// SPDX-License-Identifier: MIT
// This narrows down how ee calls the target contract's functions
pragma solidity ^0.8.18;
import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract Handler is Test {
    DSCEngine dsce;
    DecentralizedStableCoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;
    // Counter for how many times mint was invoked through the handler
    uint256 public timesMintCalled;

    constructor(DSCEngine _dsce, DecentralizedStableCoin _dsc) {
        dsce = _dsce;
        dsc = _dsc;

        address[] memory collateralTokens = dsce.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
    }

    // Reedeem collateral
    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        ERC20Mock collateral = getCollateralFromSeed(collateralSeed);
        dsce.depositCollateral(address(collateral), amountCollateral);
    }

    // Mint DSC via the DSCEngine and increment the counter when successful
    function mintDsc(uint256 amountDsc) public {
        dsce.mintDsc(amountDsc);
        timesMintCalled++;
    }

    // Helper function to get collateral token based on seed
    function getCollateralFromSeed(uint256 collateralSeed) private view returns(ERC20Mock) {
        if (collateralSeed % 2 ==0) {
            return weth;
        }
        return wbtc;
    }
}
