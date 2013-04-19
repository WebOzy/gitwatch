#!/bin/bash
#
# gitwatch - watch file or directory and git commit all changes as they happen
#
# Original work by Patrick Lehner with modifications by Nicholas Garofalo
#
#############################################################################
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################
#
# Requires the command 'inotifywait' to be available, which is part of
# the inotify-tools (See https://github.com/rvoicilas/inotify-tools )
#

if [ -z $1 ]; then
    exit
fi

# These two strings are used to construct the commit comment
#  They're glued together like "<CCPREPEND>(<DATE&TIME>)<CCAPPEND>"
# If you don't want to add text before and/or after the date/time, simply
#  set them to empty strings

CCPREPEND="I found changes on "
CCAPPEND=" and committed them via gitwatch.sh"

IN=$(readlink -f "$1")

if [ -d $1 ]; then
    TARGETDIR=`echo "$IN" | sed -e "s/\/*$//" ` #dir to CD into before using git commands: trim trailing slash, if any
    INCOMMAND="inotifywait --exclude=\"^${TARGETDIR}/.git\" -qqr -e close_write,moved_to,delete $TARGETDIR" #construct inotifywait-commandline
    GITADD="." #add "." (CWD) recursively to index
    GITINCOMMAND=" -a" #add -a switch to "commit" call just to be sure
elif [ -f $1 ]; then
    TARGETDIR=$(dirname $IN) #dir to CD into before using git commands: extract from file name
    INCOMMAND="inotifywait -qq -e close_write,moved_to,delete $IN" #construct inotifywait-commandline
    GITADD="$IN" #add only the selected file to index
    GITINCOMMAND="" #no need to add anything more to "commit" call
else
    exit
fi

# This takes care of committing and pushing

while true; do
    $INCOMMAND # wait for changes
    sleep 2 # wait 2 more seconds to give apps time to write out all changes
    DATE=`date +"%d %b %Y at %r"` # construct date-time string
    cd $TARGETDIR # CD into right dir
    git add $GITADD # add file(s) to index
    git commit$GITINCOMMAND -m"${CCPREPEND}${DATE}${CCAPPEND}" # construct commit message and commit
    git push # push the changes to github
done
