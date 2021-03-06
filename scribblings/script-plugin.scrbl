#lang scribble/manual

@(require planet/scribble
          racket/file
          racket/path
          racket/runtime-path
          (for-syntax racket/base) ; for build-path in runtime-path
          (for-label racket/gui)
          (for-label drracket/tool-lib))

@(define-runtime-path examples-path (build-path 'up "examples"))
@(define (example-file f)
   (let ([p (build-path examples-path f)])
     (unless (file-exists? p)
       (error "File not found" p))
     p))

@(define (example-link f)
   (filepath f)
   #;(hyperlink (example-file f) ; we cannot use an hyperlink because I get an error "from root: link going out"
              (filepath f)))

@(define (codeblock/file file)
   (list
    @(filebox (path->string (file-name-from-path file)) "")
    @(codeblock (file->string file))))

@(define (codeblock/example-file filename)
   (list
    @(filebox (example-link filename) "")
    @(codeblock (file->string (example-file filename)))))

@title{Script Plugin for DrRacket}

@;author{Laurent Orseau}
@(smaller (author+email "Laurent Orseau" "laurent.orseauREMOVEME@gmail.com" #:obfuscate? #t))

@section{Introduction}

The Script Plugin's purpose is to make it easy to extend DrRacket with small Racket scripts
that can be used in the definition (or interaction) window, or to graphically interact with the user.

Creating a new script is as easy as a click on a menu item.
Each script is automatically added as an item to the @italic{Scripts} menu, without needing to restart DrRacket.
A keyboard shortcut can be assigned to a script (via the menu item).
By default, a script takes as input the currently selected text, and outputs the replacement text.
There is also direct access to some elements of DrRacket for advanced
(though simplified since there is no need to create a dedicated plugin) scripting,
like DrRacket's frame and the definition or interaction editor.

@section{Some demonstration videos}

@(itemlist
  @item{@hyperlink["https://www.youtube.com/watch?v=KJjVREsgnvA"]{Tab indent plugin:} Word alignment}
  @item{@hyperlink["https://www.youtube.com/watch?v=qgjAZd4eBBY"]{Abstract variable plugin:} Turn an expression into a definition}
  )

@section{Installation}

To install, simply evaluate:

@racket[(require (planet orseau/script-plugin/tool))]

Wait for the installation process to finish, and then restart DrRacket.
You should now see a new @italic{Scripts} menu.

@section{First simple example}

Click on the @italic{Scripts/Manage scripts/New script...} menu item, and enter @italic{Reverse} for the script name.
This creates and opens the files reverse.rkt and reverse.rktd in the script directory.
Also, a new item automatically appears in the @italic{Scripts} menu.

In the .rkt file that just opened in DrRacket, modify the @racket[item-callback] function to the following:
@(racketblock
  (define (item-callback str)
    (list->string (reverse (string->list str))))
  )
and save the file.
(Note: if you changed the properties file, you will need to reload the menu by clicking on
@italic{Scripts/Manage scripts/Reload scripts menu}).

Then go to a new tab, type some text, select it, and click on @italic{Scripts/Reverse}, and voilà!

@section{Description}

The plugin adds a @italic{Scripts} menu to the main window.
This menu has several items, followed by the (initially empty) list of active
scripts.


The @italic{New script} item asks for a script name and creates 2 files:
@itemlist[
  @item{a .rkt file, the script itself (filled with a default script template),}
  @item{a .rktd file, the metadata of the script with the default values.}
]
These two files are automatically opened in DrRacket for edition.

The script menu is rebuilt each time the user activates it, so that changes
are taken into account as soon as possible.

@subsection{The .rkt file}
    This is the script file.
    It must provide the @racket[item-callback] function,
    as in the sample code.
    It is meant to be executable by itself, as a normal module, to ease the testing process.

    @defproc[(item-callback [str string?]) (or/c string? (is-a?/c snip%) #f)]{
    Returns the string meant to be inserted in place of the current selection,
    or at the cursor if there is no selection.
    If the returned value is not a @racket[string] or a @racket[snip%],
    the selection is not modified (i.e., the file remains in a saved state if it was already saved).
    }



    This function signature can also be extended by (optional or mandatory) special keyword arguments:
    @;(the exact signature is determined with @racket[procedure-keywords]):
    @itemlist[
               @item{@racket[#:file : (or/c path? #f)]

                      The path to the current file of the definition window, or @racket[#f]
                      if there is no such file (i.e., unsaved editor).

                      @bold{Example:}
                      @(racketblock
                        (define (item-callback str #:file f)
                          (string-append "(in " (if f (path->string f) "no-file") ": " str))
                        )

                      See also: @racket[file-name-from-path], @racket[filename-extension],
                      @racket[path->string], @racket[split-path].
                      }

               @item{@racket[#:definitions : text%]

                      The @racket[text%] editor of the current definition window.

                      @bold{Example:} @example-link{insert-lambda.rkt}
                      @;(codeblock/file (example-file "insert-lambda.rkt"))

                      See @racket[text%] for more details.
                      }

               @item{@racket[#:interactions : text%]

                      The @racket[text%] editor of the current interaction window.
                      Similar to @racket[#:definitions].
                      }

               @item{@racket[#:editor : text%]

                      The @racket[text%] current editor, either the definition or the interaction editor.
                      Similar to @racket[#:definitions].
                      }

               @item{@racket[#:frame : drracket:unit:frame<%>]

                      DrRacket's frame.
                      For advanced scripting.

                      @bold{Example:}
                      @(racketblock
                        (define (item-callback str #:frame fr)
                          (send fr create-new-tab)
                          #f)
                        )
                      }

              ]



    The name of the function can also be changed,
    but this requires to change it also in the @racket[functions]
    entry of the .rktd file (see below), and the function must be @racket[provide]d.

@subsection{The .rktd file}

This is the metadata file.
It contains an association list dictionary that defines the configuration of the script.

@bold{Note:} @italic{This file being a data file, it should almost never contain quotes. The quotes in the following definitions must thus not appear in the file.}

Most entries (@racket[label], @racket[shortcut], @racket[shortcut-prefix], @racket[help-string]) are the same as
for the @racket[menu-item%] constructor.
In particular, a keyboard shortcut can be assigned to an item.

Additionally, if the @racket[label] is @racket['separator], then a separator is added in the menu.

If an entry does not appear in the dictionary, it takes its default value.

There are some additional entries:
@itemlist[
          @item{@racket[functions : (or/c symbol? (listof (list/c symbol? string?))) = item-callback]

                 If a symbol, it is the name of the function to call (which must be provided),
                 and it must follow @racket[item-callback]'s signature (with potential extensions).

                 If a list, each symbol is the name of a function, and each string is a label for that function.
                 In this case, a sub-menu holding all these functions is created,
                 and the @racket[label] option is used as the parent menu name.

                 Note that a sub-menu can be shared among scripts.

                 @bold{Example:}

                 The following .rktd file creates a sub-menu named @italic{My Functions} (with the letter F for keyboard access),
                 containing 3 items, one for each function and its associated letter-accessor.
                 @(codeblock/example-file "my-functions.rktd")

                 And the associated .rkt example file:
                 @(codeblock/example-file "my-functions.rkt")

                 @bold{Note:} The @racket[label] can also be @racket['separator].

                 }
           @item{@racket[output-to : (one-of/c 'selection 'new-tab 'message-box #f) = 'selection]

                  If @racket['selection], the output of the @racket[item-callback] function replaces the
                  selection in the current tab, or insert at the cursor if there is no
                  selection.
                  If @racket['new-tab], a new tab is created and the output of the function is written to it.
                  If @racket['message-box], the output is displayed in a @racket[message-box].
                  If @racket[#f], no output is generated.
                  }
           @item{@racket[persistent : boolean? = #f]

                  If not persistent, each time a script is invoked, it is done so in a fresh namespace
                  (so that less memory is used, at the expense of a slight time overhead).
                  In particular, all variables are reset to their initial state.

                  On the contrary, if a script is persistent, a fresh namespace is created only
                  the first time it is invoked, and the same namespace is re-used for the subsequent invocations.

                  Consider the following script:
                  @codeblock|{#lang racket/base
                  (define count 0)
                  (define (item-callback str)
                    (set! count (+ 1 count))
                    (number->string count))
                   }|

                  If the script is persistent, the counter increases at each invocation of the script via the menu,
                  whereas it always displays 1 if the script is not persistent.

                  Note: Persistent scripts can be "unloaded" by clicking on the @italic{Scripts/Manage scripts/Unload persistent scripts} menu item.
                  In the previous example, this will reset the counter.
                  }
           @item{@racket[active : boolean? = #t]

                  If set to @racket[#f], no menu item is generated for this dictionary.}

 ]

Finally, one .rktd file can contain several such dictionaries (one after the other),
which allows for multiple sub-menus and menu items and in a single script.
This would have roughly the same effect as splitting such a script into several scripts,
each one with its own .rktd file and its single dictionary.

If any change is made to a .rktd file, the Scripts menu will probably need to be reloaded:
Click on @italic{Scripts/Manage scripts/Reload scripts menu}.

@section{Scripts directory}

@;{
There are several other examples in the @filepath{examples} directory.
To use an example, just copy both the .rkt and .rktd files of the same name
from the @filepath{examples} directory to the user's script directory (see below).
It should then automatically appear in the @italic{Scripts} menu.

To find the @filepath{examples} directory, evaluate (once the plugin is installed):
@(racketblock
  (require racket planet/resolver)
  (build-path (path-only
               (resolve-planet-path
                '(planet orseau/script-plugin/tool)))
              "examples")
  )
}

The default location of the user's scripts is in a sub-folder of
@racket[(find-system-path 'pref-dir)].
The directory of the user's scripts can be changed through DrRacket's preferences
(in @italic{Edit/Preferences/Scripts}).
@bold{Important:} The user's script directory must have write-access for the user
(which should be the case for the default settings).

The @italic{Import bundled script} item is useful to either restore a bundled script to its initial contents if you have made changes,
or import new scripts after an update of the plugin.

Note: Bundled scripts are automatically copied from the plugin directory
to the user script directory on installation.
To force the recopy of all bundled scripts,
just delete the user script directory (itself, not only its contents) and restart DrRacket.

@section{Usage ideas and sample scripts}

@itemlist[
           @item{Auto-completion (see @example-link{complete-word.rkt})}
           @item{On-screen signature of the function at the cursor (see @example-link{def-signatures.rkt}, much faster than launching the browser,
                                                                        but less detailed)}
           @item{Code snippets scripts, with keyboard shortcuts, e.g.,
                 adding a @racket[require] line for each planet package you usually use, or a license header}
           @item{Module template (e.g., the @filepath{info.rkt} file)}
           @item{ASCII frames and styling (upper-case, ASCII art, etc.) for comment titles, sections, etc.
                 (see @example-link{sections.rkt})}
           @item{Automatic comments, e.g. with today's date, user name, etc. (see @example-link{author-date.rkt})}
           @item{Automatic reformatting and custom indentation (see @example-link{indent-table.rkt})}
           @item{Analyse the current file and display the results in a new tab, or
                 Count the number of words/lines/characters and display it in a message-box}
           @item{Perform a particular search and replace operation
                 (see @example-link{regexp-replace.rkt})}
           @item{Open the color chooser and make it output the constructor code for a color (see @example-link{color-chooser.rkt})}
           @item{Open a new tab with a template code}
           @item{Commit/update files from repositories}
           @item{Perform various OS tasks, e.g., open the OS's browser or terminal in the directory of the current file}
           @item{Turn DrRacket into a very rich text editor with @racket[slideshow]
                                                                 (see @example-link{test-slideshow.rkt})}
           @item{Add a spell checker for scribble to DrRacket}
           @item{Add your own menus to DrRacket (see @example-link{test-menu.rkt})}
           @item{Make an Overview frame for scrbl documents, with links to (sub)sections; This could also be added as an automatically refreshed menu to DrRacket}
           @item{...}
           ]

Remark: Code snippets should probably be of rare usage, as one should better take advantage of
Racket's wonderful macro system.
In some cases however, snippets might be useful, e.g., to require your common module where
all your usual macros and functions are defined, or for automatic comments.

@section{Updating the Script Plugin package}

To update the Script Plugin once already installed, just @racket[require] the newest version of the @PLaneT package.
The user's scripts will not be modified in the process.
There may be new bundled scripts or new versions of some bundled scripts in the new package; they won't be (re)installed by default.
To (re)install them, import them with the @italic{Import bundled script} menu item.
To import all bundled scripts at once, delete or rename the user script directory and (re)start DrRacket;
the directory will be recreated with all bundled scripts (then move your own scripts from the renamed folder to this new one).

Some scripts are persistent (like the @filepath{def-signatures} one) and need either DrRacket to be restarted
or simpler to click on the @italic{Unload persistent scripts} menu item.

@section{License}

Copyright (c) 2012 by @link["mailto:laurent.orseauREMOVEME@gmail.com"]{Laurent Orseau @"<laurent.orseauREMOVEME@gmail.com>"}.

This package is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You can find a copy of the GNU Lesser General Public License at
@link["http://www.gnu.org/licenses/lgpl-3.0.html"]{http://www.gnu.org/licenses/lgpl-3.0.html}.
