;; ===================================================
;; Daily Check-in Rewards Contract with Token Minting
;; ===================================================

;; Define the token (SIP-010 compliant)
(define-fungible-token checkin-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant reward-amount u100) ;; Reward per check-in in tokens
(define-constant blocks-per-day u144) ;; ~10 min per block => 144 blocks/day

;; Error codes
(define-constant err-owner-only (err u100))
(define-constant err-already-checked-in (err u101))

;; Last check-in tracking (stores "day number" for each user)
(define-map last-checkin principal uint)

;; Token supply tracking
(define-data-var total-supply uint u0)

;; ---------------------------------------------
;; Function 1: Initialize token supply (owner)
;; ---------------------------------------------
(define-public (initialize (initial-supply uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (try! (ft-mint? checkin-token initial-supply tx-sender))
    (var-set total-supply initial-supply)
    (ok {status: "Token Initialized", supply: initial-supply})
  )
)

;; ---------------------------------------------
;; Function 2: Daily check-in & reward
;; ---------------------------------------------
(define-public (daily-checkin)
  (let (
        (last (default-to u0 (map-get? last-checkin tx-sender)))
        (today (/ block-height blocks-per-day))
       )

    ;; Check if already checked in today
    (asserts! (> today last) err-already-checked-in)

    ;; Update check-in date
    (map-set last-checkin tx-sender today)

    ;; Mint reward tokens for the user
    (try! (ft-mint? checkin-token reward-amount tx-sender))
    (var-set total-supply (+ (var-get total-supply) reward-amount))

    (ok {status: "Checked in", reward: reward-amount, day: today})
  )
)

;; ---------------------------------------------
;; View: Get last check-in date
;; ---------------------------------------------
(define-read-only (get-last-checkin (user principal))
  (ok (map-get? last-checkin user))
)

;; ---------------------------------------------
;; View: Get token balance
;; ---------------------------------------------
(define-read-only (get-balance (user principal))
  (ok (ft-get-balance checkin-token user))
)

;; ---------------------------------------------
;; View: Get total token supply
;; ---------------------------------------------
(define-read-only (get-total-supply)
  (ok (var-get total-supply))
)
