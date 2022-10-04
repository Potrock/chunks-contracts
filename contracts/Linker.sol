// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

//NEED ERC2771CONTEXT IMPLEMENTATION!
contract Linker is Ownable {
    using ECDSA for bytes32;

    address public approvedSigner;
    mapping(address => mapping(string => string)) uuidByPlatformByPlayer;
    mapping(string => mapping(string => address)) walletByUuidByPlatform;
    mapping (address => bytes32) public addressToKeccak;

    /**
    * Events
    */

    event PlayerLinked(string _platform, string _uuid, address _address);

    constructor()  {
        approvedSigner = msg.sender;
    }

    /**
     * Reads
     */

    function getAddressByUuidByPlatform(string calldata _uuid, string calldata _platform) external view returns (address) {
        string memory lowercaseUuid = _stringToLower(_uuid);
        return walletByUuidByPlatform[_platform][lowercaseUuid];
    }

    function getUuidByPlatformByPlayer(address _address, string calldata _platform) external view returns (string memory) {
        return uuidByPlatformByPlayer[_address][_platform];
    }

    /**
    * Writes
    */

    function linkPlayerToUuidByPlatform(string calldata _uuid, string calldata _platform, bytes calldata _signature) public {
        string memory lowercaseUuid = _stringToLower(_uuid);
        require(_verifyApprovedSigner(keccak256(abi.encode(msg.sender, lowercaseUuid, _platform)), _signature), "Invalid Approval Signature");
        
        uuidByPlatformByPlayer[msg.sender][_platform] = lowercaseUuid;
        walletByUuidByPlatform[_platform][lowercaseUuid] = msg.sender;

        emit PlayerLinked(_platform, lowercaseUuid, msg.sender);
    }

    function getEncodeParameters(string calldata _uuid, string calldata _platform) external view returns (bytes memory) {
        return abi.encode(msg.sender, _uuid, _platform);
    }
    function testSig(string calldata _uuid, string calldata _platform) public {
        bytes32 keccak = keccak256(abi.encode(msg.sender, _stringToLower(_uuid), _platform));
        addressToKeccak[msg.sender] = keccak;
    }

    /**
    * Overrides
    */

    // function _msgData()
    //     internal
    //     view
    //     override(Context, ERC2771Context)
    //     returns (bytes calldata)
    // {
    //     return super._msgData();
    // }

    // function msg.sender
    //     internal
    //     view
    //     override(Context, ERC2771Context)
    //     returns (address)
    // {
    //     return super.msg.sender;
    // }

    /**
     * Utils
     */

    function _stringToLower(string memory _base)
        internal
        pure
        returns (string memory)
    {
        bytes memory _baseBytes = bytes(_base);

        for (uint16 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = (_baseBytes[i] >= 0x41 && _baseBytes[i] <= 0x5A)
                ? bytes1(uint8(_baseBytes[i]) + 32)
                : _baseBytes[i];
        }

        return string(_baseBytes);
    }

    /**
     * Owner only
     */

    function setPrimarySigner(address _approvedSigner) external onlyOwner {
        require(approvedSigner != address(0), "Zero address");
        approvedSigner = _approvedSigner;
    }

    /**
     * Security
     */

    function _verifyApprovedSigner(
        bytes32 hash,
        bytes calldata signature
    ) internal view returns (bool) {
        return
            hash.toEthSignedMessageHash().recover(signature) == approvedSigner;
    }
}
