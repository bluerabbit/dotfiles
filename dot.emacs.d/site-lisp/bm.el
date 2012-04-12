;;; bm.el  -- Visible bookmarks in buffer.

;; Copyrigth (C) 2000-2003  Jo Odland

;; Author: Jo Odland <jood@online.no>
;; Time-stamp:	<Thu Oct 30 10:56:39 2003  jood>
;; Version: $Id: bm.el,v 1.24 2003/10/30 09:57:31 jood Exp $
;; Keywords; bookmark, highlight, faces, persistent
;; URL: http://home.online.no/~jood/emacs/bm.el

;; Portions Copyright (C) 2002 by Ben Key
;; Updated by Ben Key <bkey1@tampabay.rr.com> on 2002-12-05
;; to add support for XEmacs


;; This file is *NOT* part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to the
;; Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.


;;; Commentary:

;;; Description:
;;
;;   This package was created because I missed the bookmarks from M$
;;   Visual Studio. I find that they provide an easy way to navigate
;;   in a buffer.
;;
;;   bm.el provides visible, buffer local, bookmarks and the ability
;;   to jump forward and backward to the next bookmark.
;;
;;   Features:
;;    - Different wrapping modes, see `bm-wrap-search' and 
;;      `bm-wrap-immediately'.
;;    - Setting bookmarks based on a regexp, `bm-bookmark-regexp' and 
;;      `bm-bookmark-regexp-region'.
;;    - Goto line position or start of line, `bm-goto-position'.
;;    - Bookmark persistence (see below).
;;    - Extract bookmarks into separate buffer, `bm-extract'.
;;
;;   The use of overlays for bookmarks was inspired by highline.el by
;;   Vinicius Jose Latorre <vinicius@cpqd.com.br>.
;;
;;   This package is developed and testet on GNU Emacs 21.2. It should
;;   work on all GNU Emacs 21.x and also on XEmacs 21.x with some
;;   limitations.
;;
;;   There are some incompabilities with lazy-lock when using
;;   fill-paragraph. All bookmark below the paragraph being filled
;;   will be lost. This issue can be resolved using the jit-lock-mode
;;   introduced in GNU Emacs 21.1
;;


