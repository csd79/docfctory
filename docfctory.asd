(defsystem "docfctory"
  :description "Generate documents from control data in an XLSX"
  :author      "Denes Cselovszki <denes.cselovszki@gmail.com>"
  :version     "0.06"
  :depends-on  ("ccom")
  :serial      t
  :components  ((:file "package")
                (:file "fli-templates")
                (:file "util")
                (:file "docfctory")
                (:file "main-gui")
                (:file "running-gui")))
