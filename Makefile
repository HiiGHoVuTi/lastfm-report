
THIS=music
EXPORT_REMOTE := "localhost"
EXPORT_PATH := $(shell pwd)

.PHONY: all clean export

all: public/index.html

public/index.html: public/data.json scripts/generate_html.sh
	bash scripts/generate_html.sh

public/data.json: scripts/fetch_data.sh
	bash scripts/fetch_data.sh

clean:
	rm -f public/data.json public/index.html

export: public/index.html
	ssh $(EXPORT_REMOTE) rm -rf $(EXPORT_PATH)/$(THIS)
	scp -r public $(EXPORT_REMOTE):$(EXPORT_PATH)/$(THIS)

export-local: public/index.html
	rm -rf $(EXPORT_PATH)/$(THIS)
	cp -r public $(EXPORT_PATH)/$(THIS)
