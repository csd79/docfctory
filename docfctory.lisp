;;;; -*- Mode: Common-Lisp; Author: denes.cselovszky@gmail.com -*- 
                                                                              ;

(in-package #:docfctory)
(require "shell-objs")


;; ----------------------------------------------------------------------
;; Global vars


(defparameter *workdir*       "c:\\Users\\cselovszkid\\Downloads\\2024.04.01. TKig Gazdvez kinevmód\\")
(defparameter *control-book*  (concatenate 'string *workdir* "Illetményváltozás_TK_complete.xlsx"))
(defparameter *outdir*        (concatenate 'string *workdir* "out\\"))

#|(defparameter *doc-template*  (concatenate 'string *workdir* "Kinevezésmódosítás_tankerületi igazgató.docx"))
(defparameter *control-sheet* "Tankerületi igazgatók")
(defparameter *filename-col*  16)|#

(defparameter *doc-template*  (concatenate 'string *workdir* "Kinevezésmódosítás_gazdasági vezetõ.docx"))
(defparameter *control-sheet* "Gazdasági vezetõk")
(defparameter *filename-col*  16)

(defparameter *previous-workbook* "")
(defparameter *outdir-selected*   "")


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
(defun replace-text (find orig-text new-text)
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
              (replace-text find 
                            (format nil "<~a>" (ccom:column (1+ col)))
                            (aref control col)))
        #m(saveas2 document outfile-docx)
        #m(saveas2 document outfile-pdf +wd-format-pdf+)
        #m(close document nil)
        outfile-docx))))


;;; Main functionality.
(defun docfctory ()
  (let* ((control  (control-data *control-book* *control-sheet*))
         (last-row (array-dimension control 0)))
    (cclet* ((documents #p(documents (com:create-object :progid "Word.Application"))))
      (loop for row from 1 below last-row
            for doc-control = (extract-row control row)
            doing (print (document doc-control *filename-col* documents))))))


;;; Set global variables from GUI.
(defun init ()
  (setf *previous-workbook* ""
        *outdir-selected*   "")
  )


;;; Initialize and run the main fn.
(defun run (interface)
  (declare (ignore interface))
  (docfctory)
  )


;;; Exit (might be important with multiple running instances).
(defun exit-program ()
  )


;; ----------------------------------------------------------------------
;; GUI


(defun list-of-worksheets (filename)
  (cclet* ((sheets #p(worksheets (get-document filename)))
           (count  #p(count sheets)))
    (loop for i from 1 upto count collecting
          #p(name #p(item sheets i)))))


(defun file-directory (filename)
  (let ((raw-pathname (make-pathname
                       :host (pathname-host filename)
                       :directory (pathname-directory filename))))
    (namestring raw-pathname)))


(defun workbook-changed (interface)
  ;; Pathname string of the selected file.
  (let ((text (capi:text-input-pane-text (workbook-pane interface))))
    (if (string-equal (pathname-type text) "xlsx")
      ;; If the selected file is an '.xlsx':
      (unless (string-equal text *previous-workbook*)
        ;; If it is different from the previously selected '.xlsx'
        (setf *previous-workbook* text
              ;; Populate the worksheet selection pane with worksheet names.
              (capi:collection-items (worksheet-pane interface))
              (list-of-worksheets text))
        (worksheet-changed nil interface)
        ;; If output dir isn't selected yet, give it a value.
        (when (string= *outdir-selected* "")
          (setf (capi:text-input-pane-text (out-directory interface))
                (file-directory text)
                *outdir-selected* (file-directory text))))
      ;; If the selected file is of another type, empty two panes.
      (setf (capi:collection-items (worksheet-pane interface))
            '()
            (capi:collection-items (out-filename interface))
            '()))))


(defconstant +xl-to-left+          -4159)
(defconstant +xl-up+               -4162)
(defconstant +xl-values+           -4163)
(defconstant +xl-by-columns+           2)
(defconstant +xl-whole+                1)
(defconstant +xl-previous+             2)


(defun worksheet-changed (text interface)
  (declare (ignore text))
  (let* ((item     (capi:choice-selection (worksheet-pane interface)))
         (items    (capi:collection-items (worksheet-pane interface)))
         (filename (capi:text-input-pane-text (workbook-pane interface))))
    ;; Extract LABELS from the first row of selected workbook/worksheet.
    (cclet* ((sheets  #p(worksheets (get-document filename)))
             (sheet   #p(item sheets (elt items item)))
             (whole   #p(cells sheet))
             (top     #p(row #p(end whole +xl-up+)))
             (left    #p(column #p(end whole +xl-to-left+)))
             (from    (range sheet left top))
             (right   #p(column #m(find whole "*" from +xl-values+
                                        +xl-whole+ +xl-by-columns+ +xl-previous+)))
             (header  #p(value2 (range sheet 1 1 right 1)))
             (labels  (loop for c from 0 below right collecting
                            (aref header 0 c))))
      (setf (capi:collection-items (out-filename interface))
            labels))))


(capi:define-interface main ()
  ()
  (:panes
   (workbook-pane
    capi:text-input-pane
    :title "Vezérlõ táblázat"
    :accessor workbook-pane
    :buttons `(:browse-file (:pathname ,(sys:get-folder-path :my-documents)
                             :filter   "*.xlsx"
                             :filters  ("Excel táblázatok" "*.xlsx"
                                        "Minden fájl"      "*.*"))
               :ok          nil)
    :callback 'workbook-changed
    :callback-type :interface
    :change-callback 'workbook-changed
    :change-callback-type :interface)
   (worksheet-pane
    capi:option-pane
    :accessor worksheet-pane
    :title "Vezérlõ munkalap"
    :items '("")
    :selection-callback 'worksheet-changed
    )
   (out-filename
    capi:option-pane
    :accessor out-filename
    :title "Kimeneti fájlnév oszlop"
    :items '("")
    )
   (out-directory
    capi:text-input-pane
    :title "Kimeneti mappa"
    :text (namestring (system:get-folder-path :my-documents))
    :accessor out-directory
    :buttons `(:browse-file (:directory t)
               :ok          nil))
   (start-button
    capi:push-button-panel
    :items (list "Indítás")
    :layout-args '(:x-uniform-size-p t)
    :callback-type :interface
    :callbacks '(run)))
  (:layouts
   (default
    capi:column-layout
    '(workbook-pane worksheet-pane out-filename out-directory start-button)))
  (:default-initargs
   :title "docfctory v0.02"
   :destroy-callback 'exit-program
   :initial-focus 'workbook-pane
   :best-width 450
   :best-x 735
   :best-y 400))


;;; Start the GUI.
(defun start ()
  (init)
  (capi:display (make-instance 'main)))
