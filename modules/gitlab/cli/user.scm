(define-module (gitlab cli user)
  #:use-module (oop goops)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 format)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 regex)
  #:use-module (web uri)
  #:use-module (gitlab)
  #:export (handle-user-command
            print
            print-many
            string->boolean))


;; Helper procedures.

(define (print result fields)
  (let ((fields (and fields (string-split fields #\,))))
    (for-each (lambda (rec)
                (let ((key   (car rec))
                      (value (cdr rec)))
                  (if (or (not fields)
                          (member key fields))
                      (format #t "~20a: ~a~%"
                              key
                              (cond
                               ((equal? value #f)
                                "false")
                               ((equal? value #t)
                                "true")
                               (else
                                value))))))
              result)))

(define (print-many data fields)
  (if fields
      (let ((fields (string-split fields #\,)))
        (pretty-print (map (lambda (user)
                             (filter (lambda (rec) (member (car rec) fields))
                                     user))
                           data)))
      (pretty-print data)))

(define (string->boolean str)
  (cond
   ((string=? str "true")
    #t)
   ((string=? str "false")
    #f)
   (else
    (error "Wrong boolean value (expecting 'true' or 'false')" str))))



(define (print-user-help program-name)
  (format #t "\
Usage: ~a user [arguments]

Options:
  --limit <limit>
              Limit the number of users that will be requested
              from the server.  By default, the command will fetch
              all the users that satisfy the requirements set by
              other options.
  --print, -p <list-of-parameters>
              Print only the specified parameters from this
              comma-separated list.
              Value example: name,email
  --id <id>
              ID of a user that should be requested.
  --name <name>
  --email-like <regexp>
              Print only users whose emails are matched by the
              regexp.  Note that currently this option does not work when
              '--id' is used.
  --email-not-like <regexp>
              Print only users whose emails are NOT matched by the
              regexp.  Note that currently this option does not work when
              '--id' is used.
  --username <username>
  --search <query>
              Search for users by name, username, primary email,
              or secondary email, by using this option.
  --state <state>
"
          program-name))

(define %user-option-spec
  '((help   (single-char #\h) (value #f))
    (server (single-char #\s) (value #t))
    (token  (single-char #\t) (value #t))
    (limit  (single-char #\l) (value #t))
    (print  (single-char #\p) (value #t))
    (id                       (value #t))
    (active?                  (value #t))
    (order-by                 (value #t))
    (sort                     (value #t))
    (name                     (value #t))
    (email-like               (value #t))
    (email-not-like           (value #t))
    (username                 (value #t))
    (search                   (value #t))
    (state                    (value #t))))

(define (string->boolean str)
  (cond
   ((string=? str "true")
    #t)
   ((string=? str "false")
    #f)
   (else
    (error "Wrong boolean value (expecting 'true' or 'false')" str))))

(define (handle-user-command program-name args)
  (let* ((options (getopt-long args %user-option-spec))
         (help-needed? (option-ref options 'help      #f))
         ;; Required parameters.
         (server       (option-ref options 'server    #f))
         (token        (option-ref options 'token     #f))
         ;; Optional parameters.
         (limit        (option-ref options 'limit     #f))
         (fields       (option-ref options 'print     #f))
         (id           (option-ref options 'id        #f))
         (active?      (option-ref options 'active?   'undefined))
         (external?    (option-ref options 'external? 'undefined))
         (order-by     (option-ref options 'order-by  'undefined))
         (sort         (option-ref options 'sort      'undefined))
         (name         (option-ref options 'name      'undefined))
         (email-like   (option-ref options 'email-like #f))
         (email-not-like (option-ref options 'email-not-like #f))
         (username     (option-ref options 'username  'undefined))
         (search       (option-ref options 'search    'undefined))
         (state        (option-ref options 'state     'undefined)))

    (when (or help-needed? (< (length args) 2))
      (print-user-help program-name)
      (exit 0))

    (unless token
      (error "GitLab token is not provided."))

    (unless server
      (error "GitLab server URL is not provided."))

    (let* ((gitlab (make <gitlab>
                     #:endpoint server
                     #:token    token))
           (result (gitlab-request-users gitlab
                                         #:limit     (and limit
                                                          (string->number limit))
                                         #:id        id
                                         #:username  username
                                         #:active?   (if (equal? active? 'undefined)
                                                         'undefined
                                                         (string->boolean active?))
                                         #:external? (if (equal? external? 'undefined)
                                                         'undefined
                                                         (string->boolean external?))
                                         #:order-by  order-by
                                         #:search    search
                                         #:sort      sort)))

      (when (and email-like email-not-like)
        (error "Only one option must be specified: --email-like, --email-not-like"))

      (cond
       (id
        (print result fields))
       (email-like
        (let* ((lst (vector->list result))
               (rx  (make-regexp email-like))
               (filtered-lst (filter (lambda (user)
                                       (regexp-exec rx (assoc-ref user "email")))
                                     lst)))
          (print-many filtered-lst fields)))
       (email-not-like
        (let* ((lst (vector->list result))
               (rx  (make-regexp email-not-like))
               (filtered-lst (filter (lambda (user)
                                       (not (regexp-exec rx (assoc-ref user "email"))))
                                     lst)))
          (print-many filtered-lst fields)))
       (else
        (print-many (vector->list result) fields))))))

;;; user.scm ends here.

