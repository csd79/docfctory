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

(defun get-document (fullname)
  (com::get-object fullname :riid 'com::i-dispatch))


;;; Get the contents of the controlling spreadsheet.
(defun control-data (filename sheetname)
  (cclet* ((workbook   (get-document filename))
;           (worksheets ?('worksheets workbook))
;           (worksheet  ?('item worksheets sheetname))
           (worksheets (?worksheets workbook))
           (worksheet  (?item worksheets sheetname))
           (range      (used-range worksheet)))
;    ?('value2 range)))
    (?value2 range)))


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
  (!execute find orig-text nil nil nil nil nil t +wd-find-continue+ nil new-text))


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
      (cclet* ((document  (!open documents *doc-template*))
;               (find      ?('find ?('content document))))
               (find      (?find (?content document))))
        ;; Loop over the columns of the control array, perform replace operations in the document content.
        (loop for col from 0 below (array-dimension control 0) doing
              (word-replace-text find 
;                                 (format nil "<~a>" (ccom:column (1+ col)))
                                 (format nil "<~a>" (column (1+ col)))
                                 (aref control col)))

; C:\Users\cselovszkid\docfctory\Szombathelyi_TK_köznevelési intézmények_ell.xlsx
        ;; Loop over shapes
;        (cclet* ((shapes ?('shapes document))
;                 (scount ?('count shapes)))
        (cclet* ((shapes (?shapes document))
                 (scount (?count shapes)))
          (loop for i from 1 upto scount doing
                (cclet* ((shape (!item shapes i))
#|                         (frame ?('textframe shape))
                         (has   ?('hastext frame))
                         (range (unless (zerop has) ?('textrange frame)))
                         (find  (when range ?('find range))))|#
                         (frame (?textframe shape))
                         (has   (?hastext frame))
                         (range (unless (zerop has) (?textrange frame)))
                         (find  (when range (?find range))))
                  (when find
                    (loop for col from 0 below (array-dimension control 0) doing
                          (word-replace-text find 
;                                             (format nil "<~a>" (ccom:column (1+ col)))
                                             (format nil "<~a>" (column (1+ col)))
                                             (aref control col)))))))

        
        ;; Save resulting document with new name as DOCX.
        (!saveas2 document outfile-docx)
        (funcall dump-text (format nil "~a elmentve.~%" outfile-docx))
        ;; Also save it as PDF, if needed.
        (when *pdf-out*
          (!saveas2 document outfile-pdf +wd-format-pdf+)
          (funcall dump-text (format nil "~a elmentve.~%" outfile-pdf)))
        ;; Close modified template.
        (!close document nil)
        ;; Signal to the caller that validation passed.
        t))))


;;; Main functionality.
(defun docfctory (control-book control-sheet filename-column dump-text progress)
  (with-com-initialized
    (let* ((control  (control-data control-book control-sheet))
           (last-row (array-dimension control 0)))
      ;; Create a Word object (to speed up processing.
;      (cclet* ((documents   ?('documents (com:create-object :progid "Word.Application")))
      (cclet* ((documents   (?documents (com:create-object :progid "Word.Application")))
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
