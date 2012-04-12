;;設定
;;(require 'git-status)
;;psvn.el http://www.xsteve.at/prg/emacs/psvn.el からの移植

(eval-when-compile (require 'cl))
(require 'vc-git)
(add-to-list 'vc-handled-backends 'Git)

(defvar git-status-state-mark-modeline t
  "modeline mark display or not") 

(defun git-status-update-modeline ()
  "Update modeline state dot mark properly"
  (when (and buffer-file-name (git-status-in-vc-mode?))
    (git-status-update-state-mark
     (git-status-interprete-state-mode-color
      (vc-git-state buffer-file-name)))))

(defun git-status-update-state-mark (color)
  (git-status-uninstall-state-mark-modeline)
  (git-status-install-state-mark-modeline color))

(defun git-status-uninstall-state-mark-modeline ()
  (setq mode-line-format
        (remove-if #'(lambda (mode) (eq (car-safe mode)
                                        'git-status-state-mark-modeline))
                   mode-line-format))
  (force-mode-line-update t))

(defun git-status-install-state-mark-modeline (color)
  (push `(git-status-state-mark-modeline
          ,(git-status-state-mark-modeline-dot color))
        mode-line-format)
  (force-mode-line-update t))

(defun git-substring-no-properties (string &optional from to)
  (if (fboundp 'substring-no-properties)
      (substring-no-properties string from to)
    (substring string (or from 0) to)))

(defun git-status-in-vc-mode? ()
  "Is vc-git active?"
  (interactive)
  (and vc-mode (string-match "^ GIT" (git-substring-no-properties vc-mode))))

(defun git-status-state-mark-modeline-dot (color)
  (propertize "    "
              'display
              `(image :type xpm
                      :data ,(format "/* XPM */
static char * data[] = {
\"18 13 3 1\",
\"  c None\",
\"+ c #000000\",
\". c %s\",
\"                  \",
\"       +++++      \",
\"      +.....+     \",
\"     +.......+    \",
\"    +.........+   \",
\"    +.........+   \",
\"    +.........+   \",
\"    +.........+   \",
\"    +.........+   \",
\"     +.......+    \",
\"      +.....+     \",
\"       +++++      \",
\"                  \"};"
                                     color)
                      :ascent center)))

(defsubst git-status-interprete-state-mode-color (stat)
  "Interpret vc-git-state symbol to mode line color"
  (case stat
    ('edited "tomato")
    ('up-to-date "GreenYellow")
    ('unknown  "gray")
    ('added    "blue")
    ('deleted  "red")
    ('unmerged "purple")
    (t "red")))

(defadvice vc-after-save (after git-status-vc-git-after-save activate)
    (when (git-status-in-vc-mode?) (git-status-update-modeline)))

(defadvice vc-find-file-hook (after git-status-vc-git-find-file-hook activate)
    (when (git-status-in-vc-mode?) (git-status-update-modeline)))

;; http://d.hatena.ne.jp/kitokitoki/20100824/p1#c1282700989 より。
;; ToDo あとで検証
(defadvice vc-git-checkin (after git-status-vc-git-after-checkin activate)
   (when (git-status-in-vc-mode?) (git-status-update-modeline)))


(provide 'git-status)