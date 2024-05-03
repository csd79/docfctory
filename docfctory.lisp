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
  (with-com-initialized
    (cclet* ((workbook   (get-document filename))
             (worksheets #p(worksheets workbook))
             (worksheet  #p(item worksheets sheetname))
             (range      (used-range worksheet)))
      #p(value2 range))))


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


;;; Create document.
(defun document (control filename-column documents)
  (let* ((outfile-raw  (concatenate 'string *outdir* (aref control filename-column)))
         (outfile-docx (concatenate 'string outfile-raw ".docx"))
         (outfile-pdf  (concatenate 'string outfile-raw ".pdf"))
         (length       (length outfile-docx)))
    (if (> length 259)
      (format t "Kiemeneti fájlnév túl hosszú, ~a karakter! (~a)~%" length outfile-docx)
      (cclet* ((document  #m(open documents *doc-template*))
               (find      #p(find #p(content document))))
        (loop for col from 0 below (array-dimension control 0) doing
              (word-replace-text find 
                            (format nil "<~a>" (ccom:column (1+ col)))
                            (aref control col)))
        #m(saveas2 document outfile-docx)
        (when *pdf-out*
          #m(saveas2 document outfile-pdf +wd-format-pdf+))
        #m(close document nil)
        outfile-docx))))


;;; Main functionality.
(defun docfctory (control-book control-sheet filename-column)
  (let* ((control  (control-data control-book control-sheet))
         (last-row (array-dimension control 0)))
    (cclet* ((documents #p(documents (com:create-object :progid "Word.Application"))))
      (loop for row from 1 below last-row
            for doc-control = (extract-row control row)
            doing (print (document doc-control filename-column documents))))))
