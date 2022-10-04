// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract Linker is Ownable, ERC2771Context {
    address private approvedSigner;
    mapping(address => mapping(uint16 => string)) uuidByPlatformByPlayer;
    mapping(uint16 => mapping(string => address)) walletByUuidByPlatform;

    /**
    * Events
    */

    event PlayerLinked(uint16 _platform, string _uuid, address _address);

    constructor(address _forwarder) ERC2771Context(_forwarder) {
        approvedSigner = _msgSender();
    }

    /**
     * Reads
     */

    function getAddressByUuidByPlatform(string calldata _uuid, uint16 _platform) external view returns (address) {
        string memory lowercaseUuid = _stringToLower(_uuid);
        return walletByUuidByPlatform[_platform][lowercaseUuid];
    }

    function getUuidByPlatformByPlayer(address _address, uint16 _platform) external view returns (string) {
        return uuidByPlatformByPlayer[_address][_platform];
    }

    /**
    * Writes
    */

    function linkPlayerToUuidByPlatform(string calldata _uuid, uint16 _platform, bytes calldata _signature) public {
        string memory lowercaseUuid = _stringToLower(_uuid);
        require(_verifyPrimarySignerSignature(keccak256(abi.encode(_msgSender(), lowercaseUuid, _platform)), _signature), "Invalid Approval Signature");
        
        uuidByPlatformByPlayer[_msgSender()][_platform] = lowercaseUuid;
        walletByUuidByPlatform[_platform][lowercaseUuid] = _msgSender();

        emit PlayerLinked(_platform, lowercaseUuid, _msgSender());
    }

    /**
    * Overrides
    */

    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return super._msgData();
    }

    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address)
    {
        return super._msgSender();
    }

    /**
     * Utils
     */

    function _stringToLower(string memory _base)
        internal
        pure
        returns (string memory)
    {
        bytes memory _baseBytes = bytes(_base);

        for (uint256 i = 0; i < _baseBytes.length; i++) {
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

    function _verifyPrimarySignerSignature(
        bytes32 hash,
        bytes calldata signature
    ) internal view returns (bool) {
        return
            hash.toEthSignedMessageHash().recover(signature) == approvedSigner;
    }
}
