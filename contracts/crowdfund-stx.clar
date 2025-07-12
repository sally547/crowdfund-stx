;; Crowdfunding Smart Contract

;; Error constants
(define-constant ERR_INVALID_AMOUNT u100)
(define-constant ERR_DEADLINE_PASSED u101)
(define-constant ERR_NOT_OWNER u102)
(define-constant ERR_GOAL_NOT_MET u103)
(define-constant ERR_DEADLINE_NOT_REACHED u104)
(define-constant ERR_ALREADY_WITHDRAWN u105)
(define-constant ERR_NO_CONTRIBUTION u106)
(define-constant ERR_GOAL_ALREADY_MET u107)
(define-constant ERR_DEADLINE_NOT_PASSED u108)
(define-constant ERR_TRANSFER_FAILED u109)

;; Contract data
(define-data-var project-owner principal tx-sender)
(define-data-var funding-goal uint u10000000) ;; 10 STX in microSTX
(define-data-var deadline uint (+ stacks-block-height u144)) ;; ~1 day assuming 10min blocks
(define-data-var total-raised uint u0)
(define-data-var is-withdrawn bool false)

;; Map to track contributions
(define-map contributions  
  { contributor: principal }  
  { amount: uint })

;; Contribute to the campaign
(define-public (contribute (amount uint))
  (begin
    (asserts! (> amount u0) (err ERR_INVALID_AMOUNT))
    (asserts! (< stacks-block-height (var-get deadline)) (err ERR_DEADLINE_PASSED))
    
    ;; Transfer STX from contributor to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (let ((prev (default-to u0 (get amount (map-get? contributions { contributor: tx-sender })))))
      (map-set contributions { contributor: tx-sender }
        { amount: (+ prev amount) })
      (var-set total-raised (+ (var-get total-raised) amount))
      (ok { contributed: amount, total: (var-get total-raised) })
    )
  ))

;; Withdraw funds if funding goal met and deadline passed
(define-public (withdraw)
  (begin
    (asserts! (is-eq tx-sender (var-get project-owner)) (err ERR_NOT_OWNER))
    (asserts! (>= (var-get total-raised) (var-get funding-goal)) (err ERR_GOAL_NOT_MET))
    (asserts! (>= stacks-block-height (var-get deadline)) (err ERR_DEADLINE_NOT_REACHED))
    (asserts! (is-eq (var-get is-withdrawn) false) (err ERR_ALREADY_WITHDRAWN))
    
    (var-set is-withdrawn true)
    (try! (as-contract (stx-transfer? (var-get total-raised) tx-sender (var-get project-owner))))
    (ok "Funds withdrawn successfully")
  ))

;; Refund if funding failed
(define-public (refund)
  (let ((contribution (unwrap! (map-get? contributions { contributor: tx-sender }) (err ERR_NO_CONTRIBUTION))))
    (begin
      (asserts! (< (var-get total-raised) (var-get funding-goal)) (err ERR_GOAL_ALREADY_MET))
      (asserts! (>= stacks-block-height (var-get deadline)) (err ERR_DEADLINE_NOT_PASSED))
      
      (map-delete contributions { contributor: tx-sender })
      (var-set total-raised (- (var-get total-raised) (get amount contribution)))
      (try! (as-contract (stx-transfer? (get amount contribution) tx-sender tx-sender)))
      (ok { refunded: (get amount contribution) })
    )))

;; Emergency refund for owner (if needed)
(define-public (emergency-refund (contributor principal))
  (let ((contribution (unwrap! (map-get? contributions { contributor: contributor }) (err ERR_NO_CONTRIBUTION))))
    (begin
      (asserts! (is-eq tx-sender (var-get project-owner)) (err ERR_NOT_OWNER))
      
      (map-delete contributions { contributor: contributor })
      (var-set total-raised (- (var-get total-raised) (get amount contribution)))
      (try! (as-contract (stx-transfer? (get amount contribution) tx-sender contributor)))
      (ok { refunded: (get amount contribution), to: contributor })
    )))

;; View a user's contribution
(define-read-only (get-contribution (user principal))
  (map-get? contributions { contributor: user }))

;; Get campaign summary
(define-read-only (campaign-info)
  (ok {
    owner: (var-get project-owner),
    goal: (var-get funding-goal),
    deadline: (var-get deadline),
    raised: (var-get total-raised),
    withdrawn: (var-get is-withdrawn),
    current-block: stacks-block-height,
    is-active: (< stacks-block-height (var-get deadline)),
    goal-met: (>= (var-get total-raised) (var-get funding-goal))
  }))

;; Check if campaign is successful
(define-read-only (is-successful)
  (and 
    (>= (var-get total-raised) (var-get funding-goal))
    (>= stacks-block-height (var-get deadline))))

;; Check if campaign failed
(define-read-only (is-failed)
  (and 
    (< (var-get total-raised) (var-get funding-goal))
    (>= stacks-block-height (var-get deadline))))

;; Get total number of contributors
(define-read-only (get-contributor-count)
  ;; Note: This is a simplified version. In a real implementation,
  ;; you might want to maintain a separate counter for efficiency
  (var-get total-raised)) ;; Placeholder - would need iteration in full implementation

;; Update campaign parameters (only owner, before deadline)
(define-public (update-goal (new-goal uint))
  (begin
    (asserts! (is-eq tx-sender (var-get project-owner)) (err ERR_NOT_OWNER))
    (asserts! (< stacks-block-height (var-get deadline)) (err ERR_DEADLINE_PASSED))
    (asserts! (> new-goal u0) (err ERR_INVALID_AMOUNT))
    
    (var-set funding-goal new-goal)
    (ok { new-goal: new-goal })
  ))

(define-public (extend-deadline (additional-blocks uint))
  (begin
    (asserts! (is-eq tx-sender (var-get project-owner)) (err ERR_NOT_OWNER))
    (asserts! (< stacks-block-height (var-get deadline)) (err ERR_DEADLINE_PASSED))
    (asserts! (> additional-blocks u0) (err ERR_INVALID_AMOUNT))
    
    (let ((new-deadline (+ (var-get deadline) additional-blocks)))
      (var-set deadline new-deadline)
      (ok { new-deadline: new-deadline })
    )
  ))
