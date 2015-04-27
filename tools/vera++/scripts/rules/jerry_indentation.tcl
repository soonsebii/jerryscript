#!/usr/bin/tclsh

# Copyright 2014-2015 Samsung Electronics Co., Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Indentation

foreach fileName [getSourceFileNames] {
    set indent 0
    set lastCheckedLineNumber -1
    set is_in_comment "no"
    set is_in_pp_define "no"
    set is_in_class "no"
    set parentheses_level 0

    foreach token [getTokens $fileName 1 0 -1 -1 {}] {
        set type [lindex $token 3]
        set lineNumber [lindex $token 1]

        if {$is_in_comment == "yes"} {
            set is_in_comment "no"
        }

        if {$type == "newline"} {
            set is_in_pp_define "no"
        } elseif {$type == "class"} {
            set is_in_class "yes"
        } elseif {$is_in_class == "yes" && $type == "semicolon" && $indent == 0} {
            set is_in_class "no"
        } elseif {$type == "ccomment"} {
            set is_in_comment "yes"
        } elseif {[string first "pp_" $type] == 0} {
            if {$type == "pp_define"} {
                set is_in_pp_define "yes"
            }

            set lastCheckedLineNumber $lineNumber
        } elseif {$type == "space"} {
        } elseif {$type != "eof"} {
            if {$type == "rightbrace"} {
                incr indent -2
            }

            if {$is_in_pp_define == "no" && $is_in_comment == "no" && $is_in_class == "no" && $parentheses_level == 0} {
                set line [getLine $fileName $lineNumber]

                if {$lineNumber != $lastCheckedLineNumber} {
                    if {[string length $line] == 0} {
                    }

                    if {[regexp {^[[:blank:]]*} $line match]} {
                        set real_indent [string length $match]
                          if {$indent != $real_indent} {
                              if {![regexp {^[[:alnum:]_]{1,}:$} $line] || $real_indent != 0} {
                                  report $fileName $lineNumber "Indentation: $real_indent -> $indent. Line: '$line'"
                              }
                          }
                    }
                }

                if {$lineNumber == $lastCheckedLineNumber} {
                    if {$type == "leftbrace"} {
                        if {![regexp {^[[:blank:]]*\{[[:blank:]]*$} $line]
                            && ![regexp {[^\{=]=[^\{=]\{.*\},?} $line]} {
                          report $fileName $lineNumber "Left brace is not the only non-space character in the line: '$line'"
                        }
                    }
                    if {$type == "rightbrace"} {
                        if {![regexp {^.* = .*\{.*\}[,;]?$} $line]
                            && ![regexp {[^\{=]=[^\{=]\{.*\}[,;]?} $line]} {
                            report $fileName $lineNumber "Right brace is not first non-space character in the line: '$line'"
                        }
                    }
                }
                if {$type == "rightbrace"} {
                  if {![regexp {^[[:blank:]]*\}((( [a-z_\(][a-z0-9_\(\)]{0,}){1,})?;| /\*.*\*/| //.*)?$} $line]
                      && ![regexp {[^\{=]=[^\{=]\{.*\}[,;]?} $line]} {
                        report $fileName $lineNumber "Right brace is not the only non-space character in the line and \
                          is not single right brace followed by \[a-z0-9_() \] string and single semicolon character: '$line'"
                 }
                }
            }

            if {$type == "leftbrace"} {
                incr indent 2
            } elseif {$type == "leftparen"} {
                incr parentheses_level 1
            } elseif {$type == "rightparen"} {
                incr parentheses_level -1
            }

            set lastCheckedLineNumber $lineNumber
        }
    }
}