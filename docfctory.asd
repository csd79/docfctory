(defsystem "docfctory"
  :description "Generate documents from control data in an XLSX"
  :author      "Denes Cselovszki <denes.cselovszki@gmail.com>"
  :version     "0.03"
  :depends-on  ("ccom")
  :serial      t
  :components  ((:file "package")
                (:file "docfctory")))
