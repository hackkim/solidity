// src/VotingSystem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 투표 시스템 스마트 컨트랙트
contract VotingSystem {
    // 배포자 주소 (오직 제안만 가능)
    address public owner;

    // 투표 안건 구조체
    struct Proposal {
        uint256 id;            // 안건 ID
        string description;    // 안건 설명
        uint256 votesYes;      // 찬성 수
        uint256 votesNo;       // 반대 수
        uint256 createdAt;     // 생성 시간 (투표 마감 판단용)
    }

    // 유권자 여부 저장
    mapping(address => bool) public isVoter;

    // 안건 저장 (id => Proposal)
    mapping(uint256 => Proposal) public proposals;

    // 누가 어떤 안건에 투표했는지 기록 (id => (voter => true/false))
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // 안건 수 (ID 카운터)
    uint256 public proposalCount;

    // 배포자만 실행 가능한 제한자
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // 유권자만 실행 가능한 제한자
    modifier onlyVoter() {
        require(isVoter[msg.sender], "Not a voter");
        _;
    }

    // 생성자 - 배포 시 유권자 주소들 지정
    constructor(address[] memory _voters) {
        owner = msg.sender;
        for (uint i = 0; i < _voters.length; i++) {
            isVoter[_voters[i]] = true;
        }
    }

    // 안건 추가 함수 (owner만 가능)
    function addProposal(string memory _desc) public onlyOwner {
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            description: _desc,
            votesYes: 0,
            votesNo: 0,
            createdAt: block.timestamp // 현재 블록의 시간 기록
        });
        proposalCount++; // 안건 수 증가
    }

    // 투표 함수 - 찬성(true), 반대(false)
    function vote(uint256 _id, bool _support) public onlyVoter {
        require(_id < proposalCount, "Invalid proposal id");                 // 유효한 안건인지 확인
        require(!hasVoted[_id][msg.sender], "Already voted");               // 중복 투표 방지

        Proposal storage p = proposals[_id];
        require(block.timestamp < p.createdAt + 5 minutes, "Voting is closed"); // 5분 이내만 투표 가능

        if (_support) {
            p.votesYes++;
        } else {
            p.votesNo++;
        }

        hasVoted[_id][msg.sender] = true; // 투표 여부 기록
    }

    // 투표 결과 확인 함수 (5분 지나야 가능)
    function getResult(uint256 _id) public view returns (string memory result) {
        require(_id < proposalCount, "Invalid proposal id"); // 유효한 ID 확인
        Proposal storage p = proposals[_id];
        require(block.timestamp >= p.createdAt + 5 minutes, "Voting still ongoing"); // 마감 여부 확인

        if (p.votesYes > p.votesNo) {
            return "PASSED";     // 찬성 > 반대
        } else if (p.votesYes < p.votesNo) {
            return "REJECTED";   // 반대 > 찬성
        } else {
            return "TIE";        // 동점
        }
    }

    // 안건 상세 정보 조회용 함수
    function getProposal(uint256 _id) public view returns (
        string memory desc,
        uint256 yes,
        uint256 no,
        uint256 createdAt
    ) {
        Proposal memory p = proposals[_id];
        return (p.description, p.votesYes, p.votesNo, p.createdAt);
    }
}
