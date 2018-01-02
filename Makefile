#!/usr/bin/make -f
# Makefile to build translations

# Languages which we translate
LANGUAGES=tr fr de es it ro

# Documentation source dir
SOURCE_DIR=docs.ubports.com/

SPHINXOPTS=

# Names of pages, this is hardcoded to allow ordering
SOURCES=$(wildcard $(SOURCE_DIR)*.rst)
PAGES=$(basename $(notdir $(SOURCES)))

# Name of Gettext templates
TEMPLATES=$(addprefix locale/,$(addsuffix .pot,$(PAGES)))

# Symlinked fake mo files
FAKE_MOFILES=$(foreach lang,$(LANGUAGES),$(addsuffix .mo, $(addprefix translated/$(lang)/LC_MESSAGES/, $(PAGES))))

POFILES=$(addsuffix .po, $(addprefix po/,$(LANGUAGES)))
MOFILES=$(addsuffix .mo, $(addprefix po/,$(LANGUAGES)))
INDEXFILES=$(addsuffix /index.html, $(addprefix output/,$(LANGUAGES)))

CONFIGS=$(addsuffix /conf.py, $(addprefix docs/,$(LANGUAGES)))

all: $(FAKE_MOFILES) $(MOFILES) $(CONFIGS)

SECONDARY: $(POFILES) $(INDEXFILES)
.phony: all html $(addprefix html-,$(LANGUAGES))

clean:
	@rm locale/ po/ translated/ docs/ output/ -r

docs/%/conf.py: $(SOURCE_DIR)conf.py Makefile $(SOURCES)
	@mkdir -p docs/$*
	@cd docs/$* && ln -sf ../../$(SOURCE_DIR)* .
	@rm -f $@
	@sed 's/#language = None/language = "$*"\nlocale_dirs = ["..\/..\/translated\/"]/' $< > $@

locale/%.pot: $(SOURCES)
	@make -C $(SOURCE_DIR) gettext BUILDDIR=`pwd`
	@mv gettext/ locale/

po/documentation.pot: $(TEMPLATES)
	@echo "UPDATE $@"
	@mkdir po
	@msgcat -o $@ $(wildcard locale/*.pot)
	@sed -i 's/Report-Msgid-Bugs-To: [^"]*/Report-Msgid-Bugs-To: ubports-community@list.ubports.com\\n/' $@

po/%.po: po/documentation.pot
	@echo "UPDATE $@"
	@if [ ! -f $@ ] ; then msginit --no-translator -i $< -o $@ ; fi
	@msgmerge --previous -U $@ -C $@ $<

po/%.mo: po/%.po
	@echo "GEN $@"
	@msgfmt $< -o $@

translated/%.mo:
	@mkdir -p $(dir $@)
	@ln -sf ../../../po/`echo $@ | sed 's@translated/\(.*\)/LC_MESSAGES.*@\1@'`.mo $@

html: $(addprefix html-,$(LANGUAGES))

html-%: output/%/index.html
	@echo -n

output/%/index.html: po/%.mo
	@echo "HTML $*"
	@mkdir -p "output/$*"
	@sphinx-build $(SPHINXOPTS) docs/$*/ output/$*
