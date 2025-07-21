;; Maintenance Scheduling Contract
;; Coordinates equipment testing and repairs

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-MAINTENANCE-NOT-FOUND (err u201))
(define-constant ERR-INVALID-STATUS (err u202))
(define-constant ERR-INVALID-PRIORITY (err u203))
(define-constant ERR-TECHNICIAN-NOT-FOUND (err u204))

;; Maintenance status constants
(define-constant MAINTENANCE-SCHEDULED u1)
(define-constant MAINTENANCE-IN-PROGRESS u2)
(define-constant MAINTENANCE-COMPLETED u3)
(define-constant MAINTENANCE-CANCELLED u4)

;; Priority constants
(define-constant PRIORITY-LOW u1)
(define-constant PRIORITY-MEDIUM u2)
(define-constant PRIORITY-HIGH u3)
(define-constant PRIORITY-CRITICAL u4)

;; Data Variables
(define-data-var next-maintenance-id uint u1)
(define-data-var next-technician-id uint u1)

;; Data Maps
(define-map maintenance-records
  { maintenance-id: uint }
  {
    equipment-id: uint,
    maintenance-type: (string-ascii 30),
    description: (string-ascii 200),
    priority: uint,
    status: uint,
    scheduled-date: uint,
    assigned-technician: (optional uint),
    estimated-hours: uint,
    actual-hours: (optional uint),
    cost: (optional uint),
    completed-date: (optional uint),
    notes: (optional (string-ascii 500))
  }
)

(define-map technicians
  { technician-id: uint }
  {
    name: (string-ascii 50),
    specialization: (string-ascii 30),
    certification-level: uint,
    active: bool,
    current-workload: uint
  }
)

(define-map maintenance-history
  { equipment-id: uint, maintenance-id: uint }
  {
    maintenance-date: uint,
    maintenance-type: (string-ascii 30),
    technician-id: uint,
    cost: uint,
    notes: (string-ascii 500)
  }
)

(define-map authorized-personnel principal bool)

;; Authorization functions
(define-private (is-authorized (user principal))
  (or
    (is-eq user CONTRACT-OWNER)
    (default-to false (map-get? authorized-personnel user))
  )
)

;; Public functions

;; Add authorized personnel
(define-public (add-authorized-personnel (user principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set authorized-personnel user true))
  )
)

;; Register new technician
(define-public (register-technician
  (name (string-ascii 50))
  (specialization (string-ascii 30))
  (certification-level uint)
)
  (let ((technician-id (var-get next-technician-id)))
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= certification-level u1) (<= certification-level u5)) ERR-INVALID-STATUS)
    (map-set technicians
      { technician-id: technician-id }
      {
        name: name,
        specialization: specialization,
        certification-level: certification-level,
        active: true,
        current-workload: u0
      }
    )
    (var-set next-technician-id (+ technician-id u1))
    (ok technician-id)
  )
)

;; Schedule maintenance
(define-public (schedule-maintenance
  (equipment-id uint)
  (maintenance-type (string-ascii 30))
  (description (string-ascii 200))
  (priority uint)
  (scheduled-date uint)
  (estimated-hours uint)
)
  (let ((maintenance-id (var-get next-maintenance-id)))
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= priority u1) (<= priority u4)) ERR-INVALID-PRIORITY)
    (map-set maintenance-records
      { maintenance-id: maintenance-id }
      {
        equipment-id: equipment-id,
        maintenance-type: maintenance-type,
        description: description,
        priority: priority,
        status: MAINTENANCE-SCHEDULED,
        scheduled-date: scheduled-date,
        assigned-technician: none,
        estimated-hours: estimated-hours,
        actual-hours: none,
        cost: none,
        completed-date: none,
        notes: none
      }
    )
    (var-set next-maintenance-id (+ maintenance-id u1))
    (ok maintenance-id)
  )
)

