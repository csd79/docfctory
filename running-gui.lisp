;;;; -*- Mode: Common-Lisp; Author: denes.cselovszky@gmail.com -*- 
                                                                              ;

(in-package #:docfctory)


;; ----------------------------------------------------------------------
;; Global vars


(defparameter *text-buffer-name* "temp")


;; ----------------------------------------------------------------------
;; Running GUI


;;; GUI window during processing.
(capi:define-interface progress ()
  ()
  (:panes
   ;; Pane to contain text output from the working thread.
   (text-dump
    capi:editor-pane
    :accessor           text-dump
    :flag               'minimal-example
    :buffer-name        *text-buffer-name*
    :enabled            :read-only
    :visible-min-width  '(character 80)
    :visible-min-height '(character 30))
   ;; Progress bar.
   (progress
    capi:progress-bar
    :accessor progress
    :start 0
    :end 100))
  (:default-initargs
   :title "Feldolgozás"
   :best-x 735
   :best-y 400))



;;; Write into the GUI's text pane.
(defun dump-text (string)
  (let* ((buffer (editor:buffer-from-name *text-buffer-name*))
         (point  (editor:buffers-end buffer)))
    (editor:insert-string point string)))


;;; Return fn to change the progress bar.
(defun progress-bar-changer (interface)
  (lambda (percent)
    (setf (capi:range-slug-start (progress interface))
          percent)))


;;; Start progress GUI, and call DOCFCTORY.
(defun run-progress (control-book control-sheet filename-column)
  (let ((progress-gui (make-instance 'progress)))
    ;; Flushing the buffer for each new run.
    (capi:modify-editor-pane-buffer (text-dump progress-gui)
                                    :contents "")
    ;; Show progress GUI.
    (capi:display progress-gui)
    ;; Start process.
    (with-property-accessors
      (setf (property-accessors-on) t)
      (docfctory control-book control-sheet filename-column
                 #'dump-text (progress-bar-changer progress-gui)))))
