;; Data Collection Contract
;; Gathers and stores required reporting information

(define-data-var admin principal tx-sender)

;; Map of collected data
(define-map collected-data
  { report-id: (string-ascii 64) }
  {
    institution-id: (string-ascii 64),
    requirement-id: (string-ascii 64),
    data-hash: (buff 32), ;; SHA-256 hash of the report data
    timestamp: uint,
    status: (string-ascii 20) ;; "draft", "submitted", "approved", "rejected"
  }
)

;; Submit data for a report
(define-public (submit-data (report-id (string-ascii 64))
                           (institution-id (string-ascii 64))
                           (requirement-id (string-ascii 64))
                           (data-hash (buff 32)))
  (begin
    ;; Anyone can submit data, but we'd add authentication in a real system
    (asserts! (is-none (map-get? collected-data { report-id: report-id }))
              (err u100))
    (ok (map-set collected-data
      { report-id: report-id }
      {
        institution-id: institution-id,
        requirement-id: requirement-id,
        data-hash: data-hash,
        timestamp: block-height,
        status: "submitted"
      }))
  )
)

;; Update report status (admin only)
(define-public (update-status (report-id (string-ascii 64))
                             (new-status (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (match (map-get? collected-data { report-id: report-id })
      report (ok (map-set collected-data
                 { report-id: report-id }
                 (merge report { status: new-status })))
      (err u404)
    )
  )
)

;; Get report data
(define-read-only (get-report (report-id (string-ascii 64)))
  (map-get? collected-data { report-id: report-id })
)

;; Verify if a data hash matches what's stored
(define-read-only (verify-data-hash (report-id (string-ascii 64)) (data-hash (buff 32)))
  (match (map-get? collected-data { report-id: report-id })
    report (ok (is-eq data-hash (get data-hash report)))
    (err u404)
  )
)
