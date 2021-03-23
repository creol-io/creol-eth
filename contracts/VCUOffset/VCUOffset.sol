
pragma solidity ^0.5.0;
/*
  @title VCUOFfset v0.0.1
 ________  ________  _______   ________  ___          
|\   ____\|\   __  \|\  ___ \ |\   __  \|\  \         
\ \  \___|\ \  \|\  \ \   __/|\ \  \|\  \ \  \        
 \ \  \    \ \   _  _\ \  \_|/_\ \  \\\  \ \  \       
  \ \  \____\ \  \\  \\ \  \_|\ \ \  \\\  \ \  \____  
   \ \_______\ \__\\ _\\ \_______\ \_______\ \_______\
    \|_______|\|__|\|__|\|_______|\|_______|\|_______|
                                             
 



 __      _______ _    _  ____   __  __          _   
 \ \    / / ____| |  | |/ __ \ / _|/ _|        | |  
  \ \  / / |    | |  | | |  | | |_| |_ ___  ___| |_ 
   \ \/ /| |    | |  | | |  | |  _|  _/ __|/ _ \ __|
    \  / | |____| |__| | |__| | | | | \__ \  __/ |_ 
     \/   \_____|\____/ \____/|_| |_| |___/\___|\__|
                                                    
                                                    
                                   

Author:      Joshua Bijak
Date:        February 17, 2020
Title:       VCUOFfset Contract for offsetting VCUs
Description: Contract collects and aggregates offsetting information

 
*/

import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";


import "../GridMix/GridMixInterface.sol";
import "../RoomState/RoomStateInterface.sol";
import "../LEDState/LEDStateInterface.sol";

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "creol-carbon-eth/contracts/CarbonVCU/CarbonVCUInterface.sol";
import "creol-carbon-eth/contracts/VCUSubToken/VCUSubTokenInterface.sol";

contract VCUOffset is Initializable, Ownable {
    
    using SafeMath for uint256;
    
    event VCUOffsetConfirmed(address VCU, uint256 VCUID, uint256 amountC02);
    
    GridMixInterface private genericGridMixInterface;
    RoomStateInterface private genericRoomStateInterface;
    CarbonVCUInterface private genericCarbonVCUInterface;
    
    uint256 private currentWattHoursToOffset;
    uint256 private currentAvailableOffsets;
    uint256 public tokensToBurn;
    
    uint256 public CreolOffsetFactor;
    
    event TokensReady(uint256 tokensToBurn);
    
    constructor() public{

    }
    
    function initialize (address _GridMixContract, address _RoomStateContract, address _CarbonVCUContract, address _owner, uint256 _offsetFactor) public initializer{
        require(_offsetFactor > 0);      
        genericGridMixInterface = GridMixInterface(_GridMixContract);
        genericRoomStateInterface = RoomStateInterface(_RoomStateContract);
        genericCarbonVCUInterface = CarbonVCUInterface(_CarbonVCUContract);
        CreolOffsetFactor = _offsetFactor;
        super.initialize(_owner);
        
    }
    /**
     * @notice Changes Grid Mix contract
     * @dev  -  Updates Grid Mix Interface
     * @param _newGridMixContract New address of GridMix contract
     * 
     */
    function updateGridMixInterface(address _newGridMixContract) public onlyOwner {
         genericGridMixInterface = GridMixInterface(_newGridMixContract);
    }
     /**
     * @notice Changes RoomState contract
     * @dev  -  Updates RoomState Interface
     * @param _newRoomStateContract New address of RoomState contract
     * 
     */
     function updateRoomStateInterface(address _newRoomStateContract) public onlyOwner {
         genericRoomStateInterface = RoomStateInterface(_newRoomStateContract);
     }
     
     function updateOffsetFactor(uint256 _newFactor) public onlyOwner {
         CreolOffsetFactor = _newFactor;
     }
    
    function updateCarbonVCU(address _newCarbonVCU) public onlyOwner {
        
        genericCarbonVCUInterface = CarbonVCUInterface(_newCarbonVCU);
    }
    
    function sendOffset(string memory _groupID, uint256[] memory _VCUIDs, string memory countryCode) public payable onlyOwner{
            
            collectWattHours(_groupID);
            collectAvailableOffsets(_VCUIDs);
            collectGridMix(countryCode);
    }
    
    function collectWattHours(string memory _groupID) internal{
        
        currentWattHoursToOffset = 0;
        address[] memory LEDs = genericRoomStateInterface.getGroupAddresses(_groupID);
        LEDStateInterface genericLEDStateInterface;
        for (uint32 i = 0 ; i < LEDs.length; i++){
            genericLEDStateInterface = LEDStateInterface(LEDs[i]);
            uint256 LEDhours = genericLEDStateInterface.getDailyRuntime();
            uint256 watts = genericLEDStateInterface.getWattage();
            
            // Add Wh to offset calculator
            currentWattHoursToOffset = currentWattHoursToOffset+((LEDhours/3600)*watts);
            
        }

        
        
    }
    
    function collectAvailableOffsets(uint256[] memory _VCUIDs) internal{
        
        currentAvailableOffsets = 0;
        VCUSubTokenInterface genericVCUSubtokenInterface;
        for (uint32 i = 0; i < _VCUIDs.length; i++){
            address subtokenAddress = genericCarbonVCUInterface.gettokenIDtoSubtokenAddress(_VCUIDs[i]);
            genericVCUSubtokenInterface = VCUSubTokenInterface(subtokenAddress);
            
            currentAvailableOffsets = currentAvailableOffsets + genericVCUSubtokenInterface.totalSupply();
        }
        
    }
    
    function collectGridMix(string memory countryCode) public payable onlyOwner{
        genericGridMixInterface.requestCO2Signal.value(msg.value)(countryCode);
    }
    
    function continueOffset(uint256 _gridIntensity) public{
        //TODO: Ensure that only the grid mix contract can call this
        require(msg.sender == address(genericGridMixInterface), "GridMix Contract doesn't match");
        tokensToBurn = CreolOffsetFactor * _gridIntensity * (currentWattHoursToOffset/1000);
        //require(currentAvailableOffsets >= tokensToBurn, "Not Enough Offsets, try again after topping up");
        emit TokensReady(tokensToBurn);
            
        
    }
    function finishOffset(uint256[] memory _VCUIDs, address _vcuOwner) public onlyOwner{
        require(currentAvailableOffsets >= tokensToBurn, "Not Enough Offsets, try again after topping up using startOffset()");
        
        
        VCUSubTokenInterface genericVCUSubtokenInterface;
        uint32 i = 0;
        while (tokensToBurn > 0){
            address subtokenAddress = genericCarbonVCUInterface.gettokenIDtoSubtokenAddress(_VCUIDs[i]);
            genericVCUSubtokenInterface = VCUSubTokenInterface(subtokenAddress);
            
            uint256 curSupply = genericVCUSubtokenInterface.totalSupply();
            
            if (tokensToBurn > curSupply){
                //ASSUMES THAT APPROVAL HAS BEEN GIVEN
                //Otherwise this will fail
                genericVCUSubtokenInterface.burnFrom(_vcuOwner,curSupply);
                tokensToBurn = tokensToBurn - curSupply;
            }
            else if (tokensToBurn < curSupply){
                genericVCUSubtokenInterface.burnFrom(_vcuOwner,tokensToBurn);
                tokensToBurn = 0;
                
                
            }
        }
        
    }
    
}