
;; title: PolicyEdu
;; version: 1.0.0
;; summary: Educational Policy Voting System
;; description: A smart contract for democratic decision-making on educational policies

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_PROPOSAL (err u101))
(define-constant ERR_ALREADY_VOTED (err u102))
(define-constant ERR_VOTING_CLOSED (err u103))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u104))
(define-constant ERR_INSUFFICIENT_WEIGHT (err u105))

;; Voting periods (in blocks)
(define-constant VOTING_PERIOD u1008) ;; ~1 week at 10 min blocks
(define-constant MIN_VOTING_WEIGHT u1)

;; data vars
(define-data-var proposal-counter uint u0)
(define-data-var contract-active bool true)

;; data maps
;; Store proposal details
(define-map proposals
  uint
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    proposer: principal,
    start-block: uint,
    end-block: uint,
    votes-for: uint,
    votes-against: uint,
    executed: bool,
    category: (string-ascii 50)
  }
)

;; Track user votes per proposal
(define-map user-votes
  {proposal-id: uint, voter: principal}
  {vote: bool, weight: uint}
)

;; Authorized voters with their voting weights
(define-map voter-registry
  principal
  {weight: uint, active: bool, role: (string-ascii 50)}
)

;; public functions

;; Initialize contract with owner as admin
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set voter-registry CONTRACT_OWNER {weight: u10, active: true, role: "admin"})
    (ok true)
  )
)

;; Add or update voter registration
(define-public (register-voter (voter principal) (weight uint) (role (string-ascii 50)))
  (begin
    (asserts! (get-contract-active) ERR_UNAUTHORIZED)
    (asserts! (is-admin tx-sender) ERR_UNAUTHORIZED)
    (asserts! (>= weight MIN_VOTING_WEIGHT) ERR_INSUFFICIENT_WEIGHT)
    (ok (map-set voter-registry voter {weight: weight, active: true, role: role}))
  )
)

;; Deactivate a voter
(define-public (deactivate-voter (voter principal))
  (begin
    (asserts! (get-contract-active) ERR_UNAUTHORIZED)
    (asserts! (is-admin tx-sender) ERR_UNAUTHORIZED)
    (match (map-get? voter-registry voter)
      voter-data (ok (map-set voter-registry voter (merge voter-data {active: false})))
      ERR_INVALID_PROPOSAL
    )
  )
)

;; Create a new policy proposal
(define-public (create-proposal
  (title (string-ascii 100))
  (description (string-ascii 500))
  (category (string-ascii 50))
)
  (let
    (
      (proposal-id (+ (var-get proposal-counter) u1))
      (start-block block-height)
      (end-block (+ block-height VOTING_PERIOD))
    )
    (asserts! (get-contract-active) ERR_UNAUTHORIZED)
    (asserts! (is-authorized-voter tx-sender) ERR_UNAUTHORIZED)
    (map-set proposals proposal-id {
      title: title,
      description: description,
      proposer: tx-sender,
      start-block: start-block,
      end-block: end-block,
      votes-for: u0,
      votes-against: u0,
      executed: false,
      category: category
    })
    (var-set proposal-counter proposal-id)
    (ok proposal-id)
  )
)

;; Vote on a proposal
(define-public (vote (proposal-id uint) (vote-for bool))
  (let
    (
      (voter-data (unwrap! (map-get? voter-registry tx-sender) ERR_UNAUTHORIZED))
      (proposal-data (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
      (voter-weight (get weight voter-data))
    )
    (asserts! (get-contract-active) ERR_UNAUTHORIZED)
    (asserts! (get active voter-data) ERR_UNAUTHORIZED)
    (asserts! (<= block-height (get end-block proposal-data)) ERR_VOTING_CLOSED)
    (asserts! (is-none (map-get? user-votes {proposal-id: proposal-id, voter: tx-sender})) ERR_ALREADY_VOTED)

    ;; Record the vote
    (map-set user-votes
      {proposal-id: proposal-id, voter: tx-sender}
      {vote: vote-for, weight: voter-weight}
    )

    ;; Update proposal vote counts
    (if vote-for
      (map-set proposals proposal-id
        (merge proposal-data {votes-for: (+ (get votes-for proposal-data) voter-weight)})
      )
      (map-set proposals proposal-id
        (merge proposal-data {votes-against: (+ (get votes-against proposal-data) voter-weight)})
      )
    )
    (ok true)
  )
)

;; Execute a proposal (mark as executed)
(define-public (execute-proposal (proposal-id uint))
  (let
    (
      (proposal-data (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
    )
    (asserts! (get-contract-active) ERR_UNAUTHORIZED)
    (asserts! (is-admin tx-sender) ERR_UNAUTHORIZED)
    (asserts! (> block-height (get end-block proposal-data)) ERR_VOTING_CLOSED)
    (asserts! (not (get executed proposal-data)) ERR_INVALID_PROPOSAL)
    (asserts! (> (get votes-for proposal-data) (get votes-against proposal-data)) ERR_INVALID_PROPOSAL)

    (ok (map-set proposals proposal-id (merge proposal-data {executed: true})))
  )
)

;; Admin function to pause/unpause contract
(define-public (set-contract-active (active bool))
  (begin
    (asserts! (is-admin tx-sender) ERR_UNAUTHORIZED)
    (ok (var-set contract-active active))
  )
)

;; read only functions

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

;; Get voter information
(define-read-only (get-voter-info (voter principal))
  (map-get? voter-registry voter)
)

;; Get user's vote on a specific proposal
(define-read-only (get-user-vote (proposal-id uint) (voter principal))
  (map-get? user-votes {proposal-id: proposal-id, voter: voter})
)

;; Get current proposal counter
(define-read-only (get-proposal-counter)
  (var-get proposal-counter)
)

;; Check if contract is active
(define-read-only (get-contract-active)
  (var-get contract-active)
)

;; Check if address is admin
(define-read-only (is-admin (address principal))
  (match (map-get? voter-registry address)
    voter-data (is-eq (get role voter-data) "admin")
    false
  )
)

;; Check if address is authorized voter
(define-read-only (is-authorized-voter (address principal))
  (match (map-get? voter-registry address)
    voter-data (get active voter-data)
    false
  )
)

;; Get proposal results
(define-read-only (get-proposal-results (proposal-id uint))
  (match (map-get? proposals proposal-id)
    proposal-data
    (some {
      proposal-id: proposal-id,
      title: (get title proposal-data),
      votes-for: (get votes-for proposal-data),
      votes-against: (get votes-against proposal-data),
      total-votes: (+ (get votes-for proposal-data) (get votes-against proposal-data)),
      passed: (> (get votes-for proposal-data) (get votes-against proposal-data)),
      executed: (get executed proposal-data),
      voting-ended: (> block-height (get end-block proposal-data))
    })
    none
  )
)

;; Check if voting is active for a proposal
(define-read-only (is-voting-active (proposal-id uint))
  (match (map-get? proposals proposal-id)
    proposal-data
    (and
      (<= (get start-block proposal-data) block-height)
      (>= (get end-block proposal-data) block-height)
    )
    false
  )
)

;; private functions
;;