;;; Installation:
;;
;;   To use bm.el, put it in your load-path and add
;;   the following to your .emacs
;;
;;   (require 'bm)
;;
;; or
;;
;;   (autoload 'bm-toggle   "bm" "Toggle bookmark in current buffer." t)
;;   (autoload 'bm-next     "bm" "Goto bookmark."                     t)
;;   (autoload 'bm-previous "bm" "Goto previous bookmark."            t)
;;


;;; Configuration:
;;
;;   To make it easier to use, assign the commands to some keys.
;;
;;   M$ Visual Studio key setup.
;;     (global-set-key (kbd "<C-f2>") 'bm-toggle)
;;     (global-set-key (kbd "<f2>")   'bm-next)
;;     (global-set-key (kbd "<S-f2>") 'bm-previous)
;;


;;; Persistence:
;;
;;   Bookmark persistence is achieved by storing bookmark data in a
;;   repository when a buffer is killed. The repository is saved to
;;   disk on exit. See `bm-repository-file'. The maximum size of the
;;   repository is controlled by `bm-repository-size'.
;;
;;   The buffer local variable `bm-buffer-persistence' decides if
;;   bookmarks in a buffer is persistent or not. Use the function
;;   `bm-toggle-buffer-persistence' to toggle bookmark persistence.
;;
;;   To have automagic bookmark persistence we need to add some
;;   functions to the following hooks. Insert the following code
;;   into your .emacs file:
;;
;;   ;; Loading the repository from file when on start up.
;;   (add-hook' after-init-hook 'bm-repository-load)
;;
;;   ;; Restoring bookmarks when on file find.
;;   (add-hook 'find-file-hooks 'bm-buffer-restore)
;;
;;   ;; Saving bookmark data on killing a buffer
;;   (add-hook 'kill-buffer-hook 'bm-buffer-save)
;;
;;   ;; Saving the repository to file when on exit.
;;   ;; kill-buffer-hook is not called when emacs is killed, so we
;;   ;; must save all bookmarks first.
;;   (add-hook 'kill-emacs-hook '(lambda nil
;; 	  		             (bm-buffer-save-all)
;; 			             (bm-repository-save)))
;;
;;   ;; Update bookmark repository when saving the file.
;;   (add-hook 'after-save-hook 'bm-buffer-save)
;;
;;   ;; Restore bookmarks when buffer is reverted.
;;   (add-hook 'after-revert-hook 'bm-buffer-restore)
;;
;;
;;   The after-save-hook and after-revert-hook is not necessary to use
;;   to achieve persistence, but it makes the bookmark data in
;;   repository more connected to the file state.



;;; Acknowledgements:
;;
;;  - Thanks to Ben Key for XEmacs support.
;;  - Thanks to Peter Heslin for notifying me on the incompability with
;;    lazy-lock.
;;  - Thanks to Christoph Conrad for adding support for goto line position
;;    in bookmarks and simpler wrapping.
;;


;;; Todo:
;;
;;  - Prevent the bookmark (overlay) from being extended when
;;    inserting (before, inside or after) the bookmark in XEmacs. This
;;    is due to the missing support for overlay hooks i XEmacs.
;;


;;; Code:
;;

;; xemacs needs overlay emulation package
(eval-and-compile
  (unless (fboundp 'overlay-lists)
    (require 'overlay)))


(defconst bm-version "$Id: bm.el,v 1.24 2003/10/30 09:57:31 jood Exp $"
  "RCS version of bm.el")


(defgroup bm nil
  "Toggle visible, buffer local, bookmarks."
  :link '(emacs-library-link :tag "Source Lisp File" "bm.el")
  :group 'faces
  :group 'editing
  :prefix "bm-")


(defcustom bm-face 'bm-face
  "*Specify face used to highlight the current line."
  :type 'face
  :group 'bm)


(defcustom bm-persistent-face 'bm-persistent-face
  "*Specify face used to highlight the current line when bookmark is
persistent."
  :type 'face
  :group 'bm)


(defcustom bm-priority 0
  "*Specify bm overlay priority.

Higher integer means higher priority, so bm overlay will have precedence
over overlays with lower priority.  *Don't* use negative number."
  :type 'integer
  :group 'bm)


(defface bm-face
  '((((class grayscale) (background light)) (:background "DimGray"))
    (((class grayscale) (background dark))  (:background "LightGray"))
    (((class color) (background light)) (:foreground "White" :background "DarkOrange1"))
    (((class color) (background dark))  (:foreground "Black" :background "DarkOrange1")))
  "Face used to highlight current line."
  :group 'bm)


(defface bm-persistent-face
  '((((class grayscale) (background light)) (:background "DimGray"))
    (((class grayscale) (background dark))  (:background "LightGray"))
    (((class color) (background light)) (:foreground "White" :background "DarkBlue"))
    (((class color) (background dark))  (:foreground "Black" :background "DarkBlue")))
  "Face used to highlight current line if bookmark is persistent."
  :group 'bm)


(defcustom bm-wrap-search t
 "*Specify if bookmark search should wrap.

nil, don't wrap when there are no more bookmarks.
t, wrap."
 :type 'boolean
 :group 'bm)


(defcustom bm-wrap-immediately t
  "*Specify if a wrap should be announced or not. Has only effect when
`bm-wrap-search' is t.

nil, announce before wrapping
t, don't announce."
  :type 'boolean
  :group 'bm)


(defcustom bm-recenter nil
  "*Specify if the buffer should be recentered around the bookmark
after a `bm-next' or a `bm-previous'."
  :type 'boolean
  :group 'bm)


(defcustom bm-goto-position t
  "*Specify if the `bm-next' and `bm-previous' should goto start of
line or to the position where the bookmark was set.

nil, goto start of line. 
t, goto position on line."
  :type 'boolean
  :group 'bm)


(defcustom bm-repository-file (expand-file-name "~/.bm-repository")
  "*Filename to store persistent bookmarks across sessions. If nil the
repository will not be persistent.."
  :type 'string
  :group 'bm)


(defcustom bm-repository-size 100
  "*Size of persistent repository. If nil then there if no limit."
  :type 'integer
  :group 'bm)


(defcustom bm-buffer-persistence nil
  "*Specify if bookmarks in a buffer should be persistent. Buffer local variable.

nil, don't save bookmarks
t, save bookmarks."
  :type 'boolean
  :group 'bm)
(make-variable-buffer-local 'bm-buffer-persistence)


(defvar bm-repository nil
  "Alist with all persistent bookmark data.")

(defvar bm-regexp-history nil
  "Bookmark regexp history.")

(defvar bm-wrapped nil
  "State variable to support wrapping.")


(defun bm-customize nil
  "Customize bm group"
  (interactive)
  (customize-group 'bm))


(defun bm-bookmark-add nil
  "Add bookmark at current line. Do nothing if no bookmark is
present."
  (if (not (bm-bookmark-at (point)))
      (let ((bookmark (make-overlay (bm-start-position)
				    (bm-end-position))))


        (overlay-put bookmark 'position (point-marker))
	(if bm-buffer-persistence
	    (overlay-put bookmark 'face bm-persistent-face)
	  (overlay-put bookmark 'face bm-face))
	(overlay-put bookmark 'evaporate t)
        (unless (featurep 'xemacs)
          (overlay-put bookmark 'priority bm-priority)
          (overlay-put bookmark 'modification-hooks '(bm-freeze))
          (overlay-put bookmark 'insert-in-front-hooks '(bm-freeze-in-front))
          (overlay-put bookmark 'insert-behind-hooks '(bm-freeze)))
	(overlay-put bookmark 'category 'bm)
	bookmark)))


(defun bm-bookmark-remove (&optional bookmark)
  "Remove bookmark at point or the bookmark specified with the
optional parameter."
  (if (null bookmark)
      (setq bookmark (bm-bookmark-at (point))))

  (if (bm-bookmarkp bookmark)
      (delete-overlay bookmark)))



;;;###autoload
(defun bm-toggle nil
  "Toggle bookmark at point."
  (interactive)
  (let ((bookmark (bm-bookmark-at (point))))
    (if bookmark
	(bm-bookmark-remove bookmark)
      (bm-bookmark-add))))


(defun bm-count nil
  "Count the number of bookmarks in buffer."
  (let ((bookmarks (bm-lists)))
    (+ (length (car bookmarks)) (length (cdr bookmarks)))))


(defun bm-start-position nil
  "Return the bookmark start position."
  (point-at-bol))


(defun bm-end-position nil
  "Return the bookmark end position."
  (min (point-max) (+ 1 (point-at-eol))))


(defun bm-freeze-in-front (overlay after begin end &optional len)
  "Prevent overlay from being extended to multiple lines. When
inserting in front of overlay move overlay forward."
  (if after
      (move-overlay overlay (bm-start-position) (bm-end-position))))


(defun bm-freeze (overlay after begin end &optional len)
  "Prevent overlay from being extended to multiple lines. When
inserting inside or behind the overlay, keep the original start
postion."
  (if after
      (let ((bm-start (overlay-start overlay)))
	(if bm-start
	    (move-overlay overlay
			  bm-start
			  (save-excursion
			    (goto-char bm-start)
			    (bm-end-position)))))))


(defun bm-equal (first second)
  "Compare two bookmarks. Return t if first is equal to second."
  (if (and (bm-bookmarkp first) (bm-bookmarkp second))
      (= (overlay-start first) (overlay-start second))
    nil))


(defun bm-bookmarkp (bookmark)
  "Return the bookmark if overlay is a bookmark."
  (if (and (overlayp bookmark) 
	   (string= (overlay-get bookmark 'category) "bm"))
      bookmark
    nil))


(defun bm-bookmark-at (point)
  "Get bookmark at point."
  (let ((overlays (overlays-at point))
	(bookmark nil))
    (while (and (not bookmark) overlays)
      (if (bm-bookmarkp (car overlays))
	  (setq bookmark (car overlays))
	(setq overlays (cdr overlays))))
    bookmark))


(defun bm-lists (&optional direction)
  "Return a pair of lists giving all the bookmarks of the current buffer.
The car has all the bookmarks before the overlay center;
the cdr has all the bookmarks after the overlay center.
A bookmark implementation of `overlay-list'."
  (overlay-recenter (point))
  (cond ((equal 'forward direction)
         (cons nil (remq nil (mapcar 'bm-bookmarkp (cdr (overlay-lists))))))
        ((equal 'backward direction)
         (cons (remq nil (mapcar 'bm-bookmarkp (car (overlay-lists)))) nil))
        (t
         (cons (remq nil (mapcar 'bm-bookmarkp (car (overlay-lists))))
               (remq nil (mapcar 'bm-bookmarkp (cdr (overlay-lists))))))))


;;;###autoload
(defun bm-next nil
  "Goto bookmark."
  (interactive)
  (if (= (bm-count) 0)
      (message "No bookmarks defined.")
    (let ((bm-list-forward (cdr (bm-lists 'forward))))
      ;; remove bookmark at point
      (if (bm-equal (bm-bookmark-at (point)) (car bm-list-forward))
          (setq bm-list-forward (cdr bm-list-forward)))

      (if bm-list-forward
          (bm-goto (car bm-list-forward))
        (if bm-wrap-search
            (if (or bm-wrapped bm-wrap-immediately)
                (progn
                  (goto-char (point-min))
                  (bm-next)
                  (message "Wrapped."))
              (setq bm-wrapped t)       ; wrap on next goto
              (message "Failed: No next bookmark."))
          (message "No next bookmark."))))))



;;;###autoload
(defun bm-previous nil
  "Goto previous bookmark."
  (interactive)
  (if (= (bm-count) 0)
      (message "No bookmarks defined.")
  (let ((bm-list-backward (car (bm-lists 'backward))))
    ;; remove bookmark at point
    (if (bm-equal (bm-bookmark-at (point)) (car bm-list-backward))
        (setq bm-list-backward (cdr bm-list-backward)))

      (if bm-list-backward
          (bm-goto (car bm-list-backward))
        (if bm-wrap-search
            (if (or bm-wrapped bm-wrap-immediately)
                (progn
                  (goto-char (point-max))
                  (bm-previous)
                  (message "Wrapped."))
              (setq bm-wrapped t)       ; wrap on next goto
              (message "Failed: No previous bookmark."))
          (message "No previous bookmark."))))))


(defun bm-remove-all nil
  "Delete all visible bookmarks in current buffer."
  (interactive)
  (let ((bookmarks (bm-lists)))
    (mapc 'bm-bookmark-remove (append (car bookmarks) (cdr bookmarks)))))


(defun bm-toggle-wrapping nil
  "Toggle wrapping on/off, when searching for next bookmark."
  (interactive)
  (setq bm-wrap-search (not bm-wrap-search))
  (if bm-wrap-search
      (message "Wrapping on.")
    (message "Wrapping off.")))


(defun bm-goto (bookmark)
  "Goto specified bookmark."
  (if (bm-bookmarkp bookmark)
      (progn
        (if bm-goto-position
            (goto-char (overlay-get bookmark 'position))
          (goto-char (overlay-start bookmark)))
        (setq bm-wrapped nil)           ; turn off wrapped state
	(if bm-recenter
	    (recenter)))
    (message "Bookmark not found.")))


(defun bm-bookmark-regexp nil
  "Set bookmark on lines that matches regexp."
  (interactive)
  (bm-bookmark-regexp-region (point-min) (point-max)))


(defun bm-bookmark-regexp-region (beg end)
  "Set bookmark on lines that matches regexp in region."
  (interactive "r")
  (let ((regexp (read-from-minibuffer "regexp: " nil nil nil 'bm-regexp-history))
        (count 0))
    (save-excursion
      (goto-char beg)
      (while (re-search-forward regexp end t)
	(bm-bookmark-add)
        (setq count (1+ count))
	(forward-line 1)))
    (message "%d bookmark(s) created." count)))


;; (defun bm-bookmark-line (line)
;;   "Set a bookmark on the specified line."
;;   (interactive)
;;   (let ((lines (count-lines (point-min) (point-max))))
;;     (save-excursion
;;       (if (> line lines)
;;           (message "Unable to set bookmerk at line %d. Only %d lines in buffer" line lines)
;;         (goto-line line)
;;         (bm-bookmark-add)))))
  

(defun bm-extract nil
  "Extract bookmarked lines to the *bookmarks* buffer."
  (interactive)
  (if (= (bm-count) 0)
      (message "No bookmarks defined.")
    (let* ((bookmarks (bm-lists))
	   (lines (mapconcat
		   '(lambda (bm)
		      (format 
		       "%4d: %s" 
		       (count-lines (point-min) (overlay-start bm))
		       (buffer-substring-no-properties (overlay-start bm) (overlay-end bm))))
		   (append (reverse (car bookmarks)) (cdr bookmarks)) "")))
      ;; set output buffer
      (with-output-to-temp-buffer "*bookmarks*"
	(save-excursion
	  (set-buffer standard-output)
	  (insert lines))))))


(defun bm-toggle-buffer-persistence nil
  "Toggle if a buffer has persistent bookmarks or not."
  (interactive)
  (if bm-buffer-persistence
      ;; turn off
      (progn
	(setq bm-buffer-persistence nil)
	(bm-repository-remove (buffer-file-name)) ; remove from repository
	(message "Bookmarks in buffer are not persistent"))
    ;; turn on
    (setq bm-buffer-persistence (not bm-buffer-persistence))
    (bm-buffer-save)			; add to repository
    (message "Bookmarks in buffer are persistent"))

  ;; change color on bookmarks
  (let ((bookmarks (bm-lists)))
    (mapc '(lambda (bookmark)
	     (if bm-buffer-persistence
		 (overlay-put bookmark 'face bm-persistent-face)
	       (overlay-put bookmark 'face bm-face))) 
	  (append (car bookmarks) (cdr bookmarks)))))


(defun bm-buffer-restore nil
  "Restore bookmarks saved in the repository for the current buffer."
  (interactive)
  (if (assoc (buffer-file-name) bm-repository)
      (let* ((buffer-data (assoc (buffer-file-name) bm-repository))
	     (size (cdr (assoc 'size buffer-data)))
	     (timestamp (cdr (assoc 'timestamp buffer-data)))
	     (positions (cdr (assoc 'positions buffer-data))))
      
	;; validate buffer size
	(if (equal size (point-max))
	    ;; restore bookmarks
	    (save-excursion
	      ;; set buffer persistent
	      (setq bm-buffer-persistence t)
	      
	      (while positions
		(goto-char (car positions))
		(bm-bookmark-add)
		(setq positions (cdr positions)))

	      (message "%d bookmark(s) restored." (bm-count)))
	
	  ;; size mismatch
	  (bm-repository-remove (buffer-file-name))
	  (message "Buffersize mismatch. Unable to restore bookmarks.")))
    (if (interactive-p) (message "No bookmarks in repository."))))


(defun bm-buffer-save nil
  "Save all bookmarks in repository."
  (interactive)
  (if bm-buffer-persistence
      (let ((buffer-data 
	     (list 
	      (buffer-file-name)
	      (cons 'size (point-max))
	      (cons 'timestamp (current-time))
	      (cons 'positions 
		    (let ((bookmarks (bm-lists)))
		      (mapcar '(lambda (bm)
				 (marker-position (overlay-get bm 'position)))
			      (append (car bookmarks) (cdr bookmarks))))))))
	;; remove if exists
	(bm-repository-remove (car buffer-data))

	;; add if there exists bookmarks
	(let ((count (length (cdr (assoc 'positions buffer-data))))) 
	  (if (> count 0)
	      (bm-repository-add buffer-data))
	  (if (interactive-p)
	      (message "%d bookmark(s) saved to repository." count))))
    
    (if (interactive-p)
	(message "Bookmarks in buffer are not persistent."))))


(defun bm-buffer-save-all nil
  "Save bookmarks in all buffers."
  (save-current-buffer
    (mapc '(lambda (buffer)
	     (set-buffer buffer)
	     (bm-buffer-save))
	  (buffer-list))))


(defun bm-repository-add (data)
  "Add data for a buffer to the repository."
  ;; appending to list, makes the list sorted by time
  (setq bm-repository (append bm-repository (list data)))
  
  ;; remove oldest element if repository is too large
  (while (and bm-repository-size
	      (> (length bm-repository) bm-repository-size))
	(setq bm-repository (cdr bm-repository))))


(defun bm-repository-remove (key)
  "Remove data for a buffer from the repository."
  (let ((repository nil))
    (if (not (assoc key bm-repository))
	;; don't exist in repository, do nothing
	nil
      ;; remove all occurances
      (while bm-repository
	(if (not (equal key (car (car bm-repository))))
	    (setq repository (append repository (list (car bm-repository)))))
	(setq bm-repository (cdr bm-repository)))
      (setq bm-repository repository))))


(defun bm-repository-load nil 
  "Load the repository from the file specified by `bm-repository-file'."
  (if (and bm-repository-file 
	   (file-readable-p bm-repository-file))
      (setq bm-repository 
	    (with-current-buffer (find-file-noselect bm-repository-file)
	      (goto-char (point-min))
	      (read (current-buffer))))))


(defun bm-repository-save nil 
  "Save the repository to the file specified by `bm-repository-file'."
  (if (and bm-repository-file
	   (file-writable-p bm-repository-file))
      (with-current-buffer (find-file-noselect bm-repository-file)
	(erase-buffer)
	(insert ";; bm.el -- persistent bookmarks. ")
	(insert "Do not edit this file.\n")
	(prin1 bm-repository (current-buffer))
	(save-buffer))))


(defun bm-repository-empty nil
  "Empty the repository."
  (interactive)
  (setq bm-repository nil))


;; bm.el ends here
(provide 'bm)
