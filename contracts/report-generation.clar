;; Report Generation Contract
;; Creates standardized regulatory reports

(define-data-var admin principal tx-sender)

;; Map of generated reports
(define-map generated-reports
  { report-id: (string-ascii 64) }
  {
    institution-id: (string-ascii 64),
    requirement-id: (string-ascii 64),
    data-report-id: (string-ascii 64), ;; Reference to data collection contract
    report-hash: (buff 32), ;; Hash of the final standardized report
    generation-date: uint,
    version: uint
  }
)

;; Generate a standardized report
(define-public (generate-report (report-id (string-ascii 64))
                               (institution-id (string-ascii 64))
                               (requirement-id (string-ascii 64))
                               (data-report-id (string-ascii 64))
                               (report-hash (buff 32)))
  (begin
    ;; Allow specific institutions or admin to generate reports
    ;; In a real system, we'd add more authentication checks
    (asserts! (is-none (map-get? generated-reports { report-id: report-id }))
              (err u100))
    (ok (map-set generated-reports
      { report-id: report-id }
      {
        institution-id: institution-id,
        requirement-id: requirement-id,
        data-report-id: data-report-id,
        report-hash: report-hash,
        generation-date: block-height,
        version: u1
      }))
  )
)

;; Update an existing report (new version)
(define-public (update-report (report-id (string-ascii 64))
                             (new-report-hash (buff 32)))
  (begin
    (match (map-get? generated-reports { report-id: report-id })
      report (ok (map-set generated-reports
                 { report-id: report-id }
                 (merge report {
                   report-hash: new-report-hash,
                   generation-date: block-height,
                   version: (+ (get version report) u1)
                 })))
      (err u404)
    )
  )
)

;; Get report details
(define-read-only (get-report-details (report-id (string-ascii 64)))
  (map-get? generated-reports { report-id: report-id })
)

;; Verify a report hash
(define-read-only (verify-report-hash (report-id (string-ascii 64)) (report-hash (buff 32)))
  (match (map-get? generated-reports { report-id: report-id })
    report (ok (is-eq report-hash (get report-hash report)))
    (err u404)
  )
)
