// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlockStreetCert is ERC1155, Ownable {

    using SafeMath for uint;

    mapping(uint => address) holders;
    
    uint nextHolder;
    string courseTitle;
    address schoolAddress;
    address tutor;

    constructor(string memory _courseTitle, address _schoolAddress, address _tutor) ERC1155(""){ 
        courseTitle = _courseTitle;
        schoolAddress = _schoolAddress;
        tutor = _tutor;
    }

    function mint(address _holder, uint256 _id, uint256 _amount, bytes memory data) external onlyOwner {
        _mint(_holder, _id, _amount, "");
    }

    function getBalanceOf(address _holder, uint256 _id) external view {
        balanceOf(_holder, _id);
    }

    function AddHolders(address _holder) external onlyOwner{
        holders[nextHolder] = _holder;
    }

    function incraseCertHolders() external onlyOwner{
        nextHolder++;
    }
}
