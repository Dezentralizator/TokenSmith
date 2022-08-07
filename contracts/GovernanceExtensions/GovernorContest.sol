// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (governance/Governor.sol)

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Timers.sol";
import "../interfaces/IGovernorContest.sol";
import "../interfaces/IERC721Version.sol";
import "../SimpleTreasury.sol";
import "../utils/ArraySlicerMemory.sol";
import "../utils/ArraySort.sol";

/**
 * @dev Core of the governance system, designed to be extended though various modules.
 *
 * This contract is abstract and requires several function to be implemented in various modules:
 *
 * - A counting module must implement {quorum}
 * - A voting module must implement {_getVotes}
 * - Additionanly, the {votingPeriod, votingDelay, registrationPeriod, registrationDelay} must also be implemented
 *
 * _Available since v4.3._
 */
abstract contract GovernorContest is Context, ERC165, EIP712, IGovernorContest {
    using SafeCast for uint256;
    using Slicer for address[];
    using Sorter for address[];
    using Timers for Timers.BlockNumber;

    bytes32 public constant CONTEST_TYPEHASH = keccak256("Contest(uint256 proposalId,uint256 value)");

    struct ContestCore {
        Timers.BlockNumber regStart;
        Timers.BlockNumber voteStart;
        Timers.BlockNumber voteEnd;
        uint256 rewardAmount;
        uint256 firstParticipant;
        bool executed;
        bool canceled;
        mapping(address => bool) hasVoted;
        mapping(address => bool) hasRegistered;

    }

    string private _name;


    ContestCore[] internal _contests;
    uint256[] public _lastEntryForContest;
    address[] listOfParticipants;
    mapping (address => string) submission;
    mapping (address => uint256) voteForSubmission;
    //uint256 registeringFee = 0;
    SimpleTreasury public immutable treasury;
    IERC721Version public immutable tokenToModify;



    /**
     * @dev Restricts a function so it can only be executed through governance proposals. For example, governance
     * parameter setters in {GovernorSettings} are protected using this modifier.
     *
     * The governance executing address may be different from the Governor's own address, for example it could be a
     * timelock. This can be customized by modules by overriding {_executor}. The executor is only able to invoke these
     * functions during the execution of the governor's {execute} function, and not under any other circumstances. Thus,
     * for example, additional timelock proposers are not able to change governance parameters without going through the
     * governance protocol (since v4.6).
     */
    modifier onlyGovernance() {
        require(_msgSender() == _executor(), "Governor: onlyGovernance");
        _;
    }

    /**
     * @dev Sets the value for {name} and {version}
     */
    constructor(string memory name_, ERC721Version _token) EIP712(name_, version()) {
        _name = name_;
        tokenToModify = _token;
        treasury = new SimpleTreasury(_token);
    }

    /**
     * @dev Function to receive ETH that will be handled by the governor (disabled if executor is a third party contract)
     In the current implementation public payable functions are preferred since Contests are limited in scope.
     This would be reactivated for more complex governance functionnalities
     */
    /*receive() external payable virtual {
        require(_executor() == address(this));
    }*/ 

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        // In addition to the current interfaceId, also support previous version of the interfaceId that did not
        // include the castVoteWithReasonAndParams() function as standard
        return
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IGovernor-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IGovernor-version}.
     */
    function version() public view virtual override returns (string memory) {
        return "1";
    }


 
    function idOfOpenContests() public view virtual override returns (uint256) {
        return _contests.length-1;
    }




    /**
    see library documentation - {ArraySlicer} */
    function currentParticipants() public view virtual override returns (address[] memory slicedParticipants) {
        return listOfParticipants.startSlicer(_contests[_contests.length-1].firstParticipant);
    }


    /**
     * @dev See {IGovernorContest-state}.
     */
    function state(uint256 contestId) public view virtual override returns (ContestState) {
        ContestCore storage contest = _contests[contestId];

        if (contest.executed) {
            return ContestState.Executed;
        } 

        if (contest.canceled) {
            return ContestState.Canceled;
        }

        uint256 registration = contestRegistration(contestId);


        if (registration == 0) {
            revert("Governor: unknown proposal id");
        }


        if (registration >= block.number) {
            return ContestState.Pending;
        }


        uint256 snapshot = contestVoting(contestId);


        if (snapshot >= block.number) {
            return ContestState.Registering;
        }

        uint256 deadline = contestDeadline(contestId);

        if (deadline >= block.number) {
            return ContestState.Voting;
        }
        
        else {
            return ContestState.Completed;
        }
    }

    /**
     * @dev See {IGovernorContest-contestRegistration}.
     */
    function contestRegistration(uint256 contestId) public view virtual override returns (uint256) {
        return _contests[contestId].regStart.getDeadline();
    }

    /**
     * @dev See {IGovernor-proposalSnapshot}.
     */
    function contestVoting(uint256 contestId) public view virtual override returns (uint256) {
        return _contests[contestId].voteStart.getDeadline();
    }

    /**
     * @dev See {IGovernor-proposalDeadline}.
     */
    function contestDeadline(uint256 contestId) public view virtual override returns (uint256) {
        return _contests[contestId].voteEnd.getDeadline();
    }

    /**
     * @dev Part of the Governor Bravo's interface: _"The number of votes required in order for a voter to become a proposer"_.
     */
    function proposalThreshold() public view virtual returns (uint256) {
        return 0;
    }

    function register(string calldata file) payable virtual override public {

        uint256 lastContestIndex = _contests.length-1;
        require(_contests[lastContestIndex].regStart.getDeadline() < block.number && _contests[lastContestIndex].voteStart.getDeadline() > block.number,"This is not the registration period");
        //require(msg.value == registeringFee, "You need to pay the registering fee" );
        if(_contests[lastContestIndex].hasRegistered[msg.sender] == false){
            listOfParticipants.push(msg.sender);
            _contests[lastContestIndex].hasRegistered[msg.sender] = true;
        }
        
        submission[msg.sender] = file;
        voteForSubmission[msg.sender] = 0;

    }


    /**
     * @dev Get the voting weight of `account` at a specific `blockNumber`, for a vote as described by `params`.
     */
    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory params
    ) internal view virtual returns (uint256);


    /**
     * @dev Default additional encoded parameters used by castVote methods that don't include them
     *
     * Note: Should be overridden by specific implementations to use an appropriate value, the
     * meaning of the additional params, in the context of that implementation
     */
    function _defaultParams() internal view virtual returns (bytes memory) {
        return "";
    }

    /**
     * @dev See {IGovernor-propose}.
     */
    function initiateContest() public virtual override returns (uint256) {

        require(
            getVotes(_msgSender(), block.number - 1) >= proposalThreshold(),
            "Governor: proposer votes below proposal threshold"
        );

        uint256 value = treasury.getBalance();


        uint256 contestId = _contests.length;

        require (state(contestId-1) == ContestState.Executed || state(contestId-1) == ContestState.Canceled, "Previous contest still on.");

        ContestCore storage contest = _contests[_contests.length];
        
        require(contest.voteStart.isUnset(), "Governor: proposal already exists");

        uint64 registrationStart = block.number.toUint64() + registeringDelay().toUint64();
        uint64 votingStart = registrationStart + registrationPeriod().toUint64();
        uint64 votingEnd = votingStart + votingPeriod().toUint64();

        contest.regStart.setDeadline(registrationStart);
        contest.voteStart.setDeadline(votingStart);
        contest.voteEnd.setDeadline(votingEnd);
        contest.firstParticipant = listOfParticipants.length;
        contest.rewardAmount = value;

        emit ContestCreated(
            contestId,
            _msgSender(),
            listOfParticipants.length,
            value,
            registrationStart,
            votingStart,
            votingEnd
        );

        return contestId;
    }

    /**
     * @dev See {IGovernor-hasVoted}.
     */
    function hasVoted(uint256 contestId, address account) public view virtual override returns (bool) {
        return _contests[contestId].hasVoted[account];
    }

    /**
     * @dev See {IGovernor-castVote}.
     */
    function castVote(address candidate) public virtual override returns (uint256) {
        address voter = _msgSender();
        uint256 contestId = _contests.length-1;
        
        ContestCore storage openContest = _contests[contestId];
        require(state(contestId) == ContestState.Voting, "Governor: vote not currently active");

        uint256 weight = getVotes(voter, openContest.voteStart.getDeadline());
        voteForSubmission[candidate] += weight;
        emit VoteCast(voter, contestId, candidate, weight);


        return weight;
    }

  



    /**
     * @dev See {IGovernor-execute}.
     */
    function execute(

    ) public payable virtual override returns (uint256) {
        uint256 contestId = _contests.length-1;

        ContestState status = state(contestId);
        require(
            status == ContestState.Completed ,
            "Governor: There are no completed contests to execute."
        );

        address[] memory _contestants = currentParticipants();

        address[] memory _winners = findWinners(_contestants);

        if(_winners.length == 0){
            _contests[contestId].canceled = true;
            emit ContestCanceled(contestId);
        } else {

            _contests[contestId].executed = true;

        emit ContestExecuted(contestId);

        _winners.sort(voteForSubmission);
        uint256[] memory rewards = _calculateRewards(_winners.length);

        _execute( _winners, rewards);
 

        }

        return contestId;
    }

    /**
     * @dev Internal execution mechanism. Can be overridden to implement different execution mechanism
     */
    function _execute(
        address[] memory winners,
        uint256[] memory reward
        
    ) internal virtual {
        
        //string memory errorMessage = "Governor: call reverted without message";
        uint256 denomIndex = winners.length;
        for (uint256 i = 0; i < denomIndex; ++i) {
        
            tokenToModify.addNewFile(submission[winners[i]]);
            treasury.sendETH(payable(winners[i]), reward[i]*_contests[_contests.length-1].rewardAmount/reward[denomIndex]);
            /** 
            (bool success, bytes memory returndata) = rewardDistributor.call(abi.encodeWithSignature("sendETH(address,uint256)", winners[i], reward[i]*_contests[_contests.length-1].rewardAmount/reward[denomIndex]));
            Address.verifyCallResult(success, returndata, errorMessage);
            */

        }
    }


    /**
     * @dev See {IGovernor-getVotes}.
     */
    function getVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        return _getVotes(account, blockNumber, _defaultParams());
    }


    function findWinners(address[] memory _validParticipants) public view returns (address[] memory winners){

        uint256 submissions = _validParticipants.length;
        uint256 minVoteToWin = quorum(contestVoting(_contests.length-1));
        uint256 counter;
        for (uint i=0;i<submissions;++i){
            if (voteForSubmission[_validParticipants[i]]> minVoteToWin){
               counter++;
            }

        }

        address[] memory _winners = new address[](counter);


        if (counter == 0) {

            return _winners;
        } 

        for (uint i=0;i<submissions;++i){
            if (voteForSubmission[_validParticipants[i]]> minVoteToWin){
                counter--;
                _winners[counter] = _validParticipants[i];
            }
        }
        return _winners;
    }

    /*returns the denominator showing the value of the array*/// @title A title that should describe the contract/interface
    /// @notice Calculates the rewards for the for a contest.
    /// @dev The rewards are stored as decreasing NUMERATORS according to the final ranking. 
    /// The last value of the reward array is the common denominator to allow to calculate on percentage basis.

    function _calculateRewards(uint256 amountOfWinners) private pure returns (uint256[] memory){
        uint256[] memory totalAwards = new uint256[](amountOfWinners+1);
        for (uint i=0; i< amountOfWinners ; ++i){
            totalAwards[i]=2*(amountOfWinners-i) ; 
        }

        //denominator is stored after numerators in array
        totalAwards[amountOfWinners]= 4 + amountOfWinners*(amountOfWinners+1);
        return totalAwards;
    }

    /**
     * @dev Address through which the governor executes action. Will be overloaded by module that execute actions
     * through another contract such as a timelock.
     */
    function _executor() internal view virtual returns (address) {
        return address(this);
    }


}
