# autopatch.mk
#
# patchall: Patch all the modifications.
# upgrade:  Patch upgrade modifications.
#



AUTOPATCH_DIR   := $(PORT_TOOLS)/autopatch
AUTOPATCH_TOOL  := $(AUTOPATCH_DIR)/autopatch.py


#hide :=

.PHONY: patchall upgrade porting

patchall:
	@echo ""
	@echo ">>> auto patch all ..."
	$(hide) $(AUTOPATCH_TOOL) --patchall --base=$(BASE)

upgrade:
	@echo ""
	@echo ">>> upgrade ..."
	$(hide) $(AUTOPATCH_TOOL) --upgrade --base=$(BASE) --commit1=$(LAST_COMMIT)


PORTING_USAGE="\n  Usage: porting BASE=XX [COMMIT1=XX] [COMMIT2=XX]                     " \
              "\n                                                                       " \
              "\n  - BASE  the source device you porting from, it is like a base        " \
              "\n                                                                       " \
              "\n  - COMMIT1 the 1st 7 bits SHA1 commit ID on BASE                      " \
              "\n                                                                       " \
              "\n  - COMMIT2 the 2nd 7 bits SHA1 commit ID on BASE                      " \
              "\n                                                                       " \
              "\n    e.g. porting BASE=base                                             " \
              "\n         Porting commits from base interactively                       " \
              "\n                                                                       " \
              "\n    e.g. porting BASE=base COMMIT1=643a312                             " \
              "\n         Porting commits from COMMIT1 to the latest                    " \
              "\n                                                                       " \
              "\n   Skill: Define BASE in your Makefile, next time you could            " \
              "\n          use [make porting] directly, it is more effective.           " \
              "\n                                                                       " \

# Porting commits from reference device
porting:
	$(hide) if [ -z $(BASE) ]; then echo $(PORTING_USAGE); exit 1; fi
	@echo ">>> Porting ..."
	$(hide) $(AUTOPATCH_TOOL) --porting --base=$(BASE) --commit1=$(COMMIT1) --commit2=$(COMMIT2)

