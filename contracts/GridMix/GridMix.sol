
pragma solidity ^0.5.0;
/**
 *
 *
 *
 *   @title GridMix v0.0.1
 ________  ________  _______   ________  ___
|\   ____\|\   __  \|\  ___ \ |\   __  \|\  \
\ \  \___|\ \  \|\  \ \   __/|\ \  \|\  \ \  \
 \ \  \    \ \   _  _\ \  \_|/_\ \  \\\  \ \  \
  \ \  \____\ \  \\  \\ \  \_|\ \ \  \\\  \ \  \____
   \ \_______\ \__\\ _\\ \_______\ \_______\ \_______\
    \|_______|\|__|\|__|\|_______|\|_______|\|_______|



 *
 *
   _____      _     _ __  __ _
  / ____|    (_)   | |  \/  (_)
 | |  __ _ __ _  __| | \  / |___  __
 | | |_ | '__| |/ _` | |\/| | \ \/ /
 | |__| | |  | | (_| | |  | | |>  <
  \_____|_|  |_|\__,_|_|  |_|_/_/\_\


* @author Joshua Bijak
* Date:        March 12, 2019
* @notice Grid Mix API Pulling Contract
* @dev Oracle Contract that pulls grid mix data using Provable

*
*
*
  ___                            _
|_ _|_ __ ___  _ __   ___  _ __| |_ ___
 | || '_ ` _ \| '_ \ / _ \| '__| __/ __|
 | || | | | | | |_) | (_) | |  | |_\__ \
|___|_| |_| |_| .__/ \___/|_|   \__|___/
              |_|

*
*/


import "../Provable/provableAPI.sol";

import "../../node_modules/solidity-util/lib/Strings.sol";

import "../../node_modules/solidity-util/lib/Integers.sol";

import "./GridMixInterface.sol";

import "../VCUOffset/VCUOffsetInterface.sol";

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";

import "@openzeppelin/contracts-ethereum-package/contracts/GSN/GSNRecipient.sol";


contract GridMix is GridMixInterface, usingProvable, Initializable , Ownable, GSNRecipient {

    /**
     *
           _____ _       _           _
          / ____| |     | |         | |
         | |  __| | ___ | |__   __ _| |___
         | | |_ | |/ _ \| '_ \ / _` | / __|
         | |__| | | (_) | |_) | (_| | \__ \
          \_____|_|\___/|_.__/ \__,_|_|___/


    */


    using Strings for string;
    using Integers for uint;

    string public GridIntensity;
    event LogNewProvableQuery(string description);
    event newGridIntensity(string result);

    VCUOffsetInterface public genericVCUOffsetInterface;

    address private allowedGSNAddress;

    /**
     * @notice Deploys GridMix contract
     * @dev currently hardcoded API/Keys, subject to change.
     */
    //constructor()public{}


    /**
     * OZ initialize function
     */
    function initialize(address _VCUOffsetContract, address _owner, address _allowedGSNAddress) public initializer {
        GSNRecipient.initialize();
        allowedGSNAddress = _allowedGSNAddress;
        genericVCUOffsetInterface = VCUOffsetInterface(_VCUOffsetContract);
        provable_setProof(proofType_Android | proofStorage_IPFS);
        super.initialize(_owner);

    }


    /**
      *   ______                _   _
         |  ____|              | | (_)
         | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
         |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
         | |  | |_| | | | | (__| |_| | (_) | | | \__ \
         |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
     */

    function __callback(
        bytes32 _myid,
        string memory _result,
        bytes memory _proof
    )
        public
    {
        require(msg.sender == provable_cbAddress());

        GridIntensity = _result;
        emit newGridIntensity(_result);

        genericVCUOffsetInterface.continueOffset(parseInt(_result));




    }
    function updateVCUOffset (address _newVCUOffsetContract)public onlyOwner{

        genericVCUOffsetInterface = VCUOffsetInterface(_newVCUOffsetContract);
    }

    function comp_request(
        string memory _query,
        string memory _method,
        string memory _url,
        string memory _kwargs
    )
        public
        payable
    {
        if (provable_getPrice("computation") > address(this).balance) {
            emit LogNewProvableQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit LogNewProvableQuery("Oraclize query was sent, standing by for the answer...");
            provable_query("computation",
                [_query,
                _method,
                _url,
                _kwargs]
            );
        }
    }
    /**
     * @notice ASks Co2signal.com for a gridMix value of UK grid. Uses a default API Key
     * @dev This is hardcoded but subject to change
     * @param countryCode Country Code to Query GridMix
     */

    function requestCO2Signal(string memory countryCode)
        public
        payable
    {

        string memory apiURL = "https://api.co2signal.com/v1/latest?countryCode=";

        apiURL = apiURL.concat(countryCode);

        comp_request("json(QmdKK319Veha83h6AYgQqhx9YRsJ9MJE7y33oCXyZ4MqHE).data.carbonIntensity",
                "GET",
                apiURL,
                "{'headers': {'auth-token': 'aad60b7310e3211a'}}"
                );
    }
    function setGSNAllowed(address _newGSNAddress) public onlyOwner {
        allowedGSNAddress = _newGSNAddress;
    }
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
    ) external view returns (uint256, bytes memory)  {

        //emit emittedMsgSender(_msgSender());
        //emit emittedAllowedAddress(allowedAddress);
        if(from == allowedGSNAddress){
            return _approveRelayedCall();

        }
        else {
            return _rejectRelayedCall(uint256(0));
        }
    }

    function _preRelayedCall(bytes memory context) internal returns (bytes32) {

    }

    function _postRelayedCall(bytes memory context, bool, uint256 actualCharge, bytes32) internal {

    }

    function setRelayHubAddress() public {
        if(getHubAddr() == address(0)) {
            _upgradeRelayHub(0xD216153c06E857cD7f72665E0aF1d7D82172F494);
        }
    }

    function getRecipientBalance() public view returns (uint) {
        return IRelayHub(getHubAddr()).balanceOf(address(this));
    }
/**
 *
 *
 *   _                      _
    | |                    | |
    | |     ___  __ _  __ _| |
    | |    / _ \/ _` |/ _` | |
    | |___|  __/ (_| | (_| | |
    |______\___|\__, |\__,_|_|
                 __/ |
                |___/
 *
 * They come with no warranty and are not for use in a production setting. For production usage, please contact joshua.bijak@creol.io
 *
 */
}

