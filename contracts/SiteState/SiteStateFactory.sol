pragma solidity ^0.5.0;

import "./SiteStateFactoryInterface.sol";
import "./SiteState.sol";


import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/upgrades/contracts/application/App.sol";

import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";


contract SiteStateFactory is SiteStateFactoryInterface, Initializable, Ownable {

    address[] public SiteStates;
    mapping(address => bool) public SiteStateExists;
    mapping(address => bool) public ApprovedControlStates;
    App private creolApp;


    modifier onlyApprovedControlState(){
        require(ApprovedControlStates[msg.sender] || msg.sender == owner(), "not an approved control state");
        _;
    }

    event LogNewSiteState(address SiteState);
    event newControlStateAddress(address _newControlState);
    event removedControlStateAddress(address _oldControlState);
    event newAppPackage(App _appPackage);


    function initialize (address _owner,App _creolApp) public initializer {
        Ownable.initialize(_owner);
        setAppPackage(_creolApp);
    }

    function setAppPackage (App _appPackage) public onlyOwner {
        creolApp = _appPackage;
        emit newAppPackage(_appPackage);
    }
    function createSiteStateUpgradeable(address _proxyAdmin, bytes memory _encodedData) public onlyApprovedControlState returns (address) {
        string memory packageName = "creol-eth";
        string memory contractName = "SiteState";
        address newSiteState = address(creolApp.create(packageName,contractName,_proxyAdmin, _encodedData));
        SiteStates.push(newSiteState);
        SiteStateExists[newSiteState] = true;

        emit LogNewSiteState(newSiteState);

        return newSiteState;
    }
    function addApprovedControlState(address _newControlStateAddress) public onlyApprovedControlState {
        ApprovedControlStates[_newControlStateAddress] = true;
        emit newControlStateAddress(_newControlStateAddress);
    }
    function removeApprovedControlState(address _oldControlStateAddress) public onlyApprovedControlState {
        ApprovedControlStates[_oldControlStateAddress] = false;
        emit removedControlStateAddress(_oldControlStateAddress);
    }
}
