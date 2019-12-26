 (defun my-copy-to-xclipboard(arg)
    (interactive "P")
    (cond
      ((not (use-region-p))
       (error "Nothing to yank to X-clipboard"))
      ((not (display-graphic-p))
       (let ((x-display
               (or (getenv "DISPLAY")
                   (when (getenv "TMUX")
                     (shell-command-to-string
                       "tmux_display=$(ps e $(pgrep -f \"tmux attach\") |\
                        grep -o \"DISPLAY=[^ ]*\") && printf ${tmux_display##*=}"))
                   (shell-command-to-string
                 "cd /tmp/.X11-unix && for x in X*; do printf \":${x#X}\"; break; done")))
             exit-code)
         (if (not (string-match ":" x-display))
           (error "No X-display found.")
          (cond
           ((zerop (setq exit-code
                     (shell-command-on-region (region-beginning) (region-end)
                       (format "xsel --display %s -i -b" x-display)))))
           ((= 127 exit-code)
            (error "Is program `xsel' installed?"))
           (*
            (error "xsel exited with code %s" exit-code))))))
      ((display-graphic-p)
         (condition-case err
           (progn
             (call-interactively 'clipboard-kill-ring-save))
           (error "Clipboard-failure."))))
    (message "Region yanked to X-clipboard")
    (when arg
      (kill-region  (region-beginning) (region-end)))
    (deactivate-mark))

  (defun my-cut-to-xclipboard()
    (interactive)
    (my-copy-to-xclipboard t))

  (defun my-paste-from-xclipboard()
    "Uses shell command `xsel -o' to paste from x-clipboard. With
  one prefix arg, pastes from X-PRIMARY, and with two prefix args,
  pastes from X-SECONDARY."
    (interactive)
    (if (display-graphic-p)
      (clipboard-yank)
     (let*
       ((opt (prefix-numeric-value current-prefix-arg))
        (opt (cond
         ((=  1 opt) "b")
         ((=  4 opt) "p")
         ((= 16 opt) "s"))))
      (insert (shell-command-to-string (concat "xsel -o -" opt))))))

  (global-set-key (kbd "C-w") 'my-cut-to-xclipboard)
  (global-set-key (kbd "M-w") 'my-copy-to-xclipboard)
  (global-set-key (kbd "C-y") 'my-paste-from-xclipboard)
