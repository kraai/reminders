publish: elm.js
	ssh aws.ftbfs.org mkdir -p public_html/reminders
	scp elm.js index.html aws.ftbfs.org:public_html/reminders

elm.js: src/Main.elm
	elm make $< --optimize --output=$@

clean:
	rm -f elm.js

.PHONY: clean publish
