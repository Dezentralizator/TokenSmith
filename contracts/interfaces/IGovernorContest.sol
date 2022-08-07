// SPDX-License-Identifier: MIT
// Inspired from OpenZeppelin Contracts (last updated v4.7.0) (governance/IGovernor.sol)
// GovernorContest is a system to orgnaize recurrent Contest by Lorenz Schmidlin

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Interface of the {Governor} core.
 *
 * _Available since v4.3._
 */
abstract contract IGovernorContest is IERC165 {
    enum ContestState {
        Pending,
        Registering,
        Canceled,
        Voting,
        Completed,
        Executed
    }

    /**
     * @dev Emitted when a proposal is created.
     */
    event ContestCreated(
        uint256 contestId,
        address proposer,
        uint256 target,
        uint256 value,
        uint256 startBlock,
        uint256 registrationEndBlock,
        uint256 endBlock
    );

    /**
     * @dev Emitted when a proposal is canceled.
     */
    event ContestCanceled(uint256 contestId);

    /**
     * @dev Emitted when a proposal is executed.
     */
    event ContestExecuted(uint256 contestId);

    /**
     * @dev Emitted when a vote is cast.
     *
     * Note: In this implementation the vote is for a candidate through it's address.
     */
    event VoteCast(address indexed voter, uint256 proposalId, address candidate, uint256 weight);


    /**
     * @notice module:core
     * @dev Name of the governor instance (used in building the ERC712 domain separator).
     */
    function name() public view virtual returns (string memory);

    /**
     * @notice module:contestCore
     * @dev Version of the governor instance (used in building the ERC712 domain separator). Default: "1"
     */
    function version() public view virtual returns (string memory);

    /**
    @notice module:contestCore-LorenzSchmidlin
    @dev Id of the open contest */
    function idOfOpenContests() public view virtual returns (uint256);

    /**
    @notice module:contestCore-LorenzSchmidlin
    @dev Returns the slice of the participants array representing the current open contests 
    */
    function currentParticipants() public view virtual returns (address[] memory slicedParticipants);
    

  
    /**
     * @notice module:contestCore-LorenzSchmidlin
     * @dev Current state of a proposal, following Compound's convention
     */
    function state(uint256 contestId) public view virtual returns (ContestState);

    /**
     * @notice module:contest-LorenzSchmidlin
     * @dev Block number used to retrieve user's registrations for contest. Vote will be executed with ERC721Votes. Hence, voting for this proposal starts at the
     * beginning of the following block.
     */
    function contestRegistration(uint256 contestId) public view virtual returns (uint256);

    /**
     * @notice module:contest-LorenzSchmidlin
     * @dev Block number used to retrieve user's votes and quorum. Vote will be executed with ERC721Votes. Hence, voting for this proposal starts at the
     * beginning of the following block.
     */
    function contestVoting(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:contest-LorenzSchmidlin
     * @dev Block number at which votes close. Votes close at the end of this block, so it is possible to cast a vote
     * during this block.
     */
    function contestDeadline(uint256 proposalId) public view virtual returns (uint256);

    /**
    @notice module:contestCore-LorenzSchmidlin
    This function will start a contest by passing in the value of the reward pool.
    It should be called by the treasury controller. */
    function initiateContest() public virtual returns (uint256) ;

    /**
    @notice module:contestCore-LorenzSchmidlin
    @dev Allows participants to register to the contest. 

    Note : Maybe add an event?
    */
    function register(string calldata file) payable virtual public;

    /**
     * @notice module:contest-config
     * @dev Delay, in number of block, between the contest is created and the registration starts. This can be increased for various reasons such as : leave time for users to buy voting power, or delegate it, or communicate interests about the reward pool around before the voting of a proposal starts.
     */
    function registeringDelay() public view virtual returns (uint256);

    /**
     @notice module:contest-config
     @dev Time, in number of blocks, for the participants to register with their desired file.
     */

    function registrationPeriod() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of blocks, between the vote start and vote ends.
     *
     * NOTE: The {registeringDelay and registeringPeriod} can delay the start of the vote. This must be considered when setting the voting
     * duration compared to the voting delay.
     */
    function votingPeriod() public pure virtual returns (uint256);



    /**
     * @notice module:user-config
     * @dev Minimum number of cast voted required for a proposal to be successful.
     *
     * Note: The `blockNumber` parameter corresponds to the snapshot used for counting vote. This allows to scale the
     * quorum depending on values such as the totalSupply of a token at this block (see {ERC20Votes}).
     */
    function quorum(uint256 blockNumber) public view virtual returns (uint256);

    /**
     * @notice module:reputation
     * @dev Voting power of an `account` at a specific `blockNumber`.
     *
     * Note: this can be implemented in a number of ways, for example by reading the delegated balance from one (or
     * multiple), {ERC20Votes} tokens.
     */
    function getVotes(address account, uint256 blockNumber) public view virtual returns (uint256);

    /**
     * @notice module:voting
     * @dev Returns weither `account` has cast a vote on `proposalId`.
     */
    function hasVoted(uint256 contestId, address account) public view virtual returns (bool);

    /**
     * @dev Execute the contest at completion of voting period. Triggers rewarding from treasury of winners and set state of contest to executed or canceled if no one succeeded to reach the sufficient quorum.
     *
     * Emits a {ContestExecuted} event.
     *
     * Note: some module can modify the requirements for execution, for example by adding an additional timelock.
     */
    function execute() public payable virtual returns (uint256 contestId);

    /**
     * @dev Cast a vote
     *
     * Emits a {VoteCast} event.
     */
    function castVote(address participant) public virtual returns (uint256 balance);
}


