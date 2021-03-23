/*
  @title RoomStateFactory v0.0.1
 ________  ________  _______   ________  ___
|\   ____\|\   __  \|\  ___ \ |\   __  \|\  \
\ \  \___|\ \  \|\  \ \   __/|\ \  \|\  \ \  \
 \ \  \    \ \   _  _\ \  \_|/_\ \  \\\  \ \  \
  \ \  \____\ \  \\  \\ \  \_|\ \ \  \\\  \ \  \____
   \ \_______\ \__\\ _\\ \_______\ \_______\ \_______\
    \|_______|\|__|\|__|\|_______|\|_______|\|_______|





Author:      Joshua Bijak
Date:        July 23, 2020
Title:       RoomState Contract Factory interface
Description: interface to RoomStateFactory


*/

pragma solidity ^0.5.0;
/**
 * @author Joshua Bijak
 * @dev RoomStateFactory interface
 * @notice RoomStateFactory interface
 */
interface RoomStateFactoryInterface {
    function createRoomStateUpgradeable(address _creolAdmin, bytes calldata _encodedData) external returns (address);
    function addApprovedSiteState(address _newSiteStateAddress) external;
    function removeApprovedSiteState(address _oldSiteStateAddress) external;

    event LogNewRoomState(address RoomState);
}
