all: axioms.owl

rhea.obo:
	cp $(HOME)/repos/rhea2go/rhea.obo .

ec.obo:
	blip-findall -r go -consult ecmaker.pro wall > $@.tmp && mv $@.tmp $@

ptable.tsv: rhea.obo
	blip-findall -r go -i rhea.obo -consult ecmaker.pro ptable/6 -no_pred > $@.tmp && mv $@.tmp $@

mf.obo:
	blip ontol-query -r go -query "class(R,molecular_function),subclassRT(ID,R),\+entity_obsolete(ID,_)" -to obo > $@.tmp && mv $@.tmp $@
.PRECIOUS: mf.obo

mf-labels.obo: mf.obo
	obo-filter-tags.pl -t id -t name -t xref $<  > $@.tmp && mv $@.tmp $@

mf-isa-ec.obo: mf-labels.obo
	perl -npe 's@xref: EC:@is_a: EC:@' $< | obo-grep.pl -r is_a -  > $@.tmp && mv $@.tmp $@

mashup.obo: mf-isa-ec.obo ec.obo
	owltools $^ --merge-support-ontologies -o -f obo $@

set.owl: mf.obo ec.obo rhea.obo
	owltools $^ --merge-support-ontologies -o $@
.PRECIOUS: set.owl

MAX_E=5
axioms.owl: ptable.tsv set.owl 
	kboom --experimental  --splitSize 50 --max $(MAX_E) -m linked-rpt.md -j linked-rpt.json -n -o $@ -t $^
