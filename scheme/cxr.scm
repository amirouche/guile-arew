;; -*- mode: scheme; coding: utf-8 -*-
;; SPDX-License-Identifier: CC0-1.0
#!r6rs

(define-module (scheme cxr))

(import (rnrs))

(re-export
    caaaar caaadr caaar caadar caaddr caadr cadaar cadadr cadar
    caddar cadddr caddr cdaaar cdaadr cdaar cdadar cdaddr cdadr
    cddaar cddadr cddar cdddar cddddr cdddr)
