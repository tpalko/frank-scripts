#!/bin/bash 
# purpose? in a git repo, show ignored local files, in theory anything outside source control
# for capture purposes when migrating to not leave anything behind 
# can be piped to tar??

# examples 
# fish:
# tar -czvf frank-scripts-ignored.tar.gz -T $(revgit | psub)
# bash maybe?
# tar -czvf frank-scripts-ignored.tar.gz -T < <(revgit)

for IGN in $(cat .gitignore); do 
    for FND in $(find . -name "$IGN"); do 
        [[ -d ${FND} ]] \
            && find ${FND} \
            || [[ -f ${FND} ]] \
            && echo ${FND}
    done
done
