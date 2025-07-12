 Crowdfund-STX Smart Contract

**Crowdfund-STX** is a decentralized crowdfunding smart contract built with [Clarity](https://docs.stacks.co/write-smart-contracts/clarity-overview) for the Stacks blockchain. It enables project creators to launch funding campaigns, accept STX contributions, and automatically handle claims or refunds based on the campaign outcome.

---

 Features

-  Create crowdfunding campaigns with custom goal and deadline  
-  Accept STX contributions from multiple users  
-  Claim raised funds if funding goal is reached  
-  Refund contributors if the goal is not met  
-  View campaign and contribution details transparently

---

 Contract Functions

 Public Functions

| Function           | Description                                                                 |
|--------------------|-----------------------------------------------------------------------------|
| `create-campaign`  | Start a new campaign with goal and deadline                                 |
| `contribute`       | Contribute STX to a specific campaign                                       |
| `claim-funds`      | Campaign creator claims funds if goal is met                                |
| `get-refund`       | Contributors withdraw their STX if goal is not reached                      |

 Read-Only Functions

| Function          | Description                                           |
|-------------------|-------------------------------------------------------|
| `get-campaign`    | Returns details of a campaign by ID                   |

---

 Example Usage

```clarity
;; Create a campaign with a 100_000 uSTX goal and a 500-block deadline
(create-campaign u100000 u500)

;; Contribute 50_000 uSTX to campaign 0
(contribute u0 u50000)

;; After the deadline, if the goal is met, the creator can claim:
(claim-funds u0)

;; If not met, contributors can get a refund:
(get-refund u0)
