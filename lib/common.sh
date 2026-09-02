#
# common.sh - shared helpers for the install scripts in this repo.
#
# Not executable; source it:
#     . "$DIR/../lib/common.sh"
#

# link <src> <dest>
#
# Symlink dest -> src, idempotently. An existing symlink already pointing at src
# is left alone; any other file or symlink is moved aside to <dest>.bak.<epoch>
# rather than clobbered. Parent directories are created as needed.
link() {
   local src="$1" dest="$2"
   mkdir -p "$(dirname "$dest")"

   # Symlink exists and points to the right target
   if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
      echo "ok:  $dest already links to repo"
      return
   fi

   # back up a real file, or a symlink that doesn't point here
   if [ -e "$dest" ] || [ -L "$dest" ]; then
      local bak="$dest.bak.$(date +%s)"
      mv "$dest" "$bak"
      echo "bak: moved $dest -> $bak"
   fi

   ln -s "$src" "$dest"
   echo "done: linked $dest -> $src"
}
