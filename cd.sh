#! /usr/bin/env bash

cd_bookmarks() {
   local current="$PWD"

   # Get bookmarks/directory from: cd options bookmark 1...n {{{1
   bookmarks=()
   for b in "$@"
   do [[ $b != '-'* ]] && bookmarks+=("$b")
   done

   # A single bookmark => check that it doesnt match the current folder
   if ((${#bookmarks[@]} == 1))
   then [[ $current == ${bookmarks[0]%/} ]] && return 0
   fi

   # 0 or 1 directory: cd, cd options, cd directory {{{1
   if ((${#bookmarks[@]} <= 1)) && builtin cd "$@" 2>/tmp/cderror; then

      # I will use PWD instead of bookmarks[0]
      # This will ensure the following cases are dealt with correctly:
      # cd -
      # directory typo (cdspell: /var/loc -> log)
      # cd /etc/X11/ creating a different entry than cd /etc/X11
      if [[ $PWD != $HOME && $PWD != $current ]]; then

         truncate_marks

         # Increase weight for current directory since I've already been here
         local line=0
         while read -r weight dir mark; do
            ((line++))
            if [[ $dir == $PWD ]]; then
               local new_weight="$weight"
               local new_entry="$((++new_weight)) $dir $mark"
               update_weight "$line" "$new_entry"
               return 0
            fi
         done < "$HOME"/.cdmarks

         # New entry for the current directory, it's the first time I cd here
         # ed: a '1 directory' .
         printf -v new_dir 'H\na\n1 %s\n.\nwq\n' "$PWD"
         ed -s "$HOME"/.cdmarks <<< "$new_dir"
         return 0

      fi

   # 1 or + bookmarks (exclude 'cd wrong options' case) {{{1
   elif ((${#bookmarks[@]} > 0)); then

      truncate_marks

      # Increase weight for current directory since I've already been here
      local line=0
      while read -r weight dir mark; do
         ((line++))
         # Check that bookmark x AND bookmark y AND ... match in this line
         local match=1
         for m in "${bookmarks[@]}"
         do [[ "$dir $mark" != *$m* ]] && match=0
         done
         if ((match)); then
            # cd options dir
            if builtin cd "${@:1:((${#@}-${#bookmarks[@]}))}" "$dir" 2>/tmp/cderror; then
               if [[ $dir != $HOME && $dir != $current ]]; then
                  local new_weight="$weight"
                  local new_entry="$((++new_weight)) $dir $mark"
                  update_weight "$line" "$new_entry"
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

   cat /tmp/cderror >&2; return 2
}

# Functions {{{1

# Shrink file size to 100 lines when it reaches 150 lines
truncate_marks() {
   if (( $(wc -l $HOME/.cdmarks | cut -d' ' -f1) > 150 ))
   then ed -s "$HOME"/.cdmarks <<< $'H\n101,$d\nwq\n'
   fi
}

update_weight() {
   local line="$1" entry="$2"

   # Increase weight of the directory
   # Path must not contain any @s !
   # ed: line s @ .* @ new_entry @
   printf -v update 'H\n%us@.*@%s@\nwq\n' "$line" "$entry"
   ed -s "$HOME"/.cdmarks <<< "$update"

   # Put highest score entries at the top
   sort -rn -o "$HOME"/.cdmarks "$HOME"/.cdmarks
}

# cd help
ch() {
cat << 'HELP'
c  filter<tab> : list a subset of bookmarks matching your filters
cs filter ...  :                        ""
cs             : list all bookmarks
---------------+--------------------------------------------------
cb bookmark    : create a named bookmark for the current directory
---------------+--------------------------------------------------
ci             : import your personal ~/.cdmarks.skel file
HELP
}

# <tab> completion for c
complete -Fcd_complete c
cd_complete() {
   # Similar to cs()
   local out=$(command grep -i "${COMP_WORDS[1]}" "$HOME"/.cdmarks)
   for f in "${COMP_WORDS[@]:2}"
   do out=$(command grep -i "$f" <<< "$out")
   done
   IFS=$'\n' read -r -d $'\0' -a dirlist < <(cut -d' ' -f2 <<< "$out")
   if [[ $dirlist ]]
   then IFS=$'\n' read -r -d $'\0' -a COMPREPLY < <(printf '%q\n' "${dirlist[@]}")
   fi
}

# cds (cd in plural)
cs() {
   if (($#)); then
      local out=$(command grep -i "$1" "$HOME"/.cdmarks)
      for f in "${@:2}"
      do out=$(command grep -i "$f" <<< "$out")
      done
      echo "$out"
   else
      column -t < "$HOME"/.cdmarks
   fi
}

# cd bookmark
cb() {
   printf -v bookmark 'H\n/%s[^/]*$/s@\s*$@ %s@\nwq\n' "${PWD//\//\/}" "$1"
   ed -s "$HOME"/.cdmarks <<< "$bookmark"
}

# cd import
ci() {
   [[ -r $HOME/.cdmarks ]] && local reset='n' || local reset='y'
   read -p \
      "Are you sure you want to overwrite ~/.cdmarks with ~/.cdmarks.skel (y/N) " reset
   if [[ $reset == 'y' ]]
   then sed "s@\~@$HOME@" "$HOME"/.cdmarks.skel > "$HOME"/.cdmarks
   fi
}