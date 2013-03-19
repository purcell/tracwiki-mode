;;; tracwiki-mode.el --- Emacs Major mode for working with Trac

;; Copyright (C) 2013 Matthew Erickson <peawee@peawee.net>

;; Author: Matthew Erickson <peawee@peawee.net>
;; Maintainer: Matthew Erickson <peawee@peawee.net>
;; Created: March 13, 2013
;; Version: 0.1
;; Keywords: Trac, wiki, tickets

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; tracwiki-mode is a major mode for editing Trac-formatted text files
;; in GNU Emacs. tracwiki-mode is free software, licensed under the
;; GNU GPL.

(require 'xml-rpc)

;;; Constants
(defconst tracwiki-mode-version "0.1"
  "Tracwiki mode version number")

;;; Customizable Variables
(defgroup tracwiki nil
  "Major mode for editing text files and tickets from a Trac wiki."
  :prefix "tracwiki-"
  :group  'wp
  :link   '(url-link "http://peawee.net"))

(defcustom tracwiki-xmlrpc-url nil
  "Set to the Trac xmlrpc login URL. For example:
  http://site.com/trac/login/xmlrpc"
  :group 'tracwiki
  :type 'string)

(defcustom tracwiki-uri-types
  '("acap" "cid" "data" "dav" "fax" "file" "ftp" "gopher" "http" "https"
    "imap" "ldap" "mailto" "mid" "modem" "news" "nfs" "nntp" "pop" "prospero"
    "rtsp" "service" "sip" "tel" "telnet" "tip" "urn" "vemmi" "wais")
  "Link types for syntax highlighting of URIs."
  :group 'tracwiki
  :type 'list)

;;; Font Lock
(require 'font-lock)

(defvar tracwiki-italic-face 'tracwiki-italic-face
  "Face name to use for italics")
(defvar tracwiki-bold-face 'tracwiki-bold-face
  "Face name to use for bolded text")
(defvar tracwiki-header-face 'tracwiki-header-face
  "Face name to use for headers")
(defvar tracwiki-blockquote-face 'tracwiki-blockquote-face
  "Face name to use for blockquotes")

(defgroup tracwiki-faces nil
  "Faces used in Tracwiki mode"
  :group 'tracwiki
  :group 'faces)

(defface tracwiki-italic-face
  '((t (:inherit font-lock-variable-name-face :slant italic)))
  "Face for italic text."
  :group 'tracwiki-faces)

(defface tracwiki-bold-face
  '((t (:inherit font-lock-variable-name-face :weight bold)))
  "Face for bold text."
  :group 'tracwiki-faces)

(defface tracwiki-header-face
  '((t (:inherit font-lock-function-name-face :weight bold)))
  "Base face for headers."
  :group 'tracwiki-faces)

(defface tracwiki-blockquote-face
  '((t (:inherit font-lock-builtin-face)))
  "Face for list item markers."
  :group 'tracwiki-faces)

(defconst tracwiki-regex-header
  "^[ \t]*=[ \t]*.*"
  "Regular expression matching Trac headers")

(defconst tracwiki-regex-blockquote
  "^[ \t]*>[ \t]*.*"
  "Regular expression matching Trac blockquotes")

(defun tracwiki-match-code-blocks (last)
  "Match code blocks from point to LAST."
  (let (open lang body close all)
    (cond ((and (eq major-mode 'tracwiki-mode)
                (search-forward-regexp "^\\({{{\\)\\(\\w+\\)?$" last t))
           (beginning-of-line)
           (setq open (list (match-beginning 1) (match-end 1))
                 lang (list (match-beginning 2) (match-end 2)))
           (forward-line)
           (setq body (list (point)))
           (cond ((search-forward-regexp "^}}}$" last t)
                  (setq body (reverse (cons (1- (match-beginning 0)) body))
                        close (list (match-beginning 0) (match-end 0))
                        all (list (car open) (match-end 0)))
                  (set-match-data (append all open lang body close))
                  t)
                 (t nil)))
          (t nil))))

(defconst tracwiki-mode-font-lock-keywords
  (list
   (cons 'tracwiki-match-code-blocks 'tracwiki-blockquote-face)
   (cons tracwiki-regex-header 'tracwiki-header-face)
   (cons tracwiki-regex-blockquote 'tracwiki-blockquote-face)
   (cons "[0-9]+" 'font-lock-constant-face))
  "Font lock keywords used by TracWiki mode.")

(defun tracwiki-font-lock-extend-region ()
  "Extend the search region to include an entire block of text.
This helps improve font locking for block constructs such as pre blocks."
  ;; Avoid compiler warnings about these global variables from font-lock.el.
  ;; See the documentation for variable `font-lock-extend-region-functions'.
  (eval-when-compile (defvar font-lock-beg) (defvar font-lock-end))
  (save-excursion
    (goto-char font-lock-beg)
    (let ((found (or (re-search-backward "\n\n" nil t) (point-min))))
      (goto-char font-lock-end)
      (when (re-search-forward "\n\n" nil t)
        (beginning-of-line)
        (setq font-lock-end (point)))
      (setq font-lock-beg found))))

;;; Mode definition
(define-derived-mode tracwiki-mode text-mode "TracWiki"
  "Mode for Trac wiki text and tickets"
  ; Font locking
  (set (make-local-variable 'font-lock-defaults) 
       '(tracwiki-mode-font-lock-keywords))

  ; Multiline font lock
  (add-hook 'font-lock-extend-region-functions
            'tracwiki-font-lock-extend-region))

(provide 'tracwiki-mode)