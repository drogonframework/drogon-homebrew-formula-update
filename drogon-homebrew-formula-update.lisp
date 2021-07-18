;;;; drogon-homebrew-formula-update.lisp
;;
;; Copyright (C) 2021, Cocobit Software, Rafał Bugajewski.
;; All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;;
;;     * Redistributions of source code must retain the above
;;       copyright notice, this list of conditions and the following
;;       disclaimer.
;;     * Redistributions in binary form must reproduce the above
;;       copyright notice, this list of conditions and the following
;;       disclaimer in the documentation and/or other materials
;;       provided with the distribution.
;;     * Neither the name of Cocobit Software nor the names of its
;;       contributors may be used to endorse or promote products
;;       derived from this software without specific prior written
;;       permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
;; FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL COCOBIT
;; SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
;; EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
;; PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
;; PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
;; OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
;; USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
;; DAMAGE.
;;
;;; Commentary:
;;
;; Drogon Homebrew Formula Updater
;;
;;; Code:

(in-package #:drogon-homebrew-formula-update)

(defvar *archive-type* "tar.gz"
  "Suffix of Drogon source archive.")

(defun drogon-url (version)
  "Return URL to source archive of Drogon VERSION at the official
GitHub repository."
  (concatenate 'string "https://github.com/drogonframework/drogon/archive/refs/tags/v" version "." *archive-type*))

(defun drogon-digest (version)
  "Download Drogon VERSION from the official GitHub repository to a
  temporary file. Compute, and return its SHA-256."
  (uiop:with-temporary-file (:pathname tmp :prefix (concatenate 'string "drogon-" version) :type *archive-type*)
    (trivial-download:download (drogon-url version) tmp)
    (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 tmp))))

(defun trantor-revision (version repository-path)
  "Return the Git revision of the trantor submodule for the
corresponding Drogon VERSION located at REPOSITORY-PATH."
  (remove #\Return (uiop:run-program (concatenate 'string "cd \"" repository-path
                                                  "\" && git ls-tree v" version " trantor | awk '{print $3}'")
                                     :output '(:string :stripped t)))) ; This usage of :stripped T doesn’t seem to work?

(defun pull-drogon (version repository-path)
  "Pull the tag v concatenated with VERSION in the Drogon repository
at REPOSITORY-PATH."
  (legit:with-chdir (repository-path)
    (legit:git-pull :repository "origin" :refspecs (concatenate 'string "v" version) :rebase T)))

(defun patch-homebrew-formula (drogon-url digest trantor-revision repository-path)
  "Patch the Drogon Homebrew formula at REPOSITORY-PATH to contain
DROGON-URL, its SHA-256 DIGEST, and the TRANTOR-REVISION."
  (let ((homebrew-formula (concatenate 'string repository-path "Formula/drogon.rb")))
    (with-open-file (stream homebrew-formula
                            :direction :output
                            :if-exists :overwrite
                            :if-does-not-exist :create)
      (write-sequence
       (cl-ppcre:regex-replace "url \".*drogon.*\""
                               (cl-ppcre:regex-replace "sha256 \".+\""
                                                       (cl-ppcre:regex-replace "revision: \".+\""
                                                                               (uiop:read-file-string homebrew-formula)
                                                                               (concatenate 'string "revision: \"" trantor-revision "\""))
                                                       (concatenate 'string "sha256 \"" digest "\""))
                               (concatenate 'string "url \"" drogon-url "\""))
       stream))))

(defun commit-and-push-homebrew-formula (version repository-path)
  "Commit all changes to the Drogon Homebrew formula at
REPOSITORY-PATH and automatically add a commit message containing the
VERSION number."
  (legit:with-chdir (repository-path)
    (legit:git-commit :all t :message (concatenate 'string "Updated to Drogon " version))
    (legit:git-push :repository "origin" :refspecs "master")))

(defun update (version drogon-repository-path homebrew-formula-repository-path &key (dry-run))
  "Update Drogon at DROGON-REPOSITORY-PATH to Drogon VERSION. Patch
the Homebrew formula at HOMEBREW-FORMULA-REPOSITORY-PATH. Then commit
and push the changes to the latter repository."
  (let ((drogon-path (uiop:native-namestring drogon-repository-path))
         (formula-path (uiop:native-namestring homebrew-formula-repository-path))
         (digest (drogon-digest version))
         (revision (trantor-revision version drogon-path)))
    (pull-drogon version drogon-path)
    (patch-homebrew-formula (drogon-url version) digest revision formula-path)
    (if (not dry-run)
        (commit-and-push-homebrew-formula version formula-path))))
