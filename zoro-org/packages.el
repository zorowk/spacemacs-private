;;; packages.el --- zoro-org layer packages file for Spacemacs.
;;
;; Copyright (c) 2012-2017 Sylvain Benner & Contributors
;;
;; Author:  <Administrator@PENGWENHAO>
;; URL: https://github.com/syl20bnr/spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

;;; Commentary:

;; See the Spacemacs documentation and FAQs for instructions on how to implement
;; a new layer:
;;
;;   SPC h SPC layers RET
;;
;;
;; Briefly, each package to be installed or configured by this layer should be
;; added to `zoro-org-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `zoro-org/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `zoro-org/pre-init-PACKAGE' and/or
;;   `zoro-org/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:

(defconst zoro-org-packages
  '(org
    deft
    org-pomodoro
    org-brain
    (blog-admin :location (recipe
                           :fetcher github
                           :repo "codefalling/blog-admin")))
  "The list of Lisp packages required by the zoro-org layer.

Each entry is either:

1. A symbol, which is interpreted as a package to be installed, or

2. A list of the form (PACKAGE KEYS...), where PACKAGE is the
    name of the package to be installed or loaded, and KEYS are
    any number of keyword-value-pairs.

    The following keys are accepted:

    - :excluded (t or nil): Prevent the package from being loaded
      if value is non-nil

    - :location: Specify a custom installation location.
      The following values are legal:

      - The symbol `elpa' (default) means PACKAGE will be
        installed using the Emacs package manager.

      - The symbol `local' directs Spacemacs to load the file at
        `./local/PACKAGE/PACKAGE.el'

      - A list beginning with the symbol `recipe' is a melpa
        recipe.  See: https://github.com/milkypostman/melpa#recipe-format")

(defun zoro-org/init-blog-admin ()
  (use-package blog-admin
    :defer t
    :commands blog-admin-start
    :init
    (progn
      ;; do your configuration here
      (setq blog-admin-backend-type 'hexo
            blog-admin-backend-path blog-admin-dir
            blog-admin-backend-new-post-with-same-name-dir nil
            blog-admin-backend-hexo-config-file "_config.yml"
            )
      (add-hook 'blog-admin-backend-after-new-post-hook 'find-file)
      )))

(defun zoro-org/post-init-org-brain()
  (with-eval-after-load 'org-brain
    (progn
      (setq org-brain-path "~/Dropbox/brain")
      (with-eval-after-load 'evil
        (evil-set-initial-state 'org-brain-visualize-mode 'emacs))
      :config
      (setq org-id-track-globally t)
      (setq org-id-locations-file "~/.emacs.d/.org-id-locations")
      (push '("b" "Brain" plain (function org-brian-goto-end)
              "* %i%?" :empty-lines 1) org-capture-templates)
      (setq org-brain-visualize-default-choices 'all)
      (setq org-brain-title-max-length 16)
      )))

(defun zoro-org/post-init-org-pomodoro ()
  (zorowk/pomodoro-notification))

