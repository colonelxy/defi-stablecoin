// //SPDX-License-Identifier: MIT

// // What are our invariants?
// // 1. Health factor is always above minimum threshold after minting/burning DSC
// // 2. Health factor is always above minimum threshold after depositing/withdrawing collateral
// // 3. Health factor is always above minimum threshold after redeeming collateral
// // 4. Health factor is always above minimum threshold after liquidations
// // 5. Total DSC minted across all users is always less than the total collateral value in the system
// // 6. Getter view functions should never revert -> evergreen invariant
// // 7. Only allowed collateral tokens can be used in the system -> evergreen invariant
// pragma solidity ^0.8.18;

// import {Test, console} from "forge-std/Test.sol";
// import {StdInvariant} from "forge-std/StdInvariant.sol";
// import {DeployDSC} from "../../script/DeployDSC.s.sol";
// import {DSCEngine} from "../../src/DSCEngine.sol";
// import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
// import {HelperConfig} from "../../script/HelperConfig.s.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// contract OpenInvariantsTest is StdInvariant, Test{
//     DeployDSC deployer;
//     DSCEngine dsce;
//     DecentralizedStableCoin dsc;
//     HelperConfig config;
//     address weth;
//     address wbtc;
//     function setUp() external {
//         deployer = new DeployDSC();
//         (dsc, dsce, config) = deployer.run();
//     (,, weth, wbtc,) = config.activeNetworkConfig();
//         targetContract(address(dsce));
//     }

//     function invariant_protocolMustHaveMoreValueThanTotallSupply() public view {
//         uint256 totalSupply = dsc.totalSupply();
//         uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dsce));
//         uint256 totalBtcDeposited = IERC20(wbtc).balanceOf(address(dsce));

//         uint256 wethValue = dsce.getUsdValue(weth, totalWethDeposited);
//         uint256 wbtcValue = dsce.getUsdValue(wbtc, totalBtcDeposited);

//         // If no DSC is minted, skip strict check (nothing to back)
//         if (totalSupply == 0) {
//             return;
//         }
//         // Protocol collateral value must be strictly greater than total DSC supply
//         console.log("WETH Value", wethValue);
//         console.log("WBTC Value", wbtcValue);
//         console.log("Total Supply", totalSupply);

//         assert((wethValue + wbtcValue) > totalSupply);
//     }
// }