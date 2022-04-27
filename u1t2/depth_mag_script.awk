#!/usr/bin/env -S awk -f

BEGIN {FS="," ; maxDepth=0 ; maxMag=0}
{
    if (NR==1) {
        minDepth=$2;
        minMag=$3;
    }

    if ($2 > maxDepth)
        maxDepth = $2;
    else if ($2 < minDepth)
        minDepth = $2;

    if ($3 > maxMag)
        maxMag = $3;
    else if($3 < minMag)
        minMag = $3;
}
END {
    print "The deepest earthquake was " maxDepth " and the shallowest was " minDepth;
    print "The biggest earthquake was " maxMag " and the lowest was " minMag 
}
