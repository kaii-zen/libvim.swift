# -*- mode: makefile-gmake -*-

LIBVIM_SRC = onilibvim/src
CFLAGS = -DHAVE_CONFIG_H -DMACOS_X -DMACOS_X_DARWIN -Iinclude -I$(LIBVIM_SRC)/proto

-include include.d

include.d: include/auto/config.h
	set -eo pipefail; \
		$(CC) $(CFLAGS) -MM $(LIBVIM_SRC)/libvim.h \
		| sed "s|^libvim\.o|include|; s|$(LIBVIM_SRC)|include|g; s|proto/||g" > $@

include/%.pro: $(LIBVIM_SRC)/proto/%.pro
	mkdir -p $(dir $@) && install $^ $@

include/%.h: $(LIBVIM_SRC)/%.h
	mkdir -p $(dir $@) && install $^ $@

include/auto/config.h:
	cd $(LIBVIM_SRC) && ./configure CFLAGS=-Wno-implicit-int
	mkdir -p $(dir $@)
	mv $(LIBVIM_SRC)/auto/config.h $@
	echo '#include "fixes.h"' >> $@

.PHONY: clean
clean:
	$(MAKE) -C $(LIBVIM_SRC) distclean
	rm -rf include/*.h include/*.pro include/auto/config.h
