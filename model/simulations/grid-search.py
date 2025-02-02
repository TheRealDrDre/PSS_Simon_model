#!/usr/bin/env python

TMPLT = """
(load "/projects/actr/actr7/load-act-r.lisp")
(load "../simon-device.lisp")
(load "../simon-model.lisp")
(load "../simon-simulations.lisp")
(with-open-file (out "grid-search-alpha_%0.2f-lf_%0.2f.txt" :direction :output 
		     :if-exists :overwrite :if-does-not-exist :create)
  (simulate-psp 100
		out
                :alpha %0.2f
                :lf %0.2f))
		
"""
   
if __name__ == "__main__":
    i = 1
    for alpha in [x/100.0 for x in range(10,51,10)]:
        for lf in [x/100.0 for x in range(0,101,25)]:
            fout = open("grid-search_alpha_%0.2f-lf_%0.2f.lisp" % (alpha, lf), 'w')
            s = TMPLT % (alpha, lf, alpha, lf)
            fout.write(s)
            fout.flush()
            fout.close()
            i = i + 1
