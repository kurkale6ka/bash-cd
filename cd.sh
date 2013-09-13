#! /usr/bin/env bash

cd_bookmarks() {

   # Get bookmarks/directory from: cd options bookmark 1...n {{{1
   bookmarks=()
   for b in "$@"
   do [[ $b != '-'* ]] && bookmarks+=("$b")
   done

   # A single bookmark => check that it doesnt match the current folder
   if ((${#bookmarks[@]} == 1))
   then [[ $PWD == ${bookmarks[0]%/} ]] && return 0
   fi

   local old_pwd="$PWD"

   # 0 or 1 directory: cd, cd options, cd directory {{{1
   if ((${#bookmarks[@]} <= 1)) && cd "$@" 2>/tmp/.cdmarks_"$USER".err; then

      # I will use PWD instead of bookmarks[0]
      # This will ensure the following cases are dealt with correctly:
      # cd -
      # directory typo (cdspell: /var/loc -> log)
      # cd /etc/X11/ creating a different entry than cd /etc/X11
      if [[ $PWD != $HOME && $PWD != $old_pwd ]]; then

         truncate_marks

         # Increase weight for current directory since I've already been here
         local line=0
         while read -r weight dir marks; do
            ((line++))
            if [[ $dir == $PWD ]]; then
               update_weight "$line" "$((++weight)) $dir $marks"
               return 0
            fi
         done < "$HOME"/.cdmarks

         # New entry for the current directory, it's the first time I cd here
         new_entry
         return 0

      fi

   # 1 or + bookmarks (exclude 'cd wrong options' case) {{{1
   elif ((${#bookmarks[@]} > 0)); then

      truncate_marks

      # Increase weight for current directory since I've already been here
      local line=0
      while read -r weight dir marks; do
         ((line++))
         # Check that bookmark x AND bookmark y AND ... match in this line
         local match=1
         for m in "${bookmarks[@]}"
         do [[ "$dir $marks" != *"$m"* ]] && match=0
         done
         if ((match)); then
            # cd options dir
            if cd "${@:1:((${#@}-${#bookmarks[@]}))}" "$dir" 2>/tmp/.cdmarks_"$USER".err; then
               if [[ $dir != $old_pwd ]]
               then update_weight "$line" "$((++weight)) $dir $marks"
               fi
               return 0
            fi
         fi
      done < "$HOME"/.cdmarks

      # cd failed. This message replaces the builtin one only when matching with
      # more than one bookmark
      if ((${#bookmarks[@]} > 1))
      then echo 'No match found.' >&2; return 1
      fi

   fi

   cat /tmp/.cdmarks_"$USER".err >&2; return 2
}

# Use c as a shorter version of the main function
alias c=cd_bookmarks
alias cx=cd_bookmarks

# Helper functions {{{1

# Shrink file size to 100 lines when it reaches 150 lines
truncate_marks() {
   if (( $(wc -l $HOME/.cdmarks | cut -d' ' -f1) > 150 ))
   then ed -s "$HOME"/.cdmarks <<< $'H\n101,$d\nwq\n'
   fi
}

# Update weight for the current directory
update_weight() {
   # Sanitize input: s/[...]/.../g
   local  line="$(command sed 's/[]\/$*.^|[]/\\&/g' <<< "$1")"
   local entry="$(command sed 's/[\/&]/\\&/g'       <<< "$2")"

   # ed: line s / .* / new_entry /
   ed -s "$HOME"/.cdmarks <<< $'H\n'"$line"$'s/.*/'"$entry"$'/\nwq\n'

   # Put highest score entries at the top
   sort -rn -o "$HOME"/.cdmarks "$HOME"/.cdmarks
}

# Add the current directory as a new entry
new_entry() {
   if (($#))
   then echo "1 $PWD $@" >> "$HOME"/.cdmarks
   else echo "1 $PWD"    >> "$HOME"/.cdmarks
   fi
}

# cd help
ch() {
cat << 'HELP'
c  filter<tab>  : Complete: bookmarks + default directories
cx filter<tab>  : Complete: bookmarks
----------------+----------------------------------------------------
cs [filter ...] : list filtered/all bookmarks
----------------+----------------------------------------------------
cb [bookmark]   : create a (named) bookmark for the current directory
----------------+----------------------------------------------------
ci              : import your personal ~/.cdmarks.skel file
HELP
}

# <tab> completion
_cd_complete() {
   # Similar to cs()
   # Get a filtered set of bookmarks (c b1 b2 ...)
   local word="$(command sed 's/[]\/$*.^|[]/\\&/g' <<< "${COMP_WORDS[1]}")"
   local out="$(command grep -i "$word" "$HOME"/.cdmarks)"
   for f in "${COMP_WORDS[@]:2}"; do
      word="$(command sed 's/[]\/$*.^|[]/\\&/g' <<< "$f")"
      out="$(command grep -i "$word" <<< "$out")"
   done

   # Default directories
   # Don't mix default with custom completion (use custom only)
   if [[ ${FUNCNAME[1]} == 'cd_bcomplete' ]]
   then local defdirs=()
   else IFS=$'\n' read -r -d $'\0' -a defdirs < <(compgen -S/ -d "${COMP_WORDS[1]}")
   fi
   # Our bookmarked directories (color?)
   IFS=$'\n' read -r -d $'\0' -a dirlist < <(cut -d' ' -f2 <<< "$out")

   local dirs=("${defdirs[@]}" "${dirlist[@]}")
   if [[ $dirs ]]
   then IFS=$'\n' read -r -d $'\0' -a COMPREPLY < <(printf '%q\n' "${dirs[@]}")
   fi
}
complete -o nospace -Fcd_complete  c
complete -o nospace -Fcd_bcomplete cx
cd_complete()  { _cd_complete "$@"; }
cd_bcomplete() { _cd_complete "$@"; }

# cds (mnemo: cd in plural)
cs() {
   if (($#)); then
      # Get a filtered set of bookmarks (cs b1 b2 ...)
      local word="$(command sed 's/[]\/$*.^|[]/\\&/g' <<< "$1")"
      local out="$(command grep -i "$word" "$HOME"/.cdmarks)"
      for f in "${@:2}"; do
         word="$(command sed 's/[]\/$*.^|[]/\\&/g' <<< "$f")"
         out="$(command grep -i "$word" <<< "$out")"
      done
      echo "$out"
   else
      column -t < "$HOME"/.cdmarks
   fi
}

# cd bookmark
# TODO: update weights if using this function after a builtin cd (check with fc)
#       and the current directory is not a new entry
# local line=0
# while read -r weight dir marks; do
#    ((line++))
#    if [[ $dir == $PWD ]]; then
#       update_weight "$line" "$((++weight)) $dir $marks"
#       return 0
#    fi
# done < "$HOME"/.cdmarks
cb() {
   # Sanitize input
   local current="$(command sed 's/[]\/$*.^|[]/\\&/g' <<< "$PWD")"
   if (($#)); then
      # The array is flattened here but it doesn't matter as we don't want
      # bookmarks with spaces (ie: cb 'my bookmark' is forbidden)
      local marks="$(command sed 's/[\/&]/\\&/g' <<< "$@")"

      # ed: line s / $ / bookmarks /
      # I can't use ed alone here as it doesn't support alternation (\|) in patterns
      line="$(command grep -n "$current"'\([^/]\|\s*$\)' "$HOME"/.cdmarks | cut -d: -f1)"
      if ((line))
      then ed -s "$HOME"/.cdmarks <<< $'H\n'"$line"$'s/\s*$/ '"$marks"$'/\nwq\n'
      else new_entry "$@"
      fi
   else
      if ! command grep "$current" "$HOME"/.cdmarks
      then new_entry
      fi
   fi
}

# cd import
ci() {
   if [[ -r $HOME/.cdmarks ]]; then
      read -p \
         'Are you sure you want to overwrite ~/.cdmarks with ~/.cdmarks.skel (y/N) ' \
         reset
   else
      local reset=y
      echo "Creating $HOME/.cdmarks..."
   fi
   if [[ $reset == 'y' ]]; then
      # Sanitize input
      local home="$(command sed 's/[\/&]/\\&/g' <<< "$HOME")"
      sed "s/\~/$home/" "$HOME"/.cdmarks.skel > "$HOME"/.cdmarks
   fi
}