(defun zoro-org/post-init-org()
  (add-hook 'org-mode-hook (lambda () (spacemacs/toggle-line-numbers-off)) 'append)
  (with-eval-after-load 'org
    (progn
      (spacemacs|disable-company org-mode)
      (spacemacs/set-leader-keys-for-major-mode 'org-mode
        "," 'org-priority)
      (require 'org-compat)
      (require 'org)
      (add-to-list 'org-modules 'org-habit)
      (require 'org-habit)

      (setq org-refile-use-outline-path 'file)
      (setq org-outline-path-complete-in-steps nil)
      (setq org-refile-targets
            '((nil :maxlevel . 4)
              (org-agenda-files :maxlevel . 4)))
      ;; config stuck project
      (setq org-stuck-projects
            '("TODO={.+}/-DONE" nil nil "SCHEDULED:\\|DEADLINE:"))

      (setq org-agenda-inhibit-startup t) ;; ~50x speedup
      (setq org-agenda-span 'day)
      (setq org-agenda-use-tag-inheritance nil) ;; 3-4x speedup
      (setq org-agenda-window-setup 'current-window)
      (setq org-log-done t)
      (setq org-startup-indented t)
      (setq org-html-validation-link nil)

      ;; 加密文章
      ;; "http://coldnew.github.io/blog/2013/07/13_5b094.html"
      ;; org-mode 設定
      (require 'org-crypt)

      ;; 當被加密的部份要存入硬碟時，自動加密回去
      (org-crypt-use-before-save-magic)

      ;; 設定要加密的 tag 標籤為 secret
      (setq org-crypt-tag-matcher "SECRET")

      ;; 避免 secret 這個 tag 被子項目繼承 造成重複加密
      ;; (但是子項目還是會被加密喔)
      (setq org-tags-exclude-from-inheritance (quote ("SECRET")))

      ;; 用於加密的 GPG 金鑰
      ;; 可以設定任何 ID 或是設成 nil 來使用對稱式加密 (symmetric encryption)
      (setq org-crypt-key nil)

      (setq org-todo-keywords
            (quote ((sequence "TODO(t)" "STARTED(s)" "|" "DONE(d!/!)")
                    (sequence "WAITING(w@/!)" "SOMEDAY(S)" "|" "CANCELLED(c@/!)" "MEETING(m)" "PHONE(p)"))))
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Org Clock;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;; Change task state to STARTED when clocking in
      (setq org-clock-in-switch-to-state "STARTED")
      ;; Save clock data and notes in the LOGBOOK drawer
      (setq org-clock-into-drawer t)
      (setq org-log-into-drawer t)
      ;; Removes clocked tasks with 0:00 duration
      (setq org-clock-out-remove-zero-time-clocks t) ;; Show the clocked-in task - if any - in the header line

      (setq org-tags-match-list-sublevels nil)

      (add-hook 'org-mode-hook '(lambda ()
                                  ;; keybinding for editing source code blocks
                                  ;; keybinding for inserting code blocks
                                  (local-set-key (kbd "C-c i s")
                                                 'zorowk/org-insert-src-block)))

      (require 'ox-publish)
      (setq org-latex-listings t)
      (add-to-list 'org-latex-packages-alist
                   '("AUTO" "inputenc" t))
      (add-to-list 'org-latex-classes '("ctexart" "\\documentclass[10pt]{ctexart}
                                        \\usepackage[slantfont, boldfont]{xeCJK}
                                        [NO-DEFAULT-PACKAGES]
                                        [PACKAGES]
                                        \\setCJKmainfont{Noto Sans CJK SC}
                                        \\parindent 2em
                                        \\setmainfont{Times New Roman}
                                        \\setsansfont{Times New Roman}
                                        \\setmonofont{Source Code Pro}
                                        \\usepackage[utf8]{inputenc}
                                        \\usepackage[T1]{fontenc}
                                        \\usepackage{fixltx2e}
                                        \\usepackage{graphicx}
                                        \\usepackage{longtable}
                                        \\usepackage{float}
                                        \\usepackage{wrapfig}
                                        \\usepackage{rotating}
                                        \\usepackage[normalem]{ulem}
                                        \\usepackage{amsmath}
                                        \\usepackage{textcomp}
                                        \\usepackage{marvosym}
                                        \\usepackage{wasysym}
                                        \\usepackage{amssymb}
                                        \\usepackage{booktabs}
                                        \\usepackage[colorlinks,linkcolor=black,anchorcolor=black,citecolor=black]{hyperref}
                                        \\tolerance=1000
                                        \\usepackage{listings}
                                        \\usepackage{xcolor}
                                        \\usepackage{color}
                                        \\usepackage{lstautogobble}
                                        \\usepackage{zi4}
                                        \\definecolor{bluekeywords}{rgb}{0.13, 0.13, 1}
                                        \\definecolor{greencomments}{rgb}{0, 0.5, 0}
                                        \\definecolor{redstrings}{rgb}{0.9, 0, 0}
                                        \\definecolor{graynumbers}{rgb}{0.5, 0.5, 0.5}
                                        \\defaultfontfeatures{Mapping=tex-text}
                                        \\XeTeXlinebreaklocale \"zh\"
                                        \\XeTeXlinebreakskip = 0pt plus 1pt minus 0.1pt
                                        \\lstset{autogobble,
                                                 columns=fullflexible,
                                                 showspaces=false,
                                                 showtabs=false,
                                                 breaklines=true,
                                                 showstringspaces=false,
                                                 breakatwhitespace=true,
                                                 escapeinside={(*@}{@*)},
                                                 commentstyle=\\color{greencomments},
                                                 keywordstyle=\\color{bluekeywords},
                                                 stringstyle=\\color{redstrings},
                                                 numberstyle=\\color{graynumbers},
                                                 basicstyle=\\ttfamily\\footnotesize,
                                                 frame=l,
                                                 framesep=12pt,
                                                 xleftmargin=12pt,
                                                 tabsize=4,
                                                 captionpos=b}
                                        [EXTRA]"
                                        ("\\section{%s}" . "\\section*{%s}")
                                        ("\\subsection{%s}" . "\\subsection*{%s}")
                                        ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                                        ("\\paragraph{%s}" . "\\paragraph*{%s}")
                                        ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))

      (setq org-latex-default-class "ctexart")
      (setq org-latex-pdf-process
            '("xelatex -interaction nonstopmode -shell-escape -output-directory %o %f"
	            "bibtex %b"
              "makeindex %b"
	            "xelatex -interaction nonstopmode --shell-escape -output-directory %o %f"
	            "xelatex -interaction nonstopmode -shell-escape -output-directory %o %f"
              "rm -rf %b.out %b.log %b.tex %b.bbl auto"))

      ;;reset subtask
      (setq org-default-properties (cons "RESET_SUBTASKS" org-default-properties))

      (setq org-startup-with-inline-images t)
      ;;(add-hook 'org-babel-after-execute-hook 'org-redisplay-inline-images)

      (setq org-plantuml-jar-path
            (expand-file-name "/usr/share/java/plantuml/plantuml.jar"))
      (setq org-ditaa-jar-path "/usr/share/java/ditaa/ditaa-0.11.jar")

      (org-babel-do-load-languages
       'org-babel-load-languages
       '((perl . t)
         (ruby . t)
         (dot . t)
         (js . t)
         (latex .t)
         (python . t)
         (emacs-lisp . t)
         (plantuml . t)
         (C . t)
         (ditaa . t)
         (gnuplot . t)))

      (require 'ox-md nil t)
      ;; copy from chinese layer
      (defadvice org-html-paragraph (before org-html-paragraph-advice
                                            (paragraph contents info) activate)
        "Join consecutive Chinese lines into a single long line without
         unwanted space when exporting org-mode to html."
        (let* ((origin-contents (ad-get-arg 1))
               (fix-regexp "[[:multibyte:]]")
               (fixed-contents
                (replace-regexp-in-string
                 (concat
                  "\\(" fix-regexp "\\) *\n *\\(" fix-regexp "\\)") "\\1\\2" origin-contents)))
          (ad-set-arg 1 fixed-contents)))

      ;; define the refile targets
      (setq org-agenda-file-note (expand-file-name "notes.org" org-agenda-dir))
      (setq org-agenda-file-gtd (expand-file-name "gtd.org" org-agenda-dir))
      (setq org-agenda-file-code-snippet (expand-file-name "snippet.org" org-agenda-dir))
      (setq org-default-notes-file (expand-file-name "gtd.org" org-agenda-dir))
      (setq org-agenda-files (list org-agenda-dir))

      (with-eval-after-load 'org-agenda
        (define-key org-agenda-mode-map (kbd "P") 'org-pomodoro)
        (spacemacs/set-leader-keys-for-major-mode 'org-agenda-mode
          "." 'spacemacs/org-agenda-transient-state/body)
        )

      ;; the %i would copy the selected text into the template
      ;;http://www.howardism.org/Technical/Emacs/journaling-org.html
      ;;add multi-file journal
      (setq org-capture-templates
            '(("t" "Todo" entry (file+headline org-agenda-file-gtd "Workspace")
               "* TODO [#B] %?\n  %i\n"
               :empty-lines 1)
              ("n" "notes" entry (file+headline org-agenda-file-note "Quick notes")
               "* %?\n  %i\n %U"
               :empty-lines 1)
              ("l" "Learn" entry (file+headline org-agenda-file-note "Learning")
               "* TODO [#B] %?\n  %i\n %U"
               :empty-lines 1)
              ("s" "Code Snippet" entry (file org-agenda-file-code-snippet)
               "* %?\t%^g\n#+BEGIN_SRC %^{language}\n\n#+END_SRC")
              ("w" "work" entry (file+headline org-agenda-file-gtd "Wisonic")
               "* TODO [#A] %?\n  %i\n %U"
               :empty-lines 1)
              ("p" "Protocol" entry (file+headline org-agenda-file-note "Chrome Content")
               "* %^{Title}\nSource: %u, %c\n #+BEGIN_QUOTE\n%i\n#+END_QUOTE\n\n\n%?"
               :empty-lines 1)
              ("L" "Protocol Link" entry (file+headline org-agenda-file-note "Chrome Links")
               "* %? [[%:link][%:description]] \nCaptured On: %U"
               :empty-lines 1)))

      ;;An entry without a cookie is treated just like priority ' B '.
      ;;So when create new task, they are default 重要且紧急
      (setq org-agenda-custom-commands
            '(
              ("w" . "Task Schedule")
              ("wa" "Important and urgent tasks" tags-todo "+PRIORITY=\"A\"")
              ("wb" "Important and not urgent tasks" tags-todo "-Weekly-Monthly-Daily+PRIORITY=\"B\"")
              ("wc" "Not important and urgent tasks" tags-todo "+PRIORITY=\"C\"")
              ("b" "Blog" tags-todo "BLOG")
              ("p" . "Project")
              ("pw" tags-todo "PROJECT+WORK+CATEGORY=\"Wisonic\"")
              ("pl" tags-todo "PROJECT+DREAM+CATEGORY=\"zorowk\"")
              ("W" "Weekly Review"
               ((stuck "") ;; review stuck projects as designated by org-stuck-projects
                (tags-todo "PROJECT") ;; review all projects (assuming you use todo keywords to designate projects)
                ))))

      (setq org-brain-path "~/Dropbox/brain")

      (setq org-confirm-babel-evaluate nil
            org-src-fontify-natively t
            org-src-tab-acts-natively t)
      (setq spaceline-org-clock-p t)

      (setq org-ref-default-bibliography '("~/Dropbox/bibliography/references.bib")
            org-ref-pdf-directory "~/Dropbox/bibliography/book"
            org-ref-bibliography-notes "~/Dropbox/bibliography/books.org")

      (setq bibtex-completion-bibliography "~/Dropbox/bibliography/references.bib"
            bibtex-completion-library-path "~/Dropbox/bibliography/book"
            bibtex-completion-notes-path "~/Dropbox/bibliography/bibnotes.org")

      (setq org-ref-open-pdf-function
            (lambda (fpath)
              (start-process "zathura" "*helm-bibtex-zathura*" "/usr/bin/zathura" fpath)))
      (setq powerline-height 20)

      ;; For Evil users
      (with-eval-after-load 'evil
        (evil-set-initial-state 'org-brain-visualize-mode 'emacs))
      :config
      (setq org-id-track-globally t)
      (setq org-id-locations-file "~/.emacs.d/.org-id-locations")
      (push '("b" "Brain" plain (function org-brain-goto-end)
              "* %i%?" :empty-lines 1) org-capture-templates)
      (setq org-brain-visualize-default-choices 'all)
      (setq org-brain-title-max-length 12)

      (defvar zoro-website-html-preamble
        "<div class='nav'>
           <ul>
             <li><a href='https://zorowk.github.io/'>博客</a></li>
             <li><a href='/index.html'>Wiki目录</a></li>
           </ul>
         </div>")

      (defvar zoro-website-html-blog-head
        "<link rel='stylesheet' href='css/site.css' type='text/css'/> \n
         <link rel=\"stylesheet\" type=\"text/css\" href=\"/css/worg.css\"/>")

            (setq org-publish-project-alist
            `(
              ("blog-notes"
               :base-directory "~/org-notes"
               :base-extension "org"
               :publishing-directory "~/org-notes/public_html/"

               :recursive t
               :html-head , zoro-website-html-blog-head
               :publishing-function org-html-publish-to-html
               :headline-levels 4       ; Just the default for this project.
               :auto-preamble t
               :exclude "gtd.org"
               :exclude-tags ("ol" "noexport")
               :section-numbers nil
               :html-preamble ,zoro-website-html-preamble
               :author "zorowk"
               :email "near.kingzero@gmail.com"
               :auto-sitemap t          ; Generate sitemap.org automagically...
               :sitemap-filename "index.org" ; ... call it sitemap.org (it's the default)...
               :sitemap-title "我的wiki"     ; ... with title 'Sitemap'.
               :sitemap-sort-files anti-chronologically
               :sitemap-file-entry-format "%t" ; %d to output date, we don't need date here
               )
              ("blog-static"
               :base-directory "~/org-notes"
               :base-extension "css\\|js\\|png\\|jpg\\|gif\\|pdf\\|mp3\\|ogg\\|swf"
               :publishing-directory "~/org-notes/public_html/"
               :recursive t
               :publishing-function org-publish-attachment
               )
              ("blog" :components ("blog-notes" "blog-static"))))

            (add-hook 'org-after-todo-statistics-hook 'zorowk/org-summary-todo)
            ;; used by zorowk/org-clock-sum-today-by-tags

            (define-key org-mode-map (kbd "s-p") 'org-priority)
            (spacemacs/set-leader-keys-for-major-mode 'org-mode
              "tl" 'org-toggle-link-display)
            (define-key evil-normal-state-map (kbd "C-c C-w") 'org-refile)

      ;; hack for org headline toc
      (defun org-html-headline (headline contents info)
        "Transcode a HEADLINE element from Org to HTML.
         CONTENTS holds the contents of the headline.  INFO is a plist
         holding contextual information."
        (unless (org-element-property :footnote-section-p headline)
          (let* ((numberedp (org-export-numbered-headline-p headline info))
                 (numbers (org-export-get-headline-number headline info))
                 (section-number (and numbers
                                      (mapconcat #'number-to-string numbers "-")))
                 (level (+ (org-export-get-relative-level headline info)
                           (1- (plist-get info :html-toplevel-hlevel))))
                 (todo (and (plist-get info :with-todo-keywords)
                            (let ((todo (org-element-property :todo-keyword headline)))
                              (and todo (org-export-data todo info)))))
                 (todo-type (and todo (org-element-property :todo-type headline)))
                 (priority (and (plist-get info :with-priority)
                                (org-element-property :priority headline)))
                 (text (org-export-data (org-element-property :title headline) info))
                 (tags (and (plist-get info :with-tags)
                            (org-export-get-tags headline info)))
                 (full-text (funcall (plist-get info :html-format-headline-function)
                                     todo todo-type priority text tags info))
                 (contents (or contents ""))
                 (ids (delq nil
                            (list (org-element-property :CUSTOM_ID headline)
                                  (org-export-get-reference headline info)
                                  (org-element-property :ID headline))))
                 (preferred-id (car ids))
                 (extra-ids
                  (mapconcat
                   (lambda (id)
                     (org-html--anchor
                      (if (org-uuidgen-p id) (concat "ID-" id) id)
                      nil nil info))
                   (cdr ids) "")))
            (if (org-export-low-level-p headline info)
                ;; This is a deep sub-tree: export it as a list item.
                (let* ((type (if numberedp 'ordered 'unordered))
                       (itemized-body
                        (org-html-format-list-item
                         contents type nil info nil
                         (concat (org-html--anchor preferred-id nil nil info)
                                 extra-ids
                                 full-text))))
                  (concat (and (org-export-first-sibling-p headline info)
                               (org-html-begin-plain-list type))
                          itemized-body
                          (and (org-export-last-sibling-p headline info)
                               (org-html-end-plain-list type))))
              (let ((extra-class (org-element-property :HTML_CONTAINER_CLASS headline))
                    (first-content (car (org-element-contents headline))))
                ;; Standard headline.  Export it as a section.
                (format "<%s id=\"%s\" class=\"%s\">%s%s</%s>\n"
                        (org-html--container headline info)
                        (org-export-get-reference headline info)
                        (concat (format "outline-%d" level)
                                (and extra-class " ")
                                extra-class)
                        (format "\n<h%d id=\"%s\">%s%s</h%d>\n"
                                level
                                preferred-id
                                extra-ids
                                (concat
                                 (and numberedp
                                      (format
                                       "<span class=\"section-number-%d\">%s</span> "
                                       level
                                       (mapconcat #'number-to-string numbers ".")))
                                 full-text)
                                level)
                        ;; When there is no section, pretend there is an
                        ;; empty one to get the correct <div
                        ;; class="outline-...> which is needed by
                        ;; `org-info.js'.
                        (if (eq (org-element-type first-content) 'section) contents
                          (concat (org-html-section first-content "" info) contents))
                        (org-html--container headline info)))))))
      )))

(defun zoro-org/post-init-deft ()
  (progn
    (setq deft-use-filter-string-for-filename t)
    (setq deft-recursive t)
    (setq deft-extension "org")
    (setq deft-directory deft-dir)))
;;; packages.el ends here
