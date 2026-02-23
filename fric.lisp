(in-package :cl-mpm/examples/penalty/sliding)
(defparameter *refine* (parse-float:parse-float (if (uiop:getenv "REFINE") (uiop:getenv "REFINE") "1")))

(let ((threads (parse-integer (if (uiop:getenv "OMP_NUM_THREADS") (uiop:getenv "OMP_NUM_THREADS") "16"))))
  (setf lparallel:*kernel* (lparallel:make-kernel threads :name "custom-kernel"))
  (format t "Thread count ~D~%" threads))

(defun run (&key (output-dir "./output/") (results-dir nil))
  (unless results-dir
    (setf results-dir output-dir)
    (ensure-directories-exist (merge-pathnames results-dir)))
  (let ((total-disp 1d-1)
        (current-disp 0d0))
    (defparameter *data-disp* (list 0d0))
    (defparameter *data-load* (list 0d0))
    (defparameter *displacement* 0d0)
    (vgplot:close-all-plots)
    (cl-mpm/dynamic-relaxation::run-load-control
     *sim*
     :output-dir output-dir
     :load-steps 100
     :damping 1d0
     :substeps 50
     :criteria 1d-9
     :save-vtk-dr nil
     :save-vtk-loadstep t
     :loading-function
     (lambda (percent)
       (setf current-disp (* total-disp percent))
       (setf *displacement* current-disp)
       (cl-mpm/penalty::bc-set-displacement
        *loader*
        (cl-mpm/utils:vector-from-list
         (list
          current-disp
          0d0
          0d0)))
       (cl-mpm/penalty::bc-set-displacement
        *follower*
        (cl-mpm/utils:vector-from-list
         (list
          current-disp
          0d0
          0d0))))
     :pre-step
     (lambda ()
       (output-disp-header results-dir)
       (output-disp-data results-dir))
     :post-conv-step
     (lambda (sim)
       (push current-disp *data-disp*)
       (push (get-load) *data-load*)
       (output-disp-data results-dir))
     :dt-scale 1d0))
  )

(let* ((mu 0.5d0)
       (r *refine*))
  (setup :refine r
         :mps 2
         :mu mu
         :epsilon-scale 1d0)
  (run :output-dir (format nil "./data/output-refine-~E/" r)
       ;:results-dir (format nil "./results/data-refine-~E/" r)
       ))
