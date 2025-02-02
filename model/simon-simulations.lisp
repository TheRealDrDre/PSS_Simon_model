;;; ==================================================================
;;; SIMON-SIMULATIONS.LISP
;;; ==================================================================
;;; (c) 2016, Andrea Stocco, University of Washington
;;;           stocco@uw.edu
;;; ==================================================================
;;; A set of utilities for simulations and parameter fitting.  
;;; ==================================================================

;;; ----------------------------------------------------------------
;;; Running simulations
;;; ----------------------------------------------------------------

(defun decision-productions ()
  "Returns a sorted list of decision productions for a model, ('picks' first)"
  (let* ((prods (no-output (spp)))
	 (dos 
	  (remove-if-not #'(lambda (x) 
			     (string-equal (subseq (symbol-name x) 0 4) "proc")) 
			 prods))
	 (donts 
	  (remove-if-not #'(lambda (x) 
			     (string-equal (subseq (symbol-name x) 0 4) "dont")) 
			 prods)))
    (append (sort dos #'string< :key 'symbol-name)
	    (sort donts #'string< :key 'symbol-name))))

(defun decision-utilities (prods)
  "Returns a list of utilities associated with a list of productions"
  (mapcar #'(lambda (x) 
	      (caar (no-output (spp-fct (list x :u))))) 
	  prods))


(defun simulate-d2 (n vals &key (out t) (report t) (params nil))
  " Generates a list of performances for varyig D2 values"
  (format out "~{~a~^, ~}~%" '("D2" "Con/ACC" "Con/RT" "In/ACC" "In/RT"))
  (dolist (v vals)
    (setf *d2* v)
    (let* ((res (simulate n :verbose nil :report report :params params))
	   (nums (mapcar #'(lambda (x) (cons v x)) res)))
      (dolist (partial nums)
	(format out "~{~4,f~^, ~}~%" partial)))))

(defun simulate-d1 (n vals &key (out t) (report t) (params nil))
  " Generates a list of performances for varyig D2 values"
  (format out "~{~a~^, ~}~%" '("D1" "Con/ACC" "Con/RT" "In/ACC" "In/RT"))
  (dolist (v vals)
    (setf *d1* v)
    (let* ((res (simulate n :verbose nil :report report :params params))
	   (nums (mapcar #'(lambda (x) (cons v x)) res)))
      (dolist (partial nums)
	(format out "~{~4,f~^, ~}~%" partial)))))


(defun simulate-d1-d2 (n vals &key (out t) (report t) (params nil))
  "Generates a list of performances for varying D1 and D2 values"
  (format out "~{~a~^, ~}~%" '("D1" "D2" "Con/ACC" "Con/RT" "In/ACC" "In/RT"))
  (dolist (v1 vals)
    (dolist (v2 vals)
      (setf *d1* v1)
      (setf *d2* v2)
      (let* ((res (simulate n :verbose nil :report report :params params))
	     (nums (mapcar #'(lambda (x) (append 
					  (list v1 v2) 
					  x)) 
			   res)))
	(dolist (partial nums)
	  (format out "~{~4,f~^, ~}~%" partial))))))


(defun simulate (n &key (params nil) (verbose nil) (report t))
  "Simulates N runs of the model, and returns the results either as a list or as a report"
  (let ((results nil))
    (dotimes (i n (average-results results))
      (simon-reload :visicon nil)
      (when params
	;(sgp-fct (mapcan #'(lambda (x) (list (first x) (rest x))) params)))
	(sgp-fct (flatten params)))
      (sgp :v nil
	   :style-warnings nil
	   :model-warnings nil)
      (run 10000)
      (when verbose
	(when (= (mod i (round (/ n 10))) 0)
	  (let* ((c (round (/ (* 10 i) n)))
		 (empty (- 10 c))
		 (bar (make-string c :initial-element #\=))
		 (space (make-string empty :initial-element #\space))
		 (total (format nil "|~A~A| ~A#\%" bar space (* 10 c))))
	    
	    (format t total)
	    (finish-output))
	  (if *using-swank*
	      (format t "~%")
	      (dotimes (i 17)
		(write-char #\backspace)))))
      (push (append (analyze-log (experiment-log (current-device)))
		    (decision-utilities (decision-productions)))
	    results))
    (if report
	(list (average-results results))
	results)))


;;; -------------------------------------------------------------- ;;;
;;; PARAMETER SPACE PARTITIONING
;;; -------------------------------------------------------------- ;;;
;;; PSP analysis to examine how model parameters affect data
;;; patterns.
;;; Which are the data patterns of interest? 
;;; -------------------------------------------------------------- ;;;

(defparameter *parameters* '(:alpha :lf :egs :ans *bias* *d1* *d2*))


(defun seq (start end &optional (step 1))
  "Creates a list with a range of numbers"
  (let ((results nil)
	(partial start))
    (cond ((and (< start end)
		(plusp step))
	   (loop while (< partial end) do
	     (push partial results)
	     (incf partial step)))
	  ((and (> start end)
		(minusp step))
	   (loop while (> partial end) do
	     (push partial results)
	     (incf partial step)))
	  (t
	   nil))
    (reverse results)))


(defun act-r-parameter? (sym)
  "Checks whether a symbol names an ACT-R parameter"
  (keywordp sym))


(defun param-value (x)
  "Returns the correct value of a parameter (whether ACT-R or not)"
  (if (act-r-parameter? x)
      (no-output (sgp-fct (list x)))
      (list (eval x))))

(defun param-name (x)
  "Returns the name of a parameter"
  (let ((str (format nil "~A" x)))
    (string-trim "*:" str)))
	
 

(defun param-values (&optional (params *parameters*))
  "Returns the values of all parameters as a list"
  (mapcan #'param-value params))


(defun simulate-psp (n out &key (alpha 0.4) (lf 0.2))
  "Grid search of parameter space"
  (dolist (egs (seq 0 0.21 5/100))
    (dolist (ans (seq 0.2 1.1 2/10))
      (dolist (bias (seq 1 11 1))
	(let ((params `((:alpha ,alpha)
			(:lf ,lf)
			(:ans ,ans)
			(:egs ,egs))))
	  ;(print params)
	  (setf *bias* bias)
	  (setf *d1* 1 *d2* 1)
	  (dolist (d1 (seq 0.5 1.51 0.125))
	    (setf *d1* d1)
	    (let* ((res (simulate n :params params :report t))
		   (row (append (param-values)
				(first res))))
	      (format out "~{~4,f~^, ~}~%" row)
	      (finish-output)))

	  (setf *d1* 1 *d2* 1)
	  (dolist (d2 (seq 0.5 1.51 0.125))
	    (setf *d2* d2)
	    (let* ((res (simulate n :params params :report t))
		   (row (append (param-values)
				(first res))))
	      (format out "~{~4,f~^, ~}~%" row)
	      (finish-output))))))))


(defun simulate-psp2 (n out &key (alpha 0.4) (egs 0.0))
  "Grid search of parameter space"
  (dolist (lf (seq 0.20 0.31 5/100))
    ;(dolist (ans (seq 0.2 1.1 2/10))
    (dolist (ans (seq 0.2 0.21 25/100))
      (dolist (bias (seq 1 11 1))
	(let ((params `((:alpha ,alpha)
			(:lf ,lf)
			(:ans ,ans)
			(:egs ,egs))))
					;(print params)
	  (setf *bias* bias)
	  (setf *d1* 1 *d2* 1)
	  (dolist (d1 (seq 0.0 2.05 0.1))
	    (setf *d1* d1)
	    ;;	  (setf *d1* 1 *d2* 1)
	    (dolist (d2 (seq 0.0 2.05 0.1))
	      (setf *d2* d2)
	      (let* ((res (simulate n :params params :report t))
		     (row (append (param-values)
				  (first res))))
		(format out "~{~4,f~^, ~}~%" row)
		(finish-output)))))))))

(defun approx-equal (val1 val2)
  (let ((percent-diff  (/ (abs (- val1 val2))
			  (min val1 val2))))
    (< percent-diff 2/100)))

(defun approx-diff (val1 val2)
  (if (approx-equal val1 val2)
      0
      (- val1 val2)))


