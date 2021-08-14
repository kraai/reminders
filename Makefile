elm.js: src/Main.elm
	elm make $< --optimize --output=$@

clean:
	rm -f elm.js

.PHONY: clean
