// src/PiggyBank.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 개인별 이더리움 저금통 컨트랙트
contract PiggyBank {
    // 각 사용자(address)의 입금 잔액을 저장하는 매핑
    mapping(address => uint256) private deposits;

    // 이더리움(ETH)을 받을 수 있게 하는 함수
    // 사용자가 이 컨트랙트에 직접 ETH를 보내면 실행됨
    receive() external payable {
        deposits[msg.sender] += msg.value; // 입금 금액만큼 사용자 잔액 증가
    }

    // 출금 함수: 본인이 입금한 금액만 출금 가능
    function withdraw(uint256 amount) public {
        require(deposits[msg.sender] >= amount, "Not enough balance"); // 출금 가능 여부 확인
        deposits[msg.sender] -= amount; // 출금한 만큼 잔액 감소
        payable(msg.sender).transfer(amount); // 요청한 금액을 본인에게 전송
    }

    // 사용자 본인의 입금 잔액 확인 함수
    function myBalance() public view returns (uint256) {
        return deposits[msg.sender];
    }

    // 컨트랙트 전체에 쌓인 이더의 총액 확인
    // (모든 사용자의 입금 ETH 총합)
    function totalBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
