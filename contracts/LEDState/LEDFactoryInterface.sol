/*
  @title LEDFactoryInterface v0.0.1
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
Title:       LEDState Contract Factory interface
Description: interface to LEDFactory


*/

pragma solidity ^0.5.0;
/**
 * @author Joshua Bijak
 * @dev LEDFactory interface
 * @notice LEDFactory interface
 */
interface LEDFactoryInterface{
    function createLED(bool defaultState, address _roomContract,address _roomOwner, address _GSNAddress, uint256 _daliShortAddress, uint256 _LEDDim, uint256 _LEDWattage) external returns(address LEDstateAddress);
    function createLEDStateUpgradeable(address _creolAdmin, bytes calldata _encodedData) external returns (address);
    function addApprovedRoomState(address _newRoomStateAddress) external;
    function removeApprovedRoomState(address _oldRoomStateAddress) external;
    event LogNewLED(address LED);
}
