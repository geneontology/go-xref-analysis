#!/usr/bin/perl
while(<>) {
    my ($bt,$ec,$n,$eq,$xx,$kegg,$mc) = split(/\t/, $_);
    next unless $ec; # TODO
    next unless $ec =~ m@\.@;  # filter weird entries
    print "[Term]\n";
    print "id: EC:$ec\n";
    print "name: $n activity\n";
    print "xref: KEGG:$_\n" foreach split(/,/,$kegg);
    print "xref: MetaCyc:$_\n" foreach split(/,/,$mc);
    print "\n";
                                           
}
