#!/bin/perl -w

## Check command ##
if (@ARGV != 1 && @ARGV != 2) {
    print "Usage: perl $0 CHECKSTYLE_RESULT_FILE [DIFF_OUTPUT_FILE]\n";
    print "(default DIFF_OUTPUT_FILE: diffcs.xml)\n";
    exit(1);
}

## Open file ##
open(IN, $ARGV[0]) || die "$ARGV[0]: $!\n";
if (@ARGV == 2) {
    open(OUT, ">$ARGV[1]") || die "$!\n";
}
else {
    open(OUT, ">diffcs.xml") || die "$!\n";
}

if (<IN> !~ /^<\?xml*/) {
    print "Error: $ARGV[0] is not a valid checkstyle result(.xml) file.\n";
    print "       Please check $ARGV[0] file.\n";
    exit(1);
}

## Find diff ##
while (<IN>) {
    # Processing '<file' fields
    if ($_ =~ /^<file*/) {
        print OUT $_;

        # Processing file name
        @temp = split(/\"/, $_);
        $filename_old = $temp[1];
        $filename_new = $temp[1];
        $filename_new =~ s/.java$/.java.new/;

        # Diff source files & get added/changed line numbers
        if (-f $filename_old) {
            open (LINENUMS, "diff $filename_old $filename_new | grep \'^[0-9]*,*[ac][0-9]*,*[0-9]*\' | sed s/[0-9]*,*[0-9]*[ac]/\"\"/g | awk 'BEGIN {FS=\",\"}; {if (\$2) { while (\$1 < \$2 + 1) {print \$1++;} } else {print \$1;} }'|");

            @linenums = <LINENUMS>;

            close (LINENUMS);
        }
    }

    # processing '<error' fields
    elsif ($_ =~ /^<error*/) {
        # check lines
        @checkline = split(/\"/, $_);
        if (-f $filename_old) {
            foreach $i (@linenums) {
                if ($checkline[1] == $i) {
                    print OUT $_;
                }
            }
        }
        else {
            print OUT $_;
        }
    }

    # others
    else {
        print OUT $_;
    }
}

## Close opened file ##
close(OUT);
close(IN);
