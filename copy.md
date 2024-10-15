// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Import Foundry's Test framework
import "forge-std/Test.sol";

// Import the DSCEngine and DecentralizedStableCoin contracts
import "../src/DSCEngine.sol";
import "../src/DecentralizedStableCoin.sol";

// Import OpenZeppelin's ERC20 implementation
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Import Chainlink's AggregatorV3Interface
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title MockERC20
 * @dev A simple ERC20 token for testing purposes.
 */
contract MockERC20 is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    /**
     * @notice Mints tokens to a specified address.
     * @param to The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/**
 * @title MockPriceFeed
 * @dev A mock implementation of the AggregatorV3Interface for testing.
 */
contract MockPriceFeed is AggregatorV3Interface {
    int256 private price;
    uint8 private _decimals;

    /**
     * @param _price The fixed price to return.
     * @param decimals_ The number of decimals the price feed uses.
     */
    constructor(int256 _price, uint8 decimals_) {
        price = _price;
        _decimals = decimals_;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function description() external pure override returns (string memory) {
        return "Mock Price Feed";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    /**
     * @notice Returns the latest round data.
     * @return roundId The round ID.
     * @return answer The fixed price.
     * @return startedAt Timestamp when the round started.
     * @return updatedAt Timestamp when the round was updated.
     * @return answeredInRound The round ID that provided the answer.
     */
    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, price, 0, 0, 0);
    }

    // The following functions are part of the interface but are not used in the mock.
    function getRoundData(uint80 _roundId)
        external
        pure
        override
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        return (0, 0, 0, 0, 0);
    }

    function latestAnswer() external view override returns (int256) {
        return price;
    }
}

/**
 * @title DecentralizedStableCoin (Mock)
 * @dev A minimal mock implementation of the DecentralizedStableCoin for testing.
 */
contract MockDecentralizedStableCoin is DecentralizedStableCoin {
    constructor() DecentralizedStableCoin() {}

    /**
     * @notice Allows the test contract to mint DSC.
     * @param to The address to mint DSC to.
     * @param amount The amount of DSC to mint.
     */
    function mockMint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /**
     * @notice Allows the test contract to burn DSC.
     * @param from The address to burn DSC from.
     * @param amount The amount of DSC to burn.
     */
    function mockBurn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}

/**
 * @title DSCEngineTest
 * @dev Test suite for the DSCEngine contract using Foundry.
 */
