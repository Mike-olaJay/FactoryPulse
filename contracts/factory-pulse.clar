;; FactoryPulse Smart Contract
;; A contract for IoT integration with manufacturing equipment on the blockchain

(define-data-var contract-owner principal tx-sender)
(define-data-var admin-address principal tx-sender)
(define-map equipment-registry 
  { equipment-id: (string-ascii 24) }
  { 
    owner: principal,
    name: (string-ascii 64),
    model: (string-ascii 64),
    status: (string-ascii 12),
    last-updated: uint
  }
)

(define-map maintenance-records
  { equipment-id: (string-ascii 24), record-id: uint }
  {
    timestamp: uint,
    performed-by: principal,
    description: (string-ascii 256),
    status: (string-ascii 12)
  }
)

(define-map equipment-metrics
  { equipment-id: (string-ascii 24), timestamp: uint }
  {
    temperature: int,
    vibration: uint,
    power-consumption: uint,
    operational-hours: uint
  }
)

(define-map authorized-reporters principal bool)

(define-data-var next-record-id uint u1)

;; Constants for validation
(define-constant ERR-INVALID-STATUS (err u400))
(define-constant ERR-INVALID-TEMPERATURE (err u401))
(define-constant ERR-INVALID-METRICS (err u402))
(define-constant ERR-UNAUTHORIZED (err u403))

;; Helper functions for validation
(define-private (is-valid-status (status (string-ascii 12)))
  (or (is-eq status "idle")
      (is-eq status "running")
      (is-eq status "maintenance")
      (is-eq status "error")))

(define-private (is-valid-temperature (temp int))
  (and (>= temp -50) (<= temp 150)))

(define-private (is-valid-metrics (vibration uint) (power uint) (hours uint))
  (and (<= vibration u1000)
       (<= power u10000)
       (<= hours u8760)))

;; Constants for validation
(define-constant ERR-INVALID-INPUT (err u405))
(define-constant MIN-STRING-LENGTH u1)

;; Helper functions for validation
(define-private (is-valid-string (input (string-ascii 256)))
  (> (len input) MIN-STRING-LENGTH))

;; Public functions

(define-public (register-equipment (equipment-id (string-ascii 24)) (name (string-ascii 64)) (model (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u403))
    (asserts! (is-none (map-get? equipment-registry { equipment-id: equipment-id })) (err u100))
    (asserts! (is-valid-string equipment-id) ERR-INVALID-INPUT)
    (asserts! (is-valid-string name) ERR-INVALID-INPUT)
    (asserts! (is-valid-string model) ERR-INVALID-INPUT)
    (map-set equipment-registry
      { equipment-id: equipment-id }
      {
        owner: tx-sender,
        name: name,
        model: model,
        status: "idle",
        last-updated: stacks-block-height
      }
    )
    (ok true)
  )
)

(define-public (update-equipment-status (equipment-id (string-ascii 24)) (new-status (string-ascii 12)))
  (begin
    (asserts! (is-valid-string equipment-id) ERR-INVALID-INPUT)
    (let ((equipment (unwrap! (map-get? equipment-registry { equipment-id: equipment-id }) (err u101))))
      (asserts! (or (is-authorized tx-sender) (is-eq tx-sender (get owner equipment))) (err u403))
      (asserts! (is-valid-status new-status) ERR-INVALID-STATUS)
      (map-set equipment-registry
        { equipment-id: equipment-id }
        (merge equipment { 
          status: new-status,
          last-updated: stacks-block-height 
        })
      )
      (ok true)
    )
  )
)

(define-public (add-maintenance-record (equipment-id (string-ascii 24)) (description (string-ascii 256)) (status (string-ascii 12)))
  (begin
    (asserts! (is-valid-string equipment-id) ERR-INVALID-INPUT)
    (asserts! (is-valid-string description) ERR-INVALID-INPUT)
    (let ((equipment (unwrap! (map-get? equipment-registry { equipment-id: equipment-id }) (err u101)))
          (record-id (var-get next-record-id)))
      (asserts! (or (is-authorized tx-sender) (is-eq tx-sender (get owner equipment))) (err u403))
      (asserts! (is-valid-status status) ERR-INVALID-STATUS)
      (var-set next-record-id (+ record-id u1))
      (map-set maintenance-records
        { equipment-id: equipment-id, record-id: record-id }
        {
          timestamp: stacks-block-height,
          performed-by: tx-sender,
          description: description,
          status: status
        }
      )
      (ok record-id)
    )
  )
)

(define-public (report-equipment-metrics 
                (equipment-id (string-ascii 24)) 
                (temperature int) 
                (vibration uint) 
                (power-consumption uint)
                (operational-hours uint))
  (begin
    (asserts! (is-valid-string equipment-id) ERR-INVALID-INPUT)
    (let ((equipment (unwrap! (map-get? equipment-registry { equipment-id: equipment-id }) (err u101))))
      (asserts! (or (is-authorized tx-sender) (is-eq tx-sender (get owner equipment))) (err u403))
      (asserts! (is-valid-temperature temperature) ERR-INVALID-TEMPERATURE)
      (asserts! (is-valid-metrics vibration power-consumption operational-hours) ERR-INVALID-METRICS)
      (map-set equipment-metrics
        { equipment-id: equipment-id, timestamp: stacks-block-height }
        {
          temperature: temperature,
          vibration: vibration,
          power-consumption: power-consumption,
          operational-hours: operational-hours
        }
      )
      (ok true)
    )
  )
)

(define-public (authorize-reporter (reporter principal))
  (begin
    (asserts! (or (is-eq tx-sender (var-get contract-owner)) (is-eq tx-sender (var-get admin-address))) (err u403))
    (asserts! (not (is-eq reporter (var-get contract-owner))) ERR-INVALID-INPUT)
    (map-set authorized-reporters reporter true)
    (ok true)
  )
)

(define-public (remove-reporter (reporter principal))
  (begin
    (asserts! (or (is-eq tx-sender (var-get contract-owner)) (is-eq tx-sender (var-get admin-address))) (err u403))
    (asserts! (not (is-eq reporter (var-get contract-owner))) ERR-INVALID-INPUT)
    (map-delete authorized-reporters reporter)
    (ok true)
  )
)

(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u403))
    (asserts! (not (is-eq new-admin (var-get contract-owner))) ERR-INVALID-INPUT)
    (var-set admin-address new-admin)
    (ok true)
  )
)

;; Read-only functions

(define-read-only (get-equipment-details (equipment-id (string-ascii 24)))
  (map-get? equipment-registry { equipment-id: equipment-id })
)

(define-read-only (get-maintenance-record (equipment-id (string-ascii 24)) (record-id uint))
  (map-get? maintenance-records { equipment-id: equipment-id, record-id: record-id })
)

(define-read-only (get-latest-metrics (equipment-id (string-ascii 24)) (timestamp uint))
  (map-get? equipment-metrics { equipment-id: equipment-id, timestamp: timestamp })
)

(define-read-only (is-authorized (address principal))
  (default-to false (map-get? authorized-reporters address))
)