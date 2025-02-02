// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

import "./../SkyhuntersAccessControls.sol";
import "./../SkyhuntersLibrary.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SpectatorRewards {
    SkyhuntersAccessControls public accessControls;
    address[] private _erc20s;
    address[] private _erc721s;

    mapping(address => SkyhuntersLibrary.Spectator[]) private _spectators;
    mapping(address => uint256) private _thresholdERC20;
    mapping(address => uint256) private _thresholdERC721;

    event Spectated(string data, address spectator, uint256 count);

    modifier onlyAdmin() {
        if (!accessControls.isAdmin(msg.sender)) {
            revert SkyhuntersErrors.NotAdmin();
        }
        _;
    }

    modifier onlyHolder() {
        if (!_isHolder()) {
            revert SkyhuntersErrors.NeedTokens();
        }
        _;
    }

    constructor(address _accessControls) {
        accessControls = SkyhuntersAccessControls(_accessControls);
    }

    function spectate(string memory data) public onlyAdmin {
        _spectators[msg.sender].push(
            SkyhuntersLibrary.Spectator({
                blocktimestamp: block.timestamp,
                data: data
            })
        );

        emit Spectated(data, msg.sender, _spectators[msg.sender].length);
    }

    function _isHolder() internal view returns (bool) {
        bool _holder = false;

        for (uint8 i = 0; i < _erc20s.length; i++) {
            if (
                IERC20(_erc20s[i]).balanceOf(msg.sender) >=
                _thresholdERC20[_erc20s[i]]
            ) {
                _holder = true;

                break;
            }
        }

        if (!_holder) {
            for (uint8 i = 0; i < _erc721s.length; i++) {
                if (
                    IERC721(_erc721s[i]).balanceOf(msg.sender) >=
                    _thresholdERC721[_erc721s[i]]
                ) {
                    _holder = true;

                    break;
                }
            }
        }

        return _holder;
    }

    function getSpectatorCount(
        address spectator
    ) public view returns (uint256) {
        return _spectators[spectator].length;
    }

    function getSpectatorTimestamp(
        address spectator,
        uint256 count
    ) public view returns (uint256) {
        return _spectators[spectator][count].blocktimestamp;
    }

    function getSpectatorData(
        address spectator,
        uint256 count
    ) public view returns (string memory) {
        return _spectators[spectator][count].data;
    }

    function getERC20s() public view returns (address[] memory) {
        return _erc20s;
    }

    function getERC721s() public view returns (address[] memory) {
        return _erc721s;
    }

    function getERC20Threshold(address erc20) public view returns (uint256) {
        return _thresholdERC20[erc20];
    }

    function getERC721Threshold(address erc721) public view returns (uint256) {
        return _thresholdERC721[erc721];
    }

    function setAccessControls(address _accessControls) public onlyAdmin {
        accessControls = SkyhuntersAccessControls(_accessControls);
    }

    function setERC20s(address[] memory erc20s) public onlyAdmin {
        _erc20s = erc20s;
    }

    function setERC721s(address[] memory erc721s) public onlyAdmin {
        _erc721s = erc721s;
    }

    function setThresholdERC20(
        address erc20,
        uint256 threshold
    ) public onlyAdmin {
        _thresholdERC20[erc20] = threshold;
    }

    function setThresholdERC721(
        address erc721,
        uint256 threshold
    ) public onlyAdmin {
        _thresholdERC721[erc721] = threshold;
    }
}
