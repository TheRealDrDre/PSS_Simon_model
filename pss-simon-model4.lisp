;;; PSS _ SImon task


;;; main idea, same as Lovett's NJAMOS
;;; Selective attention is competition among productions.
;;; ================================================================
;;; SIMON TASK MODEL
;;; ================================================================
;;; (c) 2016, Andrea Stocco, University of Washington
;;;           stocco@uw.edu
;;; ================================================================
;;; This is an ACT-R model of the Simon task.
;;; ================================================================

(clear-all)

(define-model competitive-simon

(sgp :er t
     :act nil
     :esc T
     :ans 0.5
     :auto-attend T
     :le 0.67
     :lf 0.3
     :mas 4.0
     :ul T
     :egs 0.2
     :reward-hook bg-reward-hook
     :alpha 0.1
     :imaginal-activation 3.0
     :imaginal-delay 0.01
     :visual-activation 2.0
     :motor-burst-time 0.05
     :motor-feature-prep-time 0.05    
     :motor-initiation-time 0.01
)

(chunk-type (simon-stimulus (:include visual-object))
	    kind shape color position)

(chunk-type (simon-screen (:include visual-object))
	    kind value)

(chunk-type (simon-stimulus-location (:include visual-location))
	    shape color position)

(chunk-type simon-rule kind has-motor-response shape hand dimension)

(chunk-type compatible-response has-motor-response hand position)

;(chunk-type hand-response kind hand) 

(chunk-type wm
	    state
	    value1
	    value2
	    checked)

(add-dm (simon-rule isa chunk)
	(simon-stimulus isa chunk)
	(simon-screen isa chunk)
	(stimulus isa chunk)
	(done isa chunk)
	(pause isa chunk)
	(circle isa chunk)
	(square isa chunk)
	(shape isa chunk)
	(not-shape isa chunk)
	(position isa chunk)
	(not-position isa chunk)
	(yes isa chunk)
	(no isa chunk)
	(proceed isa chunk)
	(process isa chunk)
	(hand-response isa chunk)
	(blocked isa chunk)
	(circle-left isa simon-rule
		     kind simon-rule
		     has-motor-response yes
		     hand left
		     shape circle
		     dimension shape)

	(square-right isa simon-rule
		      kind simon-rule
		      has-motor-response yes
		      hand right
		      shape square
		      dimension shape)

	(stimulus1 isa simon-stimulus
		   shape circle
		   position right
		   color black
		   kind simon-stimulus)

	(wm1 isa wm
	     state proceed)
)

(p find-screen
   "Look at the screen (if you were not already looking at it)"
   ?visual>
     buffer empty
     state free
     
   ?visual-location>
     buffer empty
     state free
==>
   +visual-location>
     screen-x lowest
)  

(p prepare-wm
   "If there are no contents in WM, prepare contents"
   ?imaginal>
     buffer empty
     state free

   ?manual>
     preparation free
     processor free
     execution free  
==>
   +imaginal>
     isa wm
     state process
     checked no
)

;;; ----------------------------------------------------------------
;;; SELECTIVE ATTENTION
;;; ----------------------------------------------------------------
;;; These production compete for attention to shape and position of
;;; the stimulus
;;; ----------------------------------------------------------------

(p process-shape
   "Encodes the shape in WM"
   =visual>
     kind simon-stimulus
     shape =SHAPE
     
   =imaginal>
     state process
     value1 nil

   ?retrieval>
     state free
     buffer empty

==>
   =visual>
   =imaginal>
     value1 =SHAPE
)

(p dont-process-shape
   "Does not encode the shape (focuses on position as a side effect)"
   =visual>
     kind simon-stimulus
     position =POS
     
   =imaginal>
     state process
     value1 nil

   ?retrieval>
     state free
     buffer empty

==>
   =visual>
   =imaginal>
      value1 =POS
   
)

(p process-position
   "Encodes the stimulus position in WM"
   =visual>
     kind simon-stimulus
     position =POS
     
   =imaginal>
     state process
     value2 nil

   ?retrieval>
     state free
     buffer empty

==>
   =visual>
   =imaginal>
     value2 =POS
)

(p dont-process-position
   "Does not encode the position (focuses on the shape as a side effect"
   =visual>
     kind simon-stimulus
     shape =SHAPE
     
   =imaginal>
     state process
     value2 nil

   ?retrieval>
     state free
     buffer empty

==>
   =visual>     
   =imaginal>
     value2 =SHAPE
)

;;; ----------------------------------------------------------------
;;; RESPONSE AND CHECK
;;; ----------------------------------------------------------------
;;; The more responds by harvesting the most active Simon rule.
;;; Thus, response is guided by spreading activation from WM.
;;; A one-time check routine is also granted.
;;; ----------------------------------------------------------------

(p retrieve-intended-response
   "Retrieves the relevant part of the Simon Task rule"
   =visual>
     kind simon-stimulus
     shape =SHAPE
     
   =imaginal>
     state process
   - value1 nil
   - value2 nil  
   
   ?retrieval>
     state free
     buffer empty
==>
   =visual>   ; Keep visual
   =imaginal> ; Keep WM
   
   +retrieval>
     kind simon-rule
     ;shape =SHAPE
     has-motor-response yes
)


;;; Check
;;; Last time to catch yourself making a mistake
(p check-pass
   "Makes sure the response is compatible with the rules"
   =visual>
     shape =SHAPE
   
   =retrieval>
     kind  simon-rule
     shape =SHAPE

   =imaginal>
     state process
     checked no
   
   ?imaginal>
     state free
==>
   =visual>
   =retrieval>
   =imaginal>
     value2 nil
     checked yes
 )

(p check-detect-problem
   "If there is a problem, redo the retrieval once"
   =visual>
     shape =SHAPE
   
   =retrieval>
     kind  simon-rule
   - shape =SHAPE

   =imaginal>
     state process
     checked no
   
   ?imaginal>
     state free
 ==>
   =visual>
   -retrieval>
   =imaginal>
     value1 nil
     value2 nil
     checked yes
 )

 
(p respond
   "If we have a response and it has been check, we respond"
   =visual>
     kind simon-stimulus
     shape =SHAPE 

   =imaginal>
     state process
     checked yes

   =retrieval>
     kind simon-rule
     has-motor-response yes
     hand =HAND
     
   ?manual>
     preparation free
     processor free
     execution free
==>
  -imaginal>
  -retrieval>
  +manual>
     isa punch
     hand =HAND
     finger index
)

;(spp check-pass :reward 1)
(spp check-detect-problem :reward -1)
(spp process-shape :u 1 :fixed-utility t)
(spp process-position :u 0.7 :fixed-utility t)

)  ;;; End of the model

(defun simon4-reload (&key (visicon t))
  (reload)
  (install-device (make-instance 'simon-task))
  (init (current-device))
  (proc-display)
  (when visicon
    (print-visicon)))

