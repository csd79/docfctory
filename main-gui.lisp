;;;; -*- Mode: Common-Lisp; Author: denes.cselovszky@gmail.com -*- 
                                                                              ;

(in-package #:docfctory)
(require "shell-objs")


;; ----------------------------------------------------------------------
;; Global vars


(defparameter *previous-workbook* "")
(defparameter *outdir-selected*   "")


;; ----------------------------------------------------------------------
;; GUI


;;; Callback fn for whenever WORKBOOK-PANE is set.
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
        ;; If output dir isn't selected yet, initialize it and doc-template.
        (when (string= *outdir-selected* "")
          ;; Initialize output-dir.
          (setf (capi:text-input-pane-text (out-directory interface))
                (file-directory text)
                ;; Initialize doc-template.
                (capi:text-input-pane-text (doc-template interface))
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


;;; Callback fn for whenever WORKSHEET-PANE is set.
(defun worksheet-changed (text interface)
  (declare (ignore text))
  ;; Extract the selected workbook and worksheet.
  (let* ((item     (capi:choice-selection (worksheet-pane interface)))
         (items    (capi:collection-items (worksheet-pane interface)))
         (filename (capi:text-input-pane-text (workbook-pane interface))))
    ;; Extract LABELS from the first row of selected workbook/worksheet.
    (with-com-initialized
      (cclet* ((sheets  #p(worksheets (get-document filename)))
               (sheet   #p(item sheets (elt items item)))
               (whole   #p(cells sheet))
               (top     #p(row #p(end whole +xl-up+)))
               (left    #p(column #p(end whole +xl-to-left+)))
               (from    (range sheet left top))
               (right   #p(column #m(find whole "*" from +xl-values+
                                          +xl-whole+ +xl-by-columns+ +xl-previous+)))
               (header  #p(value2 (range sheet 1 1 right 1)))
               (strings (loop for c from 0 below right collecting
                              (aref header 0 c))))
        ;; Populate the OUT-FILENAME pane's list of items with the header strings.
        (setf (capi:collection-items (out-filename interface))
              strings)))))


;;; Extract contents of all fields on the main interface.
(defun extract-mainif-fields (interface)
  (let ((sheet  (capi:choice-selection (worksheet-pane interface)))
        (sheets (capi:collection-items (worksheet-pane interface))))
    (let ((control-book    (capi:text-input-pane-text (workbook-pane interface)))
          (control-sheet   (elt sheets sheet))
          (filename-column (capi:choice-selection (out-filename interface)))
          (doc-template    (capi:text-input-pane-text (doc-template interface)))
          (outdir          (capi:text-input-pane-text (out-directory interface)))
          (pdf-out         (capi:button-selected (pdf-out interface))))
      (values control-book
              control-sheet
              filename-column
              doc-template
              outdir
              pdf-out))))


;;; Display error message popup and wait for confirmation.
(defun error-message-and-wait (message)
  (capi:display-message message))


;;; Validate each data field of the main interface (except for OUT-FILENAME and PDF-OUT).
(defun validate-and-signal-mainif (control-book control-sheet doc-template outdir)
  (block amiss
    (flet ((validate (value fn error-msg)
             (unless (funcall fn value)
               (error-message-and-wait error-msg)
               (return-from amiss nil))))
      (mapc #'validate
            (list control-book doc-template outdir)
            (list #'probe-file2 #'probe-file2 #'probe-directory)
            (list "A kiválasztott vezérlõ táblázat nem található."
                  "A kiválasztott dokumentumsablon nem található."
                  "A kiválasztott kimeneti mappa nem található."))
      (with-com-initialized
        (cclet* ((sheets #p(worksheets (get-document control-book)))
                 (sheet  #p(item sheets control-sheet)))
          (validate sheet #'identity "A kiválasztott vezérlõ munkalap nem található.")
          ;; Everything is valid:
          t)))))


;;; Callback fn for START-BUTTON: initialize global vars and run the main fn.
(defun run (interface)
  (multiple-value-bind (control-book control-sheet filename-column doc-template outdir pdf-out)
      (extract-mainif-fields interface)
    ;; Validate some data before starting.
    (when (validate-and-signal-mainif control-book control-sheet doc-template outdir)
      ;; Set up global vars.
      (let ((*outdir*       outdir)
            (*doc-template* doc-template)
            (*pdf-out*      pdf-out))
        ;; Call progress GUI.
        (run-progress control-book control-sheet filename-column)))))


;;; Exit (might be important with multiple running instances).
(defun exit-program () )


;;; Main GUI.
(capi:define-interface main ()
  ()
  (:panes
   ;; Workbook selection pane.
   (workbook-pane
    capi:text-input-pane
    :title "Vezérlõ táblázat"
    :accessor workbook-pane
    :buttons `(:browse-file
               (:pathname ,(sys:get-folder-path :my-documents)
                :if-does-not-exist :prompt
                :filter   "*.xlsx"
                :filters  ("Excel táblázatok" "*.xlsx"
                           "Minden fájl"      "*.*"))
               :ok          nil)
    :callback 'workbook-changed
    :callback-type :interface
    :change-callback 'workbook-changed
    :change-callback-type :interface)
   ;; Worksheet selection pane.
   (worksheet-pane
    capi:option-pane
    :accessor worksheet-pane
    :title "Vezérlõ munkalap"
    :items '("")
    :selection-callback 'worksheet-changed
    )
   ;; Selection pane for the source of the output files.
   (out-filename
    capi:option-pane
    :accessor out-filename
    :title "Kimeneti fájlnév oszlop"
    :items '("")
    )
   ;; Template document selection pane.
   (doc-template
    capi:text-input-pane
    :title "Dokumentumsablon"
    :text (namestring (system:get-folder-path :my-documents))
    :accessor doc-template
    :buttons `(:browse-file
               (:filter   "*.docx"
                :if-does-not-exist :prompt
                :filters  ("Word dokumentumok" "*.docx"
                           "Minden fájl"      "*.*"))
               :ok          nil))
   ;; Output directory selection pane.
   (out-directory
    capi:text-input-pane
    :title "Kimeneti mappa"
    :text (namestring (system:get-folder-path :my-documents))
    :accessor out-directory
    :buttons `(:browse-file (:directory t
                             :if-doesn-not-exist :prompt)
               :ok          nil))
   ;; Check button to prescribe if saving .pdf copies is needed or not.
   (pdf-out
    capi:check-button
    :text "Mentés .pdf formátumban is"
    :accessor pdf-out)
   ;; Starting the process.
   (start-button
    capi:push-button-panel
    :items (list "Indítás")
    :layout-args '(:x-uniform-size-p t)
    :callback-type :interface
    :callbacks '(run)))
  (:layouts
   (default
    capi:column-layout
    '(workbook-pane worksheet-pane out-filename doc-template out-directory pdf-out start-button)))
  (:default-initargs
   :title "docfctory v0.06"
   :destroy-callback 'exit-program
   :initial-focus 'workbook-pane
   :best-width 450
   :best-x 735
   :best-y 400))


;;; Initialize some global vars before displaying the GUI.
(defun init ()
  (setf *previous-workbook* ""
        *outdir-selected*   ""))


;;; Check if application is registered.
(defun verify-app-present (app-progid app-name)
  (with-com-initialized
    (handler-case
        (com:create-object :progid app-progid)
      (error (e) (progn
                   (error-message-and-wait (format nil "~a alkalmazás nem található." app-name))
                   nil)))))


;;; Start the GUI.
(defun start ()
  ;; Check if Word and Excel is registered.
  (and (verify-app-present "Excel.Application" "Excel")
       (verify-app-present "Word.Application" "Word"))
    ;; Initialize some global vars.
    (progn
      (init)
      ;; Start main GUI.
      (capi:display (make-instance 'main))))
