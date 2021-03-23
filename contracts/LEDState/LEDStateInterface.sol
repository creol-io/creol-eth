
pragma solidity ^0.5.0;
/*
  @title LEDStateInterface v0.0.1
 ________  ________  _______   ________  ___          
|\   ____\|\   __  \|\  ___ \ |\   __  \|\  \         
\ \  \___|\ \  \|\  \ \   __/|\ \  \|\  \ \  \        
 \ \  \    \ \   _  _\ \  \_|/_\ \  \\\  \ \  \       
  \ \  \____\ \  \\  \\ \  \_|\ \ \  \\\  \ \  \____  
   \ \_______\ \__\\ _\\ \_______\ \_______\ \_______\
    \|_______|\|__|\|__|\|_______|\|_______|\|_______|
                                             
 

  _      ______ _____  ______         _                   _____       _             __               
 | |    |  ____|  __ \|  ____|       | |                 |_   _|     | |           / _|              
 | |    | |__  | |  | | |__ __ _  ___| |_ ___  _ __ _   _  | |  _ __ | |_ ___ _ __| |_ __ _  ___ ___ 
 | |    |  __| | |  | |  __/ _` |/ __| __/ _ \| '__| | | | | | | '_ \| __/ _ \ '__|  _/ _` |/ __/ _ \
 | |____| |____| |__| | | | (_| | (__| || (_) | |  | |_| |_| |_| | | | ||  __/ |  | || (_| | (_|  __/
 |______|______|_____/|_|  \__,_|\___|\__\___/|_|   \__, |_____|_| |_|\__\___|_|  |_| \__,_|\___\___|
                                                     __/ |                                           
                                                    |___/                                            
Author:      Joshua Bijak
Date:        Nov 14, 2019
Title:       LEDState Interface
Description: interface to LEDState

 
*/
/**
 * @author Joshua Bijak
 * @dev LEDState interface
 * @notice LEDState interface
 */

interface LEDStateInterface {
    /**
     * 
          ______               _       
         |  ____|             | |      
         | |____   _____ _ __ | |_ ___ 
         |  __\ \ / / _ \ '_ \| __/ __|
         | |___\ V /  __/ | | | |_\__ \
         |______\_/ \___|_| |_|\__|___/
                                       
     * 
     * 
     */

    event daliShortAddressUpdated(uint256 daliShortAddress);
    event dateStarted(uint256 startDate);
    event stateUpdated(bool updatedState);
    event roomChanged(address roomContract);
    event dimUpdated(uint256 LEDDim);
    event wattageUpdated(uint256 LEDWattage);
    event lastOffsetUpdated(uint256 lastOffsetTime);
    /**
      *   ______                _   _                 
         |  ____|              | | (_)                
         | |__ _   _ _ __   ___| |_ _  ___  _ __  ___ 
         |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
         | |  | |_| | | | | (__| |_| | (_) | | | \__ \
         |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
     */
    function initialize (bool defaultState, address _roomContract,address _roomOwner,address _GSNAddress, uint256 _daliShortAddress, uint256 _LEDDim, uint256 _LEDWattage) external; 
    function onDim(bool newState, uint256 _LEDDim) external;
    function updateState(bool newState) external;
    function updateDim(uint256 _LEDDim) external;
    function updateWattage(uint256 _LEDWattage) external;
    function updatedaliShortAddr(uint256 newdaliShortAddr) external;
    function updateRoomContract(address newRoomAddr) external;
    function updateRuntimeClocks(bool newState) external;
    function updateLastOffsetTime() external;
    function getDailyRuntime() external view returns (uint256 dailyRun);
    function getWeeklyRuntime() external view returns (uint256 weeklyRun);
    function getMonthlyRuntime() external view returns (uint256 monthlyRun);
    function getYearlyRuntime() external view returns (uint256 yearlyRun);
    function getAllRuntime() external view returns (uint256 alltimeRun);
    function getDim () external view returns (uint256 currentDim);
    function getState () external view returns (bool currentState);
    function getWattage () external view returns (uint256 currentWattage);
    function getDALIShortAddress () external view returns (uint256 currentDALIShort);
    function getRoomContract () external view returns (address currentRoom);
    function getStartDate () external view returns (uint256 startDate);
    function getLastOffsetDate () external view returns (uint256 lastOffsetTime);
    function setGSNAllowed(address _newGSNAddress) external;
    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256 maxPossibleCharge
    ) external view returns (uint256, bytes memory);
    function setRelayHubAddress() external;
    function getRecipientBalance() external view returns (uint);
}