
# top level target: kboom output
all: axioms.owl

# ----------------------------------------
# EC and external dbs
# ----------------------------------------

# download BRENDA
# NOTE: does not include groupings
Reactions_BKMS.csv:
	wget http://bkm-react.tu-bs.de/download/Reactions_BKMS.tar.gz -O Reactions_BKMS.tar.gz && tar -zxvf Reactions_BKMS.tar.gz

ec-labels.obo: Reactions_BKMS.csv
	cut -f2,3 $< | perl -npe 's@^@EC:@' | tbl2obo.pl - > $@

# make a hierarchy based on all ECs used in GO
#ec.obo:
#	blip-findall -r go -consult ecmaker.pro wall > $@.tmp && mv $@.tmp $@



rhea.obo: $(HOME)/repos/rhea2go/rhea.obo
	perl -npe 's@KEGG_REACTION@KEGG@' $< > $@

bt.obo: Reactions_BKMS.csv  
	./bt2obo.pl $<  > $@.tmp && mv $@.tmp $@

enzyme.dat:
	wget ftp://ftp.ebi.ac.uk/pub/databases/enzyme/$@ -O $@
enzclass.txt:
	wget ftp://ftp.ebi.ac.uk/pub/databases/enzyme/$@ -O $@

ec-leaf.obo: enzyme.dat 
	./enzyme2obo.pl $< > $@
ec-hier.obo: enzclass.txt 
	./enzclass2obo.pl $< > $@

ec.obo: ec-leaf.obo ec-hier.obo
	obo-cat.pl $^ > $@

# ----------------------------------------
# GO pre-processing
# ----------------------------------------

mf.obo:
	blip ontol-query -r go -query "class(R,molecular_function),subclassRT(ID,R),\+entity_obsolete(ID,_)" -to obo > $@.tmp && mv $@.tmp $@
.PRECIOUS: mf.obo

mf-labels.obo: mf.obo
	obo-filter-tags.pl -t id -t name -t xref $<  > $@.tmp && mv $@.tmp $@

# warp GO into EC
mf-isa-ec.obo: mf-labels.obo
	perl -npe 's@xref: EC:@is_a: EC:@' $< | obo-grep.pl -r is_a -  > $@.tmp && mv $@.tmp $@

mashup.obo: mf-isa-ec.obo ec.obo
	owltools $^ --merge-support-ontologies -o -f obo $@

# ----------------------------------------
# GO Reports
# ----------------------------------------

#redundant-xrefs-ec.tsv: mf.obo ec-labels.obo
#	blip-findall -i $< -i ec-labels.obo -consult ecmaker.pro report_ec_redundant/2 -no_pred -label > $@.tmp && mv $@.tmp $@

redundant-xrefs-ec.tsv: mf.obo ec.obo
	blip-findall -i $< -i ec.obo -consult ecmaker.pro report_redundant_set -no_pred -label > $@.tmp && mv $@.tmp $@

big_clique.tsv: mf.obo
	blip-findall -debug clique -i $< -consult ecmaker.pro big_clique/3 -no_pred -label > $@

big_clique_all.tsv: mf.obo
	blip-findall  -i $< -i bt.obo -i rhea.obo -consult ecmaker.pro big_clique/3 -no_pred -label > $@

# ----------------------------------------
# Cytoscape
# ----------------------------------------
all.sif:
	blip-findall -i ec.obo -i mf.obo -consult ecmaker.pro sif/3 -no_pred -noid -label > $@

# ----------------------------------------
# kBOOM analysis
# ----------------------------------------

ptable.tsv: rhea.obo bt.obo
	blip-findall -r go -i rhea.obo -i bt.obo -consult ecmaker.pro ptable/6 -no_pred > $@.tmp && mv $@.tmp $@



set.owl: mf.obo ec.obo rhea.obo
	owltools $^ --merge-support-ontologies -o $@
.PRECIOUS: set.owl

set.obo: set.owl
	owltools $< -o -f obo $@.tmp && mv $@.tmp $@

MAX_E=5
axioms.owl: ptable.tsv set.owl 
	kboom --experimental  --splitSize 50 --max $(MAX_E) -m linked-rpt.md -j linked-rpt.json -n -o $@ -t $^