contract DSCEngineTest is Test {
    DSCEngine private dsce;
    MockDecentralizedStableCoin private dsc;
    MockERC20 private weth;
    MockPriceFeed private wethPriceFeed;

    address private USER = address(1);

    // Events for testing
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @notice Setup function to initialize the test environment.
     */
    function setUp() public {
        // Deploy Mock ERC20 (e.g., WETH)
        weth = new MockERC20("Wrapped Ether", "WETH");

        // Deploy Mock Price Feed with WETH price = $2000 (assuming 8 decimals)
        wethPriceFeed = new MockPriceFeed(2000 * 1e8, 8);

        // Deploy Mock DecentralizedStableCoin
        dsc = new MockDecentralizedStableCoin();

        // Deploy DSCEngine with WETH as the only collateral token
        address;
        collateralTokens[0] = address(weth);

        address;
        priceFeeds[0] = address(wethPriceFeed);

        dsce = new DSCEngine(collateralTokens, priceFeeds, address(dsc));

        // Mint DSC permission to DSCEngine (assuming DSCEngine has the minter role)
        // This step depends on the actual implementation of DecentralizedStableCoin
        // For the mock, we can directly call mockMint

        // Mint WETH to USER
        weth.mint(USER, 10 ether);

        // Label addresses for better readability in logs
        vm.label(USER, "USER");
        vm.label(address(dsce), "DSCEngine");
        vm.label(address(dsc), "DSC");
        vm.label(address(weth), "WETH");
    }

    /**
     * @notice Test the successful deposit of collateral and minting of DSC.
     */
    function testDepositCollateralAndMintDsc_Success() public {
        uint256 depositAmount = 1 ether; // 1 WETH = $2000
        uint256 mintAmount = 1000 * 1e18; // Mint 1000 DSC

        // Simulate USER approving DSCEngine to spend WETH
        vm.startPrank(USER);
        weth.approve(address(dsce), depositAmount);

        // Expect the CollateralDeposited event
        vm.expectEmit(true, true, false, true);
        emit CollateralDeposited(USER, address(weth), depositAmount);

        // Expect the Transfer event from DSC minting
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), USER, mintAmount);

        // Call depositCollateralAndMintDsc
        dsce.depositCollateralAndMintDsc(address(weth), depositAmount, mintAmount);

        // Verify that the collateral was deposited correctly
        uint256 collateralDeposited = dsce.getAccountCollateralValue(USER);
        // Since 1 WETH = $2000, collateral value should be $2000
        assertEq(collateralDeposited, 2000 * 1e18, "Collateral value incorrect");

        // Verify that DSC was minted to USER
        uint256 dscBalance = dsc.balanceOf(USER);
        assertEq(dscBalance, mintAmount, "DSC minting incorrect");

        // Verify that DSCEngine holds the WETH
        uint256 dsceWethBalance = weth.balanceOf(address(dsce));
        assertEq(dsceWethBalance, depositAmount, "DSCEngine WETH balance incorrect");

        vm.stopPrank();
    }

    /**
     * @notice Test that depositing zero collateral reverts.
     */
    function testDepositCollateralAndMintDsc_RevertOnZeroCollateral() public {
        uint256 depositAmount = 0;
        uint256 mintAmount = 1000 * 1e18; // Attempt to mint 1000 DSC

        vm.startPrank(USER);
        weth.approve(address(dsce), depositAmount);

        // Expect the transaction to revert with DSCEngine__NeedMoreThanZero()
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__NeedMoreThanZero.selector));
        dsce.depositCollateralAndMintDsc(address(weth), depositAmount, mintAmount);

        vm.stopPrank();
    }

    /**
     * @notice Test that depositing a disallowed token reverts.
     */
    function testDepositCollateralAndMintDsc_RevertOnDisallowedToken() public {
        // Deploy another Mock ERC20 (e.g., DAI) which is not allowed
        MockERC20 dai = new MockERC20("Dai Stablecoin", "DAI");
        dai.mint(USER, 1000 ether);

        uint256 depositAmount = 100 ether; // Attempt to deposit 100 DAI
        uint256 mintAmount = 500 * 1e18; // Attempt to mint 500 DSC

        vm.startPrank(USER);
        dai.approve(address(dsce), depositAmount);

        // Expect the transaction to revert with DSCEngine__NotAllowedToken()
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__NotAllowedToken.selector));
        dsce.depositCollateralAndMintDsc(address(dai), depositAmount, mintAmount);

        vm.stopPrank();
    }

    /**
     * @notice Test that minting DSC reverts if collateral is insufficient.
     */
    function testDepositCollateralAndMintDsc_RevertOnInsufficientCollateral() public {
        uint256 depositAmount = 1 ether; // 1 WETH = $2000
        uint256 mintAmount = 3000 * 1e18; // Attempt to mint 3000 DSC, which exceeds collateral value

        vm.startPrank(USER);
        weth.approve(address(dsce), depositAmount);

        // Expect the transaction to revert with DSCEngine__BreaksHealthFactor
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, 0));
        dsce.depositCollateralAndMintDsc(address(weth), depositAmount, mintAmount);

        vm.stopPrank();
    }

    /**
     * @notice Test that multiple collateral deposits and mints work correctly.
     */
    function testDepositCollateralAndMintDsc_MultipleDepositsAndMints() public {
        uint256 firstDeposit = 2 ether; // 2 WETH = $4000
        uint256 firstMint = 1500 * 1e18; // Mint 1500 DSC

        uint256 secondDeposit = 1 ether; // 1 WETH = $2000
        uint256 secondMint = 500 * 1e18; // Mint 500 DSC

        vm.startPrank(USER);
        weth.approve(address(dsce), firstDeposit + secondDeposit);

        // First deposit and mint
        vm.expectEmit(true, true, false, true);
        emit CollateralDeposited(USER, address(weth), firstDeposit);
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), USER, firstMint);
        dsce.depositCollateralAndMintDsc(address(weth), firstDeposit, firstMint);

        // Second deposit and mint
        vm.expectEmit(true, true, false, true);
        emit CollateralDeposited(USER, address(weth), secondDeposit);
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), USER, secondMint);
        dsce.depositCollateralAndMintDsc(address(weth), secondDeposit, secondMint);

        // Verify total collateral
        uint256 totalCollateral = dsce.getAccountCollateralValue(USER);
        assertEq(totalCollateral, 6000 * 1e18, "Total collateral value incorrect");

        // Verify total DSC minted
        uint256 totalDsc = dsc.balanceOf(USER);
        assertEq(totalDsc, 2000 * 1e18, "Total DSC minted incorrect");

        // Verify DSCEngine WETH balance
        uint256 dsceWethBalance = weth.balanceOf(address(dsce));
        assertEq(dsceWethBalance, firstDeposit + secondDeposit, "DSCEngine WETH balance incorrect");

        vm.stopPrank();
    }

    /**
     * @notice Test that depositing without approving DSCEngine reverts.
     */
    function testDepositCollateralAndMintDsc_RevertOnNoApproval() public {
        uint256 depositAmount = 1 ether;
        uint256 mintAmount = 1000 * 1e18;

        vm.startPrank(USER);
        // Do not approve DSCEngine to spend WETH

        // Expect the transaction to revert with DSCEngine__TransferFailed()
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__TransferFailed.selector));
        dsce.depositCollateralAndMintDsc(address(weth), depositAmount, mintAmount);

        vm.stopPrank();
    }
}
