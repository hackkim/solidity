// src/MultisigWallet.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ECDSA 기반 다중 서명 월렛
contract MultisigWallet {
    address public owner; // 컨트랙트 배포자 (안건 추가 권한자)
    mapping(address => bool) public isVoter; // 투표 가능 주소들
    uint public proposalCount; // 안건 ID 카운터

    // 안건 정보 구조체
    struct Proposal {
        uint id;
        address to;           // 실행 대상 주소
        uint256 value;        // 보낼 ETH 값
        bytes data;           // 실행할 함수 호출 데이터
        uint256 yesVotes;     // 찬성 수
        uint256 noVotes;      // 반대 수
        bool executed;        // 실행 여부
    }

    mapping(uint => Proposal) public proposals; // id => Proposal
    mapping(uint => mapping(address => bool)) public hasSigned; // 중복 투표 방지

    // 오너만 실행 가능한 함수 제한자
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // 생성자 - 유권자 설정
    constructor(address[] memory _voters) {
        owner = msg.sender;
        for (uint i = 0; i < _voters.length; i++) {
            isVoter[_voters[i]] = true;
        }
    }

    // 안건 추가 (오직 오너만 가능)
    function addProposal(address to, uint256 value, bytes calldata data) external onlyOwner {
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            to: to,
            value: value,
            data: data,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        proposalCount++;
    }

    // 투표 함수 - 서명을 기반으로 투표함
    function vote(uint id, bool support, bytes calldata signature) external {
        require(isVoter[msg.sender], "Not a voter");                 // 유권자만 가능
        require(!hasSigned[id][msg.sender], "Already voted");        // 중복 투표 방지

        Proposal storage p = proposals[id];
        require(!p.executed, "Already executed");                    // 이미 실행된 안건은 투표 불가

        // 서명 검증을 위한 digest 생성 (정해진 포맷)
        bytes32 digest = keccak256(abi.encodePacked(id, p.to, p.value, p.data));

        // 서명을 통해 msg.sender가 직접 서명했는지 확인
        address signer = recover(digest, signature);
        require(signer == msg.sender, "Invalid signature");

        // 투표 처리
        hasSigned[id][msg.sender] = true;
        if (support) {
            p.yesVotes++;
        } else {
            p.noVotes++;
        }
    }

    // 실행 함수 - 찬성이 더 많을 경우 트랜잭션 실행
    function execute(uint id) external {
        Proposal storage p = proposals[id];
        require(!p.executed, "Already executed");
        require(p.yesVotes > p.noVotes, "Not enough approval");

        p.executed = true;

        // 실제 트랜잭션 실행 (ETH 전송 또는 함수 호출)
        (bool success, ) = p.to.call{value: p.value}(p.data);
        require(success, "Execution failed");
    }

    // ECDSA 서명을 통해 signer 주소 복원
    function recover(bytes32 digest, bytes memory sig) public pure returns (address) {
        // 이더리움 서명 포맷 적용 (prefix 붙이기)
        bytes32 ethSigned = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", digest));
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(sig);
        return ecrecover(ethSigned, v, r, s);
    }

    // signature를 r, s, v로 분리
    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    // 컨트랙트로 ETH 입금 받기용
    receive() external payable {}
}
