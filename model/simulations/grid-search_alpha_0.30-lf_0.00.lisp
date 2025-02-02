
(load "/projects/actr/actr7/load-act-r.lisp")
(load "../simon-device.lisp")
(load "../simon-model.lisp")
(load "../simon-simulations.lisp")
(with-open-file (out "grid-search-alpha_0.30-lf_0.00.txt" :direction :output 
		     :if-exists :overwrite :if-does-not-exist :create)
  (simulate-psp 100
		out
                :alpha 0.30
                :lf 0.00))
		
