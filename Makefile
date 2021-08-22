# Copyright 2021 Matthew James Kraai
#
# Reminders is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Reminders is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with Reminders.  If not, see
# <https://www.gnu.org/licenses/>.

publish: public/elm.min.js public/index.html
	rsync --delete --recursive public/ aws.ftbfs.org:public_html/reminders

elm.js: src/Main.elm
	elm make $< --optimize --output=$@

public/elm.min.js: elm.js
	uglifyjs $< --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle >$@

public/index.html: index.html
	tr -d '\n' <$< | sed 's/[[:space:]]\+/ /g;s/\([),:;>{]\) /\1/g' >$@

clean:
	rm -fr elm.js public

.PHONY: clean publish
