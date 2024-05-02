(defsystem "docfctory"
  :description "Generate documents from control data in an XLSX"
  :author      "Denes Cselovszki <denes.cselovszki@gmail.com>"
  :version     "0.02"
  :depends-on  ("ccom")
;  :depends-on  ("alexandria")
  :serial      t
  :components  ((:file "package")
                (:file "docfctory")))
