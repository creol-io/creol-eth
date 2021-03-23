/*
  @title LEDFactory v0.0.1
 ________  ________  _______   ________  ___
|\   ____\|\   __  \|\  ___ \ |\   __  \|\  \
\ \  \___|\ \  \|\  \ \   __/|\ \  \|\  \ \  \
 \ \  \    \ \   _  _\ \  \_|/_\ \  \\\  \ \  \
  \ \  \____\ \  \\  \\ \  \_|\ \ \  \\\  \ \  \____
   \ \_______\ \__\\ _\\ \_______\ \_______\ \_______\
    \|_______|\|__|\|__|\|_______|\|_______|\|_______|




  _      ______ _____  ______         _
 | |    |  ____|  __ \|  ____|       | |
 | |    | |__  | |  | | |__ __ _  ___| |_ ___  _ __ _   _
 | |    |  __| | |  | |  __/ _` |/ __| __/ _ \| '__| | | |
 | |____| |____| |__| | | | (_| | (__| || (_) | |  | |_| |
 |______|______|_____/|_|  \__,_|\___|\__\___/|_|   \__, |
                                                     __/ |
                                                    |___/


Author:      Joshua Bijak
Date:        October 4, 2019
Title:       LEDState Contract Factory
Description: Contract that deploys LEDState contracts for gas optimizations

  ___                            _
|_ _|_ __ ___  _ __   ___  _ __| |_ ___
 | || '_ ` _ \| '_ \ / _ \| '__| __/ __|
 | || | | | | | |_) | (_) | |  | |_\__ \
|___|_| |_| |_| .__/ \___/|_|   \__|___/
              |_|

*/

pragma solidity ^0.5.0;

import "./LEDFactoryInterface.sol";
import "./LEDState.sol";


import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/upgrades/contracts/application/App.sol";

import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
/**
 * @author Joshua Bijak
 * @dev Contract to deploy LED state contracts for tracking.
 * @notice LEDFactory: Creates LEDState contracts using LEDLibrary
 *
 */
contract LEDFactory is LEDFactoryInterface, Initializable, Ownable {

   /**
     *
           _____ _       _           _
          / ____| |     | |         | |
         | |  __| | ___ | |__   __ _| |___
         | | |_ | |/ _ \| '_ \ / _` | / __|
         | |__| | | (_) | |_) | (_| | \__ \
          \_____|_|\___/|_.__/ \__,_|_|___/


    */

    address[] public LEDs;
    mapping(address => bool) LEDExists;
    mapping(address => bool) ApprovedRoomStates;
    App private creolApp;

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

    event LogNewLED(address LED);
    event newAppPackage(App _appPackage);
    
    event newApprovedRoomState(address _newRoomState);
    event removedApprovedRoomState(address _oldRoomState);
    
        /**
     *   __  __           _ _  __ _               
        |  \/  |         | (_)/ _(_)              
        | \  / | ___   __| |_| |_ _  ___ _ __ ___ 
        | |\/| |/ _ \ / _` | |  _| |/ _ \ '__/ __|
        | |  | | (_) | (_| | | | | |  __/ |  \__ \
        |_|  |_|\___/ \__,_|_|_| |_|\___|_|  |___/
        
    */
    modifier onlyApprovedRoomStates(){
        require(ApprovedRoomStates[msg.sender] || msg.sender == owner(), "Not an approved roomState");
        _;
    }


    /**
      *   ______                _   _
         |  ____|              | | (_)
         | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
         |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
         | |  | |_| | | | | (__| |_| | (_) | | | \__ \
         |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
     */
     /**
      * @dev creates a new LEDState contract
      * @notice create new LEDState contract
      * @param defaultState first state of the LED , on or off
      * @param _roomContract Address of the room this LED belongs to
      * @param _daliShortAddress DALI short address from 0-63
      * @param _LEDDim Dim rate assigned to LED 0-254
      * @param _LEDWattage Wattage associated with this LED
      * @return LEDstateAddress Address of the new LEDState contract
      */
    function createLED(bool defaultState, address _roomContract,address _roomOwner,address _GSNAddress, uint256 _daliShortAddress, uint256 _LEDDim, uint256 _LEDWattage) public onlyApprovedRoomStates returns(address LEDstateAddress)
    {
        LEDState newLuminaire = new LEDState();
        newLuminaire.initialize(defaultState,_roomContract,_roomOwner,_GSNAddress, _daliShortAddress,_LEDDim, _LEDWattage);
        LEDs.push(address(newLuminaire));
        LEDExists[address(newLuminaire)] = true;
        emit LogNewLED(address(newLuminaire));
        return address(newLuminaire);
    }
    function setAppPackage (App _appPackage) public onlyOwner {
        creolApp = _appPackage;
        emit newAppPackage(_appPackage);
    }
    function createLEDStateUpgradeable(address _proxyAdmin, bytes memory _encodedData) public onlyApprovedRoomStates returns (address) {
        string memory packageName = "creol-eth";
        string memory contractName = "LEDState";
        address newLEDState = address(creolApp.create(packageName,contractName,_proxyAdmin, _encodedData));
        LEDs.push(newLEDState);
        LEDExists[newLEDState] = true;

        emit LogNewLED(newLEDState);

        return newLEDState;
    }
    function initialize(address _owner, App _creolApp) public initializer {
        Ownable.initialize(_owner);
        setAppPackage(_creolApp);
        addApprovedRoomState(_owner);
        
        
    }
    
    function addApprovedRoomState(address _newRoomStateAddress) public onlyApprovedRoomStates {
        ApprovedRoomStates[_newRoomStateAddress] = true;
        emit newApprovedRoomState(_newRoomStateAddress);
    }
    function removeApprovedRoomState(address _oldRoomStateAddress) public onlyApprovedRoomStates {
        ApprovedRoomStates[_oldRoomStateAddress] = false;
        emit removedApprovedRoomState(_oldRoomStateAddress);
    }

}
