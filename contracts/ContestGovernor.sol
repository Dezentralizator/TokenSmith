// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./GovernanceExtensions/GovernorContest.sol";
import "./GovernanceExtensions/GovernorVotes.sol";
import "./GovernanceExtensions/GovernorVotesQuorumFraction.sol";
import "./ERC721Version.sol";

contract ContestGovernor is GovernorContest, GovernorVotes, GovernorVotesQuorumFraction{
    constructor(ERC721Version _token)
        GovernorContest("GovernorCore", _token)
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
    {}

    function votingDelay() public pure returns (uint256) {
        return 1; // 1 block
    }

    function votingPeriod() public pure override returns (uint256) {
        return 45818; // 1 week
    }

    /**
     @dev Time, in number of blocks, before launch of registration period.
     */


    function registeringDelay() public view virtual override returns (uint256){
        return 1;
    }

    /**
     @dev Time, in number of blocks, for the participants to register with their desired file.
     */

    function registrationPeriod() public view virtual override returns (uint256){
        return 45818;
    }


    // The following functions are overrides required by Solidity.

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernorContest, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(GovernorContest)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
