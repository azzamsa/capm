;;
;; 🍿 A collection of small QoL scripts

;;;###autoload
(defun today ()
  "Inserts the current date."
  (interactive)
  (insert (format-time-string "%A, %B %e, %Y")))

;;;###autoload
(defun now ()
  "Inserts the current date and time."
  (interactive)
  (insert (format-time-string "%F %H:%M")))

;;;###autoload
(defun aza-kill-other-buffers ()
  "Kill all buffers but current buffer and special buffers.
(Buffer that start with '*' and white space ignored)"
  (interactive)
  (when (y-or-n-p "Save and kill all other buffers ? ")
    (save-all-buffers-silently)
    (let ((killed-bufs 0))
      (dolist (buffer (delq (current-buffer) (buffer-list)))
        (let ((name (buffer-name buffer)))
          (when (and name (not (string-equal name ""))
                     (/= (aref name 0) ?\s)
                     (string-match "^[^\*]" name))
            (cl-incf killed-bufs)
            (funcall 'kill-buffer buffer))))
      (message "Saved & killed %d buffer(s)" killed-bufs))))

;;;###autoload
(defun file-manager-here ()
  "Open current directory with default file manager."
  (interactive)
  (message "Opening file manager in current directory...")
  ;; `xdg-open' will pick the default file manager
  (start-process "" nil "xdg-open" "."))

;;;###autoload
(defun terminal-here ()
  "Open a new terminal with the current directory as PWD."
  (interactive)
  (message "Opening terminal in %s" default-directory)
  ;; Need to use `expand-file-name` to expand `~` into a full path
  ;; Otherwise, termhere fallback to `$HOME`
  ;; The Rust version of `termhere' only works with `call-process-shell-command',
  ;; `async-shell-command', and `shell-command'. But the (b)ash version works
  ;; out of the box. Including with `start-process'.
  ;; See https://github.com/azzamsa/dotfiles/blob/master/xtool/src/termhere.rs
  (call-process-shell-command (concat "termhere " (expand-file-name default-directory))))
(defun save-all-buffers-silently ()
  (save-some-buffers t))

(defun save-buffers-and-clean ()
  "Save buffers and delete trailing whitespaces"
  (interactive)
  (basic-save-buffer)
  (delete-trailing-whitespace))

;;;###autoload
(defun +scratch-buffer ()
  "Toggle persistent scratch buffer"
  (interactive)
  (let ((filename camp-scratch-file))
    (if-let ((buffer (find-buffer-visiting filename)))
        (if (eq (selected-window) (get-buffer-window buffer))
            (delete-window)
          (if (get-buffer-window buffer)
              (select-window (get-buffer-window buffer))
            (pop-to-buffer buffer)))
      (progn
        (split-window-vertically)
        (other-window 1)
        (find-file filename)))))

(defun +find-file-other-window-vertically (f)
  "Edit a file in another window, split vertically."
  (interactive)
  (let ((split-width-threshold 0)
        (split-height-threshold nil))
    (find-file-other-window f)))

;;
;; Project

;;;###autoload
(defun camp/browse-in-emacsd ()
  "Browse files from `user-emacs-directory'."
  (interactive) (camp-project-browse user-emacs-directory))

;;;###autoload
(defun camp/find-file-in-emacsd ()
  "Find a file under `user-emacs-directory', recursively."
  (interactive) (camp-project-find-file user-emacs-directory))

(defun camp-project-find-file (dir)
  "Jump to a file in DIR (searched recursively). "
  (let* ((default-directory (file-truename dir))
         (pr (+project-from-dir dir))
         (root (project-root pr))
         (dirs (list root)))
    (if pr
        (project-find-file-in nil dirs pr nil)
      (call-interactively #'find-file))))

(defun camp-project-browse (dir)
  "Traverse a file structure starting linearly from DIR."
  (let ((default-directory (file-truename (expand-file-name dir))))
    (call-interactively #'find-file)))