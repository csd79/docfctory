#|
(asdf:load-system "comwrapper")
(use-package :comwrp)
|#


(defparameter *workdir*       "c:\\Users\\cselovszkid\\Downloads\\2024.04.01. TK igazgató, Gazd.vez. kinevezésmódosítások\\")
(defparameter *control-book*  (concatenate 'string *workdir* "Illetményváltozás_TK_complete.xlsx"))
(defparameter *outdir*        (concatenate 'string *workdir* "out\\"))

#|(defparameter *doc-template*  (concatenate 'string *workdir* "Kinevezésmódosítás_tankerületi igazgató.docx"))
(defparameter *control-sheet* "Tankerületi igazgatók")
(defparameter *title*         "tankerületi igazgató")|#

(defparameter *doc-template*  (concatenate 'string *workdir* "Kinevezésmódosítás_gazdasági vezetõ.docx"))
(defparameter *control-sheet* "Gazdasági vezetõk")
(defparameter *title*         "gazdasági vezetõ")



(defun control (book sheet)
  (with-xlsx (xlsx book); :read-only t)
    (select-sheet xlsx sheet)
    (with-used-range (xlsx last-col last-row) 
      (with-range (xlsx range 1 2 last-col last-row)
        (com-property range "Value2")))))


(defun outfile (control row title)
  (format nil "~aKinevezésmódosítás - ~a ~a, ~a"
          *outdir*
          (aref control row 2) ; name
          title
          (substitute #\_ #\/ 
                      (aref control row 0)))) ; ref number


(defconstant +wd-replace-all+    2)
(defconstant +wd-find-continue+  1)
(defconstant +wd-format-pdf+    17)


(defun replace-text (find orig-text new-text)
  (com-method find "Execute" orig-text nil nil nil nil nil t +wd-find-continue+ nil new-text))
  

(defun document (control row)
  (let* ((outfile-raw  (outfile control row *title*))
         (outfile-docx (concatenate 'string outfile-raw ".docx"))
         (outfile-pdf  (concatenate 'string outfile-raw ".pdf")))
    (with-app (word "Word.Application")
      (set-app-visibility word t)
      (comlet* ((documents (com-property word "Documents"))
                (document  (com-method documents "Open" *doc-template*))
                (content   (com-property document "Content"))
                (find      (com-property content "Find")))
        (loop for col from 0 below (array-dimension control 1) doing
              (replace-text find 
                            (format nil "<~a>" (comwrp::column (1+ col)))
                            (aref control row col)))
        (com-method document "SaveAs2" outfile-docx)
        (com-method document "SaveAs2" outfile-pdf +wd-format-pdf+)
        (com-method document "Close" nil)))))


(defun docfactory ()
  (let* ((control (control *control-book* *control-sheet*))
         (last-row (array-dimension control 0)))
    (loop for row from 0 below last-row doing
          (print (outfile control row *title*))
          (document control row))))
