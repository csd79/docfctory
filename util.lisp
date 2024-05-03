;;;; -*- Mode: Common-Lisp; Author: denes.cselovszky@gmail.com -*- 
                                                                              ;

(in-package #:docfctory)


;; ----------------------------------------------------------------------
;; Utilities


;;; Extract a list of worksheet names from az Excel workbook.
(defun list-of-worksheets (filename)
  (cclet* ((sheets #p(worksheets (get-document filename)))
           (count  #p(count sheets)))
    (loop for i from 1 upto count collecting
          #p(name #p(item sheets i)))))


;;; Extract the device/path part of a full pathname.
(defun file-directory (filename)
  (let ((raw-pathname (make-pathname
                       :host (pathname-host filename)
                       :directory (pathname-directory filename))))
    (namestring raw-pathname)))


;;; Check if directory exists.
(defun probe-directory (pathname)
  (and (string/= pathname "")
       (probe-file pathname)))


;;; Check if file exists.
(defun probe-file2 (pathname)
  (and (probe-directory pathname)
       (pathname-name pathname)))
