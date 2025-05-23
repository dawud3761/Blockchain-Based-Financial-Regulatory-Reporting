;; Institution Verification Contract
;; Validates and manages financial entities in the system

(define-data-var admin principal tx-sender)

;; Map of verified institutions
(define-map verified-institutions
  { institution-id: (string-ascii 64) }
  {
    name: (string-ascii 100),
    license-number: (string-ascii 64),
    address: (string-ascii 256),
    is-active: bool,
    verification-date: uint
  }
)

;; Verify a new institution (only admin can call)
(define-public (verify-institution (institution-id (string-ascii 64))
                                  (name (string-ascii 100))
                                  (license-number (string-ascii 64))
                                  (address (string-ascii 256)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? verified-institutions { institution-id: institution-id }))
              (err u100))
    (ok (map-set verified-institutions
      { institution-id: institution-id }
      {
        name: name,
        license-number: license-number,
        address: address,
        is-active: true,
        verification-date: block-height
      }))
  )
)

;; Check if an institution is verified
(define-read-only (is-verified (institution-id (string-ascii 64)))
  (match (map-get? verified-institutions { institution-id: institution-id })
    institution (ok (get is-active institution))
    (err u404)
  )
)

;; Deactivate an institution
(define-public (deactivate-institution (institution-id (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (match (map-get? verified-institutions { institution-id: institution-id })
      institution (ok (map-set verified-institutions
                      { institution-id: institution-id }
                      (merge institution { is-active: false })))
      (err u404)
    )
  )
)

;; Get institution details
(define-read-only (get-institution-details (institution-id (string-ascii 64)))
  (map-get? verified-institutions { institution-id: institution-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
