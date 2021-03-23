/*
  @title RoomStateFactory v0.1.4
 ________  ________  _______   ________  ___          
|\   ____\|\   __  \|\  ___ \ |\   __  \|\  \         
\ \  \___|\ \  \|\  \ \   __/|\ \  \|\  \ \  \        
 \ \  \    \ \   _  _\ \  \_|/_\ \  \\\  \ \  \       
  \ \  \____\ \  \\  \\ \  \_|\ \ \  \\\  \ \  \____  
   \ \_______\ \__\\ _\\ \_______\ \_______\ \_______\
    \|_______|\|__|\|__|\|_______|\|_______|\|_______|
                                             
 
 



                        
Author:      Joshua Bijak
Date:        July 23, 2020
Title:       RoomState Contract Factory
Description: Contract that deploys RoomState contracts for gas optimizations and OZ upgradeability
              
  ___                            _       
|_ _|_ __ ___  _ __   ___  _ __| |_ ___ 
 | || '_ ` _ \| '_ \ / _ \| '__| __/ __|
 | || | | | | | |_) | (_) | |  | |_\__ \
|___|_| |_| |_| .__/ \___/|_|   \__|___/
              |_|                       

*/

pragma solidity ^0.5.0; 

import "./RoomStateFactoryInterface.sol";
import "./RoomState.sol";


import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/upgrades/contracts/application/App.sol";

import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
/**
 * @author Joshua Bijak
 * @dev Contract to deploy RoomState contracts for tracking.
 * @notice RoomStateFactory: Creates RoomState contracts using RoomState Contract
 *
 */
contract RoomStateFactory is RoomStateFactoryInterface, Initializable, Ownable {
   
   /**
     * 
           _____ _       _           _     
          / ____| |     | |         | |    
         | |  __| | ___ | |__   __ _| |___ 
         | | |_ | |/ _ \| '_ \ / _` | / __|
         | |__| | | (_) | |_) | (_| | \__ \
          \_____|_|\___/|_.__/ \__,_|_|___/
                                           
                                   
    */
    
    address[] public RoomStates;
    mapping(address => bool) public RoomStateExists;
    mapping(address => bool) public ApprovedSiteStates;
    
    App private creolApp;
    
    
    /**
     *   __  __           _ _  __ _               
        |  \/  |         | (_)/ _(_)              
        | \  / | ___   __| |_| |_ _  ___ _ __ ___ 
        | |\/| |/ _ \ / _` | |  _| |/ _ \ '__/ __|
        | |  | | (_) | (_| | | | | |  __/ |  \__ \
        |_|  |_|\___/ \__,_|_|_| |_|\___|_|  |___/
        
    */
    modifier onlyApprovedSiteStates(){
        require(ApprovedSiteStates[msg.sender] || msg.sender == owner(),"not an approved site state");
        _;
    }
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
 
    event LogNewRoomState(address RoomState);
    event newSiteStateAddress(address _newSiteState);
    event removedSiteStateAddress(address _oldSiteState);
    event newAppPackage(App _appPackage);
    
    /**
      *   ______                _   _                 
         |  ____|              | | (_)                
         | |__ _   _ _ __   ___| |_ _  ___  _ __  ___ 
         |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
         | |  | |_| | | | | (__| |_| | (_) | | | \__ \
         |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
     */
    
    function initialize (address _owner, App _appPackage) public initializer {
        Ownable.initialize(_owner);
        setAppPackage(_appPackage);
        addApprovedSiteState(_owner);
        
    }
    
    function setAppPackage (App _appPackage) public onlyOwner {
        creolApp = _appPackage;
        emit newAppPackage(_appPackage);
    }
    function createRoomStateUpgradeable(address _proxyAdmin, bytes memory _encodedData) public onlyApprovedSiteStates returns (address) {
        string memory packageName = "creol-eth";
        string memory contractName = "RoomState";
        address newRoomState = address(creolApp.create(packageName,contractName,_proxyAdmin, _encodedData));
        RoomStates.push(newRoomState);
        RoomStateExists[newRoomState] = true;
        
        emit LogNewRoomState(newRoomState);
        
        return newRoomState;
    }
    function addApprovedSiteState(address _newSiteStateAddress) public onlyApprovedSiteStates {
        ApprovedSiteStates[_newSiteStateAddress] = true;
        emit newSiteStateAddress(_newSiteStateAddress);
    }
    function removeApprovedSiteState(address _oldSiteStateAddress) public onlyApprovedSiteStates {
        ApprovedSiteStates[_oldSiteStateAddress] = false;
        emit removedSiteStateAddress(_oldSiteStateAddress);
    }
}