;; Assign technician to maintenance
(define-public (assign-technician (maintenance-id uint) (technician-id uint))
  (let (
    (maintenance-data (unwrap! (map-get? maintenance-records { maintenance-id: maintenance-id }) ERR-MAINTENANCE-NOT-FOUND))
    (technician-data (unwrap! (map-get? technicians { technician-id: technician-id }) ERR-TECHNICIAN-NOT-FOUND))
  )
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (get active technician-data) ERR-TECHNICIAN-NOT-FOUND)
    (asserts! (is-eq (get status maintenance-data) MAINTENANCE-SCHEDULED) ERR-INVALID-STATUS)

    (map-set maintenance-records
      { maintenance-id: maintenance-id }
      (merge maintenance-data { assigned-technician: (some technician-id) })
    )

    (map-set technicians
      { technician-id: technician-id }
      (merge technician-data {
        current-workload: (+ (get current-workload technician-data) (get estimated-hours maintenance-data))
      })
    )
    (ok true)
  )
)

;; Start maintenance work
(define-public (start-maintenance (maintenance-id uint))
  (let (
    (maintenance-data (unwrap! (map-get? maintenance-records { maintenance-id: maintenance-id }) ERR-MAINTENANCE-NOT-FOUND))
  )
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status maintenance-data) MAINTENANCE-SCHEDULED) ERR-INVALID-STATUS)
    (asserts! (is-some (get assigned-technician maintenance-data)) ERR-TECHNICIAN-NOT-FOUND)

    (map-set maintenance-records
      { maintenance-id: maintenance-id }
      (merge maintenance-data { status: MAINTENANCE-IN-PROGRESS })
    )
    (ok true)
  )
)

;; Complete maintenance work
(define-public (complete-maintenance
  (maintenance-id uint)
  (actual-hours uint)
  (cost uint)
  (notes (string-ascii 500))
)
  (let (
    (maintenance-data (unwrap! (map-get? maintenance-records { maintenance-id: maintenance-id }) ERR-MAINTENANCE-NOT-FOUND))
    (technician-id (unwrap! (get assigned-technician maintenance-data) ERR-TECHNICIAN-NOT-FOUND))
    (technician-data (unwrap! (map-get? technicians { technician-id: technician-id }) ERR-TECHNICIAN-NOT-FOUND))
  )
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status maintenance-data) MAINTENANCE-IN-PROGRESS) ERR-INVALID-STATUS)

    (map-set maintenance-records
      { maintenance-id: maintenance-id }
      (merge maintenance-data {
        status: MAINTENANCE-COMPLETED,
        actual-hours: (some actual-hours),
        cost: (some cost),
        completed-date: (some block-height),
        notes: (some notes)
      })
    )

    (map-set maintenance-history
      { equipment-id: (get equipment-id maintenance-data), maintenance-id: maintenance-id }
      {
        maintenance-date: block-height,
        maintenance-type: (get maintenance-type maintenance-data),
        technician-id: technician-id,
        cost: cost,
        notes: notes
      }
    )

    (map-set technicians
      { technician-id: technician-id }
      (merge technician-data {
        current-workload: (if (>= (get current-workload technician-data) (get estimated-hours maintenance-data))
          (- (get current-workload technician-data) (get estimated-hours maintenance-data))
          u0
        )
      })
    )
    (ok true)
  )
)

;; Read-only functions

;; Get maintenance record
(define-read-only (get-maintenance-record (maintenance-id uint))
  (map-get? maintenance-records { maintenance-id: maintenance-id })
)

;; Get technician details
(define-read-only (get-technician (technician-id uint))
  (map-get? technicians { technician-id: technician-id })
)

;; Get maintenance history for equipment
(define-read-only (get-maintenance-history (equipment-id uint) (maintenance-id uint))
  (map-get? maintenance-history { equipment-id: equipment-id, maintenance-id: maintenance-id })
)

;; Get next maintenance ID
(define-read-only (get-next-maintenance-id)
  (var-get next-maintenance-id)
)

;; Get next technician ID
(define-read-only (get-next-technician-id)
  (var-get next-technician-id)
)
