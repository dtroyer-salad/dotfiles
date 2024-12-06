#!/bin/bash
# Extract subtrees from a git repository
#
# split-repo.sh new-repo.map [branch]
#
# The map file has two parts per line separated by a pipe ('|') character.
# The first is a path into the source repository to extract, the second is
# the destination in the new repository.
#
# The current working directory should be the directory containing the source
# repositories.  
#
# The destination repository is created in the current working directory using
# the base name of the map file.
#
# Starting with a monoquux repo and a baz.map with these contents:
#
# monoquux/middleware/foo/foo-manager|foo-manager
# monoquux/middleware/bar/bar-manager|bar-manager
#
# produces a baz repo with foo-manager and bar-manager subdirectories.
#
# Left behind in the baz repo will be two type of directories:
# * The original repo used to do the filter operation, with ".old_repo" appended.
# * Any left-over directory trees from after the git mv of the components into their
#   final location. These are still under git control so need to be removed with a
#   'git rm -r' and committed.  They are left behind for manual verification of
#   files that may have been missed and need to be added to the .map file.
#
# This uses filter_git_history.sh from OpenStack's oslo.tools library.
# https://opendev.org/openstack/oslo.tools.git
#
# Export OSLO_TOOLS set to the top directory of the oslo.tools repo, or just put
# filter_git_histroy.sh in your path.

MAPFILE=${1:-repo.map}
BRANCH=${2:-master}

# Verify oslo.tools is present
OSLO_TOOLS=${OSLO_TOOLS:-""}
OSLO_TOOLS_REPO=https://opendev.org/openstack/oslo.tools.git
OSLO_FILTER_SCRIPT=filter_git_history.sh
OSLO_FILTER_CMD=$(which ${OSLO_FILTER_SCRIPT})
if [[ "$OSLO_FILTER_CMD" == "" ]]; then
    # not found in path
    if [[ -d ${OSLO_TOOLS} && -x ${OSLO_TOOLS}/tools/${OSLO_FILTER_SCRIPT} ]]; then
        # found it!
        OSLO_FILTER_CMD=${OSLO_TOOLS}/tools/${OSLO_FILTER_SCRIPT}
    else
        echo "${OSLO_FILTER_SCRIPT} is not found.  You need to get it and set OSLO_TOOLS to the directory"
        echo "\$ git clone ${OSLO_TOOLS_REPO} oslo.tools"
        echo "\$ export OSLO_TOOLS=$(pwd)/oslo.tools"
        exit 1
    fi
fi

set -e

# Set up destination repo
dest_repo=${MAPFILE%.*}
dest_repo=${dest_repo##*/}
if [[ ! -d $dest_repo ]]; then
	mkdir -p $dest_repo
	(
		cd $dest_repo; \
		git init; \
	)
fi

# Wrapper around oslo.tools/filter_git_history.sh to remove everything
# not in $filter_list, then merge that into the new repo
function filter_repo {
    local src_repo=$1
    local src_path=$2
    local dest_repo=$3
    shift; shift; shift
    local filter_list="$@"

        # initial work is done in <new-repo>/<src-repo>.old_repo
	    work_dir=$src_repo.old_repo

        # Source repo changed, batch up the filters for the last one and do it
        if [[ ! -d $dest_repo/$work_dir ]]; then
		    # Start with a copy of the source repo as the filter process is destructive
		    cp -pr $src_repo $dest_repo/$work_dir

            # Ensure no previous backup exists
            rm -rf $dest_repo/$work_dir/.git/packed_refs $dest_repo/$work_dir/.git/refs/original

		    # Filter it
		    (
                cd $dest_repo/$work_dir; \
                git checkout $BRANCH || true; \
                ${OSLO_TOOLS}/filter_git_history.sh $filter_list; \
            )
	    fi

        # Merge the filtered repo into the destination repo
        (
            cd $dest_repo; \
            git remote add tmp-remote $work_dir; \
            git fetch tmp-remote; \
            git merge -s ours tmp-remote/$BRANCH; \
            git remote remove tmp-remote; \
        )
}

# Loop through source subtrees
current_src_repo=""
current_src_path=""
current_dest_repo=""
filter_list=""
rewrite_list=""
while IFS="|" read src dest; do
	echo "Splitting $src -> $dest"
	src_repo=${src%%/*}
	src_path=${src#*/}

    if [[ "$current_src_repo" != "" && "$current_src_repo" != "$src_repo" ]]; then
        # The (next) source repo changed, process the previous (current) repo list
        filter_repo $current_src_repo $current_src_path $current_dest_repo $filter_list
    fi

    # set up the state vars
    current_src_repo=$src_repo
    current_src_path=$src_path
    current_dest_repo=$dest_repo
    filter_list+="$src_path "
    rewrite_list+="s|\t$src_path/|\t$dest/|;"
done < "$MAPFILE"

if [[ "$current_src_repo" != "" ]]; then
    # One more time, with feeling, to catch the last one
    filter_repo $current_src_repo $current_src_path $current_dest_repo $filter_list
fi

index_filter="
    git ls-files -s | sed '$rewrite_list' | \
    GIT_INDEX_FILE=\$GIT_INDEX_FILE.new \
    git update-index --index-info && mv \$GIT_INDEX_FILE.new \$GIT_INDEX_FILE || true
"

# Do the git mv to the final home
(
    cd $dest_repo; \
    git filter-branch --index-filter "$index_filter" HEAD

    # Set the branch name
    git branch -m master $BRANCH || true
)
