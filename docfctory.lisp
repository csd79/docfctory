;;;; -*- Mode: Common-Lisp; Author: denes.cselovszky@gmail.com -*- 
                                                                              ;

(in-package #:docfctory)


;; ----------------------------------------------------------------------
;; Global vars


(defparameter *outdir*        nil)
(defparameter *doc-template*  nil)
(defparameter *pdf-out*       nil)


;; ----------------------------------------------------------------------
;; Operation


;;; Get the contents of the controlling spreadsheet.
(defun control-data (filename sheetname)
  (cclet* ((workbook   (get-document filename))
           (worksheets #p(worksheets workbook))
           (worksheet  #p(item worksheets sheetname))
           (range      (used-range worksheet)))
    #p(value2 range)))


;;; Return a single row of ARRAY.
(defun extract-row (array row)
  (let ((width (array-dimension array 1)))
    (make-array width
                :displaced-to array
                :displaced-index-offset (* width row))))


(defconstant +wd-replace-all+    2)
(defconstant +wd-find-continue+  1)
(defconstant +wd-format-pdf+    17)


;;; Replace text in Word doc.
(defun word-replace-text (find orig-text new-text)
  #m(execute find orig-text nil nil nil nil nil t +wd-find-continue+ nil new-text))


;;; Non-permitted characters in a file name.
(defparameter *invalid-chars*
  '(#\/ #\< #\> #\" #\| #\? #\*))


;;; Check if filename is valid.
(defun validate-outfile (filename dump-text)
  (cond
   ;; Filename too long.
   ((> (length filename) 259)
    (progn
      (funcall dump-text (format nil "--> Kiemeneti fájlnév túl hosszú, ~a karakter! (~a) <--~%"
                                 (length filename) filename))
      nil))
   ;; Invalid character.
   ((find-if #'identity
             (mapcar #'(lambda (char)
                         (find char filename))
                     *invalid-chars*))
    (progn
      (funcall dump-text (format nil "--> Kiemeneti fájlnév illegális karaktert tartalmaz. (~a) <--~%"
                                 filename))
      nil))
   (t t)))


;;; Create document. Return NIL if filename was too long, otherwise return non-NIL.
(defun document (control filename-column documents dump-text)
  (let* ((outfile-raw  (concatenate 'string *outdir* (aref control filename-column)))
         (outfile-docx (concatenate 'string outfile-raw ".docx"))
         (outfile-pdf  (concatenate 'string outfile-raw ".pdf")))
    ;; If OUTFILE-DOCX is a valid filename:
    (when (validate-outfile outfile-docx dump-text)
      (cclet* ((document  #m(open documents *doc-template*))
               (find      #p(find #p(content document))))
        ;; Loop over the columns of the control array, perform replace operations in the document content.
        (loop for col from 0 below (array-dimension control 0) doing
              (word-replace-text find 
                                 (format nil "<~a>" (ccom:column (1+ col)))
                                 (aref control col)))
        ;; Save resulting document with new name as DOCX.
        #m(saveas2 document outfile-docx)
        (funcall dump-text (format nil "~a elmentve.~%" outfile-docx))
        ;; Also save it as PDF, if needed.
        (when *pdf-out*
          #m(saveas2 document outfile-pdf +wd-format-pdf+)
          (funcall dump-text (format nil "~a elmentve.~%" outfile-pdf)))
        ;; Close modified template.
        #m(close document nil)
        ;; Signal to the caller that validation passed.
        t))))


;;; Main functionality.
(defun docfctory (control-book control-sheet filename-column dump-text progress)
  (with-com-initialized
    (let* ((control  (control-data control-book control-sheet))
           (last-row (array-dimension control 0)))
      ;; Create a Word object (to speed up processing.
      (cclet* ((documents   #p(documents (com:create-object :progid "Word.Application")))
               (error-count 0))
        ;; Loop over rows of the control array.
        (loop for row from 1 below last-row
              for doc-control = (extract-row control row)
              doing (progn
                      ;; If document processing yields invalid filename, increase error counter.
                      (unless (document doc-control filename-column documents dump-text)
                        (incf error-count))
                      ;; Move the progress bar.
                      (funcall progress (* 100 (/ row (1- last-row))))))
        ;; If there were errors, make a special comment.
        (unless (zerop error-count)
          (funcall dump-text (format nil "Sikertelen mentések száma: ~a~%" error-count))))))
  ;; Process ends.
  (funcall dump-text (format nil "Mûvelet vége.~%")))
