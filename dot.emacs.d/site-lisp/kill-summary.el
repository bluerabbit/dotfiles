;;; 
;;; kill-summary.el: キルリングの一覧を表示し選択ヤンクできるようにする
;;;
;;;     [2001/12/25] OSHIRO Naoki. <oshiro@mibai.tec.u-ryukyu.ac.jp>
;;;     ・一覧から選択し元編集バッファにヤンクできるようにした
;;;     [2001/08/05] OSHIRO Naoki. <oshiro@mibai.tec.u-ryukyu.ac.jp>
;;;     ・一覧表示のみを試しに作成
;;;

;;; ・yank-browse とかの名前のほうがいいかも（既に他でありますが．．．）
;;; ・参考
;;;   * yank,yank-pop (simple.el)
;;;   * electric buffer list モード (ebuff-menu.el) 

;;; [動作確認]
;;; ・Meadow-1.19
;;; ・Mule-19.34.1
;;; ・XEmacs-21.1p14

;;; [~/.emacs での読み込み設定]
;;;   ;;; kill-summary
;;;   (autoload 'kill-summary "kill-summary" nil t)
;;;   (define-key global-map "\ey" 'kill-summary)

;;; [使い方]
;;;   ・kill-ring 選択用バッファを別ウィンドウに表示
;;;   ・p,n (j,k) で前と次の候補を選択し元編集バッファヘヤンク
;;;     C-p (previous-line),C-n (next-line) なら候補を移動するだけ．
;;;     SPC で現在行を選択．C-v (scroll-up) でスクロール
;;;   ・ヤンク領域は yank-pop 風に次々に切り替わる
;;;   ・yank-pop との整合性を確保．M-y に割り当てればひとまず同じように使
;;;     える（まだリング動作はできない…）．
;;;   ・表示中は他の操作はできない．RET (newline) で選択決定．
;;;     中止 (q, C-g (keyboard-quit), C-xo (other-window)) 時は
;;;     ヤンク領域を消去
;;;   ・d で現在行のキルリングを即座に消去
;;;   ・'.' で現在行をヤンクポインタに設定
;;;   ・t で各キルの行数表示を切り替え
;;;   ・^,_ でサマリー高さを変更
;;;   ・初期ウィンドウ高さは ~/.emacs 中で次のように行なう（デフォルト値 10）．
;;;     (setq kill-summary-window-height 10)


(defvar kill-summary-buffer "*kill-ring*")
(defvar kill-summary-mode-map nil)
(defvar kill-summary-window-height 10)
(defvar kill-summary-show-line-number t)
(defvar kill-summary-newline-notation "^J")
(defvar kill-summary-version "0.1.3")

(if kill-summary-mode-map
    ()
  (let ((map (make-keymap)) (submap (make-keymap))
	(esc-prefix (where-is-internal 'ESC-prefix global-map 'non-ascii))
	(control-x-prefix (where-is-internal 'Control-X-prefix global-map 'non-ascii)))
  (cond ((fboundp 'set-keymap-default-binding)
	 (set-keymap-default-binding map 'kill-summary-undefined))
	(t (fillarray (car (cdr map)) 'kill-summary-undefined)))
;  (fillarray (car (cdr kill-summary-prefix-map)) 'kill-summary-undefined)
  (mapcar (lambda (x) (if x (define-key map x submap)))
	  (list esc-prefix control-x-prefix))
  (define-key map " "   'kill-summary-yank)
  (define-key map (concat esc-prefix "y") 'kill-summary-next-line-with-yank)
  (define-key map "n" 'kill-summary-next-line-with-yank)
  (define-key map "p" 'kill-summary-previous-line-with-yank)
  (define-key map "j" 'kill-summary-next-line)
  (define-key map "k" 'kill-summary-previous-line)
  (substitute-key-definition 'next-line 'kill-summary-next-line map global-map)
  (substitute-key-definition 'previous-line 'kill-summary-previous-line map global-map)
  (substitute-key-definition 'newline 'kill-summary-quit map global-map)
  (substitute-key-definition 'keyboard-quit 'kill-summary-interrupt map global-map)
  (substitute-key-definition 'other-window 'kill-summary-quit map global-map)
  (substitute-key-definition 'delete-window 'kill-summary-quit map global-map)
  (substitute-key-definition 'scroll-up 'scroll-up map global-map)
  (substitute-key-definition 'scroll-down 'scroll-down map global-map)
  (substitute-key-definition 'isearch-forward  'isearch-forward  map global-map)
  (substitute-key-definition 'isearch-backward 'isearch-backward map global-map)
  (define-key map "." 'kill-summary-set-yank-pointer)
  (define-key map "q" 'kill-summary-quit)
  (define-key map "d" 'kill-summary-delete)
  (define-key map "t" 'kill-summary-toggle-show-line-number)
  (define-key map "^" 'kill-summary-enlarge-window)
  (define-key map "_" 'kill-summary-shrink-window)
  (setq kill-summary-mode-map map)))

(defun kill-summary-delete ()
  "キルリングから現在行の候補を削除"
  (interactive)
  (let (n (max (length kill-ring)) (cb (current-buffer))
	  (zmacs-regions nil) (y (1- (count-lines (point-min) (point)))))
    (save-excursion
      (beginning-of-line)
      (if (re-search-forward "^ *\\([0-9]+\\):" 
			     (save-excursion (end-of-line) (point)) t)
	  (setq n (- max
		     (string-to-number
		      (buffer-substring (match-beginning 1) (match-end 1)))))))
    (if (not n) ()
      (if (eq (nth n kill-ring) (car kill-ring-yank-pointer))
	  (rotate-yank-pointer 1))
      (cond ((= (length kill-ring) 1)
	     (setq kill-ring nil))
	    (t (setq kill-ring (delq (nth n kill-ring) kill-ring))))
      (setq kill-summary-window-height (window-height))
      (kill-summary-make-summary))))

(defun kill-summary-set-yank-pointer ()
  "キルリングのポインタを一覧の現在行の候補に設定"
  (interactive)
  (let (n (max (length kill-ring)))
    (save-excursion
      (beginning-of-line)
      (if (re-search-forward "^ *\\([0-9]+\\):" 
			     (save-excursion (end-of-line) (point)) t)
	  (setq n (- max
		     (string-to-number
		      (buffer-substring (match-beginning 1) (match-end 1))))))
      (if (not n) ()
	(setq kill-ring-yank-pointer (nthcdr n kill-ring))
	(message "Set yank pointer.")))))

(defun kill-summary-yank ()
  "キルリング一覧から選択行をヤンク"
  (interactive)
  (let (n (max (length kill-ring)) (cb (current-buffer)) (pre-yank yanking)
	  (zmacs-regions nil) ;; for XEmacs
	  )
    (save-excursion
      (beginning-of-line)
      (setq n (nth (count-lines (point-min) (point)) kill-summary-list)))
    (if n (setq n (- max n)))
    (save-excursion
      ;(beginning-of-line)
      ;(if (re-search-forward "^ *\\([0-9]+\\):" 
      ;			     (save-excursion (end-of-line) (point)) t)
      ;	  (setq n (- max
      ;		     (string-to-number
      ;		      (buffer-substring (match-beginning 1) (match-end 1))))))
      (if (not n) ()
	(set-buffer (get-buffer-create parent-buffer))
	(if pre-yank
	    (progn
	      (delete-region (point) (mark t))
	      (set-marker (mark-marker) (point)))
	  (push-mark (point) nil))
	(setq kill-ring-yank-pointer (nthcdr n kill-ring))
	(insert (current-kill 0))
	(goto-char (prog1 (mark t) (set-marker (mark-marker) (point))))
	(if (< (point) (mark t))
	    (goto-char (prog1 (mark t) (set-marker (mark-marker) (point)))))
	(set-buffer cb)
	(setq yanking t)))))

(defun kill-summary-enlarge-window (arg)
  "一覧ウィンドウの高さを拡大（元編集ウィンドウを縮小）"
  (interactive "p")
  (let (all)
    (setq all (pos-visible-in-window-p (point-max)))
    (select-window parent-window)
    (if (and (or (not all) (< arg 0))
	     (> (- (window-height) arg) window-min-height))
	(enlarge-window (- arg))))
  (select-window (get-buffer-window kill-summary-buffer)))

(defun kill-summary-shrink-window (arg)
  "一覧ウィンドウの高さを縮小（元編集ウィンドウを拡大）"
  (interactive "p")
  (save-excursion
    (if (> (- (window-height) arg) window-min-height)
	(kill-summary-enlarge-window (- arg)))))

(defun kill-summary-next-line-with-yank (arg)
  "キルリング一覧の次の行に移動しその候補をヤンク
ARG は移動行数"
  (interactive "p")
  (kill-summary-next-line arg t))

(defun kill-summary-next-line (arg &optional yank)
  "キルリング一覧の次の行に移動
ARG は移動行数．YANK が nil でなければ移動後の候補行をヤンクする"
  (interactive "p")
  (forward-line arg)
  (beginning-of-line)
  (if (re-search-forward "^ *[0-9]+:" nil t)
      (progn
	(goto-char (match-end 0))
	(if yank (kill-summary-yank)))))

(defun kill-summary-previous-line-with-yank (arg)
  "キルリング一覧の前の行に移動しその候補をヤンク
ARG は移動行数"
  (interactive "p")
  (kill-summary-previous-line arg t))

(defun kill-summary-previous-line (arg &optional yank)
  "キルリング一覧の前の行に移動
ARG は移動行数．YANK が nil でなければ移動後の候補行をヤンクする"
  (interactive "p")
  (forward-line (- arg))
  (if (re-search-forward "^ *[0-9]+:" nil t)
      (progn
	(goto-char (match-end 0))
	(if yank (kill-summary-yank)))))

(defun kill-summary-toggle-show-line-number ()
  "キル項目の行数表示をトグル切替"
  (interactive)
  (setq kill-summary-window-height (window-height))
  (setq kill-summary-show-line-number (not kill-summary-show-line-number))
  (kill-summary-make-summary))

(defun kill-summary-make-summary ()
  "キルリング一覧を作成
作成後，現在の kill-ring-yank-pointer に対応した行へ移動する"
  (let ((max (length kill-ring)) n nyp str strtmp prev (ndsp 0) (lines "")
	(w (- (window-width) 6)) (hs (window-height (selected-window))) h
	buffer-read-only)
    (set-buffer kill-summary-buffer)
    (erase-buffer)
    (setq n max)
    (setq nyp (length (memq (car kill-ring-yank-pointer) kill-ring)))
    (setq kill-summary-list nil)
    (mapcar
     (lambda (x)
       (setq str (split-string x "\n"))
       (setq strtmp str)
       (if kill-summary-show-line-number
	   (setq lines (format "%3d" (length str))))
       (setq str (mapconcat (lambda (y) y) str " "))
       (if (or (string-match "^[ \t]*$" str) (string= str prev))
	   ()
	 (setq kill-summary-list (append kill-summary-list (list n)))
	 (insert (format "%2d:%s %s\n" n lines
			 (truncate-string-to-width
			  (mapconcat (lambda (y) y) strtmp
				     kill-summary-newline-notation) w)))
	 (setq prev str)
	 (setq ndsp (1+ ndsp)))
       (setq n (1- n)))
     kill-ring)
    (save-excursion
      (goto-char (point-max))
      (delete-backward-char 1))
    (set-buffer-modified-p nil)
    (if (zerop ndsp)
	(progn
	  (kill-summary-quit)
	  (error "There is no kill ring for display.")))
    (goto-char (point-min))
    (or (re-search-forward (format "^ *%s:" nyp) (point-max) t)
	(re-search-forward (format "\n *%s:" nyp) (point-max) t))
    (if (not window-popup) ()
      (setq h (min (1+ ndsp) kill-summary-window-height))
      (if (or (>= h hs) (eq (minibuffer-window) parent-window)) ()
	(setq h (max h window-min-height))
	(select-window parent-window)
	(enlarge-window (- hs h))
	(select-window (get-buffer-window kill-summary-buffer)))
      ndsp)))
  
(defun kill-summary ()
  "キルリングを一覧表示し選択できるようにする"
  (interactive)
  (let (buffer target-height pb pw pws pud pbm
	       (pop-up-windows t)
	       (one-window (one-window-p t)))
    (if (zerop (length kill-ring)) (error "kill ring is empty."))
    (setq pb (current-buffer)
	  pw (selected-window)
	  pws (window-start)
	  pud buffer-undo-list
	  pbm (buffer-modified-p))
    (set-buffer (get-buffer-create kill-summary-buffer))
    (kill-all-local-variables)
    (mapcar 'make-local-variable
	    '(truncate-lines print-escape-newlines
              yanking window-popup kill-summary-list
	      parent-buffer parent-window parent-window-start
	      parent-undo-list parent-buffer-modified-p))
    (setq window-popup nil)
    (if (and (not one-window)
	     (> (window-height (selected-window)) (* window-min-height 2)))
	(progn
	  (setq window-popup t)
	  (split-window)
	  (set-window-buffer (next-window) kill-summary-buffer)
	  (select-window (next-window)))
      (pop-to-buffer kill-summary-buffer)
      (setq window-popup t))
    (setq buffer-read-only t
	  parent-buffer pb
	  parent-window pw
	  parent-window-start pws
	  parent-undo-list pud
	  parent-buffer-modified-p pbm
	  yanking (eq last-command 'yank)
	  print-escape-newlines t
	  kill-summary-list nil
	  truncate-lines t))
  (kill-summary-make-summary)
  (use-local-map kill-summary-mode-map)
  (setq major-mode 'kill-summary
	mode-name "Kill Summary"))

(defun kill-summary-quit (&optional delete)
  "キルリング一覧表示の終了
DELETE が nil でない場合は元編集バッファへのヤンクを取り消す"
  (interactive)
  (let (p (pre-yank yanking)
	  (pb parent-buffer) (pw parent-window) (pws parent-window-start)
	  (pud parent-undo-list) (pbm parent-buffer-modified-p))
    (setq kill-summary-window-height (window-height (selected-window)))
    (set-buffer pb)
    (setq p (point))
    (if (and delete pre-yank)
	(progn
	  (delete-region p (mark t))
	  (setq buffer-undo-list pud)
	  (set-buffer-modified-p pbm)
	  (pop-mark))
      (if pre-yank (setq this-command 'yank))
      (goto-char p))
    (select-window pw)
    (set-window-start (selected-window) pws)
    (set-buffer kill-summary-buffer)
    (kill-all-local-variables)
    (delete-window (get-buffer-window kill-summary-buffer))
    (kill-buffer kill-summary-buffer)))

(defun kill-summary-yank-and-quit ()
  "キルリング一覧をヤンクしてから終了"
  (interactive)
  (kill-summary-yank)
  (kill-summary-quit))

(defun kill-summary-interrupt ()
  "キルリング一覧からの選択の中止"
  (interactive)
  (kill-summary-quit t))

(defun kill-summary-undefined ()
  "キルリング一覧での無定義キーバインド用関数"
  (interactive)
  ;(set-buffer kill-summary-parent-buffer)
  (ding)
  (message "*Kill summary mode* Type 'q' to exit."))

(provide 'kill-summary)

(defvar kill-summary-load-hook nil)
(run-hooks 'kill-summary-load-hook)

;;; end of kill-summary here.